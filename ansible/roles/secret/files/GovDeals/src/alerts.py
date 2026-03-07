#!/usr/bin/env python3
"""
Alert system for GovDeals auction tracker
Supports email and ntfy notifications
"""

import smtplib
import requests
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Dict, Optional
import re
from datetime import datetime, timedelta

class AlertManager:
    def __init__(self, config: Dict):
        """
        Initialize alert manager

        Args:
            config: Dictionary with alert configuration
                {
                    'email': {
                        'enabled': True,
                        'smtp_server': 'smtp.gmail.com',
                        'smtp_port': 587,
                        'username': 'your_email@gmail.com',
                        'password': 'your_app_password',
                        'from_addr': 'your_email@gmail.com',
                        'to_addr': 'recipient@example.com'
                    },
                    'ntfy': {
                        'enabled': True,
                        'topic': 'govdeals_alerts',
                        'server': 'https://ntfy.sh'  # or your own server
                    }
                }
        """
        self.config = config

    def should_alert(self, time_remaining_str: str, threshold_minutes: int) -> bool:
        """
        Determine if an alert should be sent based on time remaining

        Args:
            time_remaining_str: String like "2 hours 30 minutes" or "45 minutes"
            threshold_minutes: Alert threshold in minutes

        Returns:
            True if time remaining is less than threshold
        """
        minutes = self._parse_time_remaining(time_remaining_str)
        if minutes is None:
            return False

        return minutes <= threshold_minutes

    def _parse_time_remaining(self, time_str: str) -> Optional[int]:
        """
        Parse time remaining string to minutes

        Args:
            time_str: String like "2 hours 30 minutes", "45 minutes", "1 day 3 hours"

        Returns:
            Total minutes or None if can't parse
        """
        if not time_str:
            return None

        time_str = time_str.lower()
        total_minutes = 0

        # Parse days
        days_match = re.search(r'(\d+)\s*day', time_str)
        if days_match:
            total_minutes += int(days_match.group(1)) * 24 * 60

        # Parse hours
        hours_match = re.search(r'(\d+)\s*hour', time_str)
        if hours_match:
            total_minutes += int(hours_match.group(1)) * 60

        # Parse minutes
        minutes_match = re.search(r'(\d+)\s*minute', time_str)
        if minutes_match:
            total_minutes += int(minutes_match.group(1))

        # Parse seconds (if ending very soon)
        seconds_match = re.search(r'(\d+)\s*second', time_str)
        if seconds_match and total_minutes == 0:
            # If only seconds remain, consider it as 0 minutes
            return 0

        return total_minutes if total_minutes > 0 else None

    def send_ending_soon_alert(self, auction_data: Dict, threshold_minutes: int):
        """Send alert that auction is ending soon"""
        message = self._format_ending_soon_message(auction_data, threshold_minutes)
        subject = f"🔔 Auction Ending Soon: {auction_data.get('title', 'Unknown')}"

        self._send_alert(subject, message, auction_data.get('url'), priority='high')

    def send_outbid_alert(self, auction_data: Dict):
        """Send alert that user was outbid"""
        message = self._format_outbid_message(auction_data)
        subject = f"📈 Outbid Alert: {auction_data.get('title', 'Unknown')}"

        self._send_alert(subject, message, auction_data.get('url'), priority='default')

    def send_price_drop_alert(self, auction_data: Dict, old_price: float, new_price: float):
        """Send alert that price dropped"""
        message = self._format_price_change_message(auction_data, old_price, new_price)
        subject = f"💰 Price Drop: {auction_data.get('title', 'Unknown')}"

        self._send_alert(subject, message, auction_data.get('url'), priority='default')

    def _format_ending_soon_message(self, auction_data: Dict, threshold: int) -> str:
        """Format ending soon message"""
        return f"""
Auction Ending Soon!

Title: {auction_data.get('title', 'Unknown')}
Current Bid: ${auction_data.get('current_bid', 'N/A')}
Time Remaining: {auction_data.get('time_remaining', 'Unknown')}
Number of Bids: {auction_data.get('num_bids', 0)}
Seller: {auction_data.get('seller', 'Unknown')}
Location: {auction_data.get('location', 'Unknown')}

URL: {auction_data.get('url')}

⏰ Alert triggered: Less than {threshold} minutes remaining!
""".strip()

    def _format_outbid_message(self, auction_data: Dict) -> str:
        """Format outbid message"""
        return f"""
You've Been Outbid!

Title: {auction_data.get('title', 'Unknown')}
New Bid: ${auction_data.get('current_bid', 'N/A')}
Time Remaining: {auction_data.get('time_remaining', 'Unknown')}
Number of Bids: {auction_data.get('num_bids', 0)}

URL: {auction_data.get('url')}
""".strip()

    def _format_price_change_message(self, auction_data: Dict,
                                     old_price: float, new_price: float) -> str:
        """Format price change message"""
        change = new_price - old_price
        change_pct = (change / old_price * 100) if old_price > 0 else 0

        return f"""
Price Changed!

Title: {auction_data.get('title', 'Unknown')}
Old Price: ${old_price:.2f}
New Price: ${new_price:.2f}
Change: ${change:.2f} ({change_pct:+.1f}%)

Time Remaining: {auction_data.get('time_remaining', 'Unknown')}

URL: {auction_data.get('url')}
""".strip()

    def _send_alert(self, subject: str, message: str, url: str, priority: str = 'default'):
        """Send alert via all enabled methods"""
        success = False

        # Send email
        if self.config.get('email', {}).get('enabled'):
            if self._send_email(subject, message):
                success = True

        # Send ntfy notification
        if self.config.get('ntfy', {}).get('enabled'):
            if self._send_ntfy(subject, message, url, priority):
                success = True

        return success

    def _send_email(self, subject: str, message: str) -> bool:
        """Send email alert"""
        try:
            email_config = self.config.get('email', {})

            msg = MIMEMultipart()
            msg['From'] = email_config.get('from_addr')
            msg['To'] = email_config.get('to_addr')
            msg['Subject'] = subject

            msg.attach(MIMEText(message, 'plain'))

            server = smtplib.SMTP(
                email_config.get('smtp_server'),
                email_config.get('smtp_port')
            )
            server.starttls()
            server.login(
                email_config.get('username'),
                email_config.get('password')
            )

            server.send_message(msg)
            server.quit()

            print(f"✓ Email sent: {subject}")
            return True

        except Exception as e:
            print(f"✗ Email failed: {e}")
            return False

    def _send_ntfy(self, subject: str, message: str, url: str, priority: str = 'default') -> bool:
        """Send ntfy notification"""
        try:
            ntfy_config = self.config.get('ntfy', {})
            topic = ntfy_config.get('topic')
            server = ntfy_config.get('server', 'https://ntfy.sh')

            headers = {
                'Title': subject,
                'Priority': priority,
                'Tags': 'alarm_clock,money_with_wings',
                'Click': url
            }

            response = requests.post(
                f"{server}/{topic}",
                data=message.encode('utf-8'),
                headers=headers,
                timeout=10
            )

            response.raise_for_status()
            print(f"✓ Ntfy sent: {subject}")
            return True

        except Exception as e:
            print(f"✗ Ntfy failed: {e}")
            return False


if __name__ == "__main__":
    # Test alert system
    test_config = {
        'email': {
            'enabled': False,  # Set to True and configure to test
            'smtp_server': 'smtp.gmail.com',
            'smtp_port': 587,
            'username': 'your_email@gmail.com',
            'password': 'your_app_password',
            'from_addr': 'your_email@gmail.com',
            'to_addr': 'recipient@example.com'
        },
        'ntfy': {
            'enabled': True,
            'topic': 'govdeals_test',
            'server': 'https://ntfy.sh'
        }
    }

    alert_manager = AlertManager(test_config)

    # Test time parsing
    print("Testing time parsing:")
    test_times = [
        "2 hours 30 minutes",
        "45 minutes",
        "1 day 3 hours",
        "30 seconds"
    ]

    for time_str in test_times:
        minutes = alert_manager._parse_time_remaining(time_str)
        print(f"  '{time_str}' = {minutes} minutes")

    # Test alert
    test_auction = {
        'title': 'Test Auction Item',
        'current_bid': 150.00,
        'time_remaining': '45 minutes',
        'num_bids': 5,
        'seller': 'Test Seller',
        'location': 'Test Location',
        'url': 'https://www.govdeals.com/test'
    }

    print("\nSending test alert...")
    alert_manager.send_ending_soon_alert(test_auction, 60)
