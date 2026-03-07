#!/usr/bin/env python3
"""
Background monitoring service for GovDeals auctions
Continuously checks watched auctions and sends alerts
"""

import sys
import os
# Add src directory to path to support both direct execution and imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import time
import json
from datetime import datetime
from typing import Dict, Set

from scraper import GovDealsScraper
from scraper_advanced import GovDealsAdvancedScraper
from database import AuctionDatabase
from alerts import AlertManager

# Try to import Selenium scraper (optional)
try:
    from scraper_selenium import GovDealsSeleniumScraper
    SELENIUM_AVAILABLE = True
except ImportError:
    SELENIUM_AVAILABLE = False

class AuctionMonitor:
    def __init__(self, config_file: str = "config/config.json", check_interval: int = 300):
        """
        Initialize auction monitor

        Args:
            config_file: Path to configuration file
            check_interval: Seconds between checks (default: 300 = 5 minutes)
        """
        self.check_interval = check_interval
        self.scraper = GovDealsScraper()
        self.db = AuctionDatabase()
        self.alerted_auctions: Set[str] = set()  # Track which auctions already alerted

        # Load configuration
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
        except FileNotFoundError:
            print(f"Warning: {config_file} not found, using default config")
            config = self._get_default_config()

        self.alert_manager = AlertManager(config.get('alerts', {}))
        self.config = config

    def _get_default_config(self) -> Dict:
        """Get default configuration"""
        return {
            'alerts': {
                'email': {
                    'enabled': False
                },
                'ntfy': {
                    'enabled': False
                }
            },
            'monitoring': {
                'check_interval': 300,
                'alert_cooldown': 3600  # Don't re-alert for 1 hour
            }
        }

    def run(self):
        """Main monitoring loop"""
        print("GovDeals Auction Monitor Started")
        print(f"Check interval: {self.check_interval} seconds")
        print("-" * 50)

        iteration = 0
        while True:
            try:
                iteration += 1
                print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Check #{iteration}")

                watched_auctions = self.db.get_watched_auctions(active_only=True)
                print(f"Monitoring {len(watched_auctions)} auction(s)")

                for auction in watched_auctions:
                    self.check_auction(auction)

                print(f"\nNext check in {self.check_interval} seconds...")
                time.sleep(self.check_interval)

            except KeyboardInterrupt:
                print("\n\nMonitoring stopped by user")
                break
            except Exception as e:
                print(f"Error in monitoring loop: {e}")
                time.sleep(60)  # Wait a minute before retrying

    def check_auction(self, watched_auction: Dict):
        """Check a single auction and send alerts if needed"""
        url = watched_auction['url']
        print(f"\n  Checking: {watched_auction.get('title', url)}")

        # Scrape current data - try basic scraper first (fast)
        auction_data = self.scraper.scrape_auction(url)

        # If regular scraper failed, try advanced scraper (better headers, no Selenium)
        if not auction_data:
            print(f"    ⚠️  Regular scraper failed, trying advanced scraper...")
            advanced_scraper = GovDealsAdvancedScraper()
            auction_data = advanced_scraper.scrape_auction(url)
            if auction_data:
                print(f"    ✓ Advanced scraper succeeded")

        # If both failed, try Selenium as last resort
        if not auction_data and SELENIUM_AVAILABLE:
            print(f"    ⚠️  Advanced scraper failed, trying Selenium...")
            try:
                with GovDealsSeleniumScraper(headless=True) as selenium_scraper:
                    auction_data = selenium_scraper.scrape_auction(url)
                if auction_data:
                    print(f"    ✓ Selenium scraper succeeded")
            except Exception as e:
                print(f"    ✗ Selenium scraper also failed: {e}")

        if not auction_data:
            print(f"    ✗ Failed to scrape with all available methods")
            return

        # Save snapshot to database
        self.db.save_auction_snapshot(auction_data)

        # Update title if we got one and it's not set
        if auction_data.get('title') and not watched_auction.get('title'):
            watched_auction['title'] = auction_data['title']

        # Display current status
        print(f"    Current bid: ${auction_data.get('current_bid', 'N/A')}")
        print(f"    Time remaining: {auction_data.get('time_remaining', 'Unknown')}")
        print(f"    Status: {auction_data.get('status', 'unknown')}")

        # Check if we should send alerts
        self._check_and_send_alerts(auction_data, watched_auction)

    def _check_and_send_alerts(self, auction_data: Dict, watched_auction: Dict):
        """Check if alerts should be sent"""
        url = auction_data.get('url')
        time_remaining = auction_data.get('time_remaining')
        threshold = watched_auction.get('alert_threshold_minutes', 60)

        # Check if auction is ending soon
        if time_remaining and self.alert_manager.should_alert(time_remaining, threshold):
            alert_key = f"ending_soon:{url}"

            # Check if we already sent this alert recently
            if alert_key not in self.alerted_auctions:
                print(f"    ⚠️  ALERT: Ending soon (< {threshold} min)!")

                self.alert_manager.send_ending_soon_alert(auction_data, threshold)

                # Log alert
                self.db.log_alert(
                    url,
                    'ending_soon',
                    f"Time remaining: {time_remaining}",
                    'email+ntfy'
                )

                # Mark as alerted
                self.alerted_auctions.add(alert_key)
            else:
                print(f"    ℹ️  Already alerted for ending soon")

        # Check for price changes
        previous = self.db.get_latest_snapshot(url)
        if previous:
            self._check_price_changes(auction_data, previous)

    def _check_price_changes(self, current_data: Dict, previous_data: Dict):
        """Check if price changed significantly"""
        current_bid = current_data.get('current_bid')
        previous_bid = previous_data.get('current_bid')

        if current_bid and previous_bid and current_bid != previous_bid:
            print(f"    📊 Price changed: ${previous_bid} → ${current_bid}")

            # Alert on significant increase (outbid scenario)
            if current_bid > previous_bid:
                change_pct = ((current_bid - previous_bid) / previous_bid) * 100
                if change_pct > 5:  # More than 5% increase
                    print(f"    📈 Significant increase: +{change_pct:.1f}%")
                    # Could send outbid alert here if desired

    def add_auction_interactive(self):
        """Interactive mode to add auctions"""
        print("\n=== Add Auction to Watch List ===")
        url = input("Auction URL: ").strip()

        if not url:
            print("No URL provided")
            return

        title = input("Title (optional): ").strip() or None
        threshold = input("Alert threshold in minutes (default 60): ").strip()

        try:
            threshold = int(threshold) if threshold else 60
        except ValueError:
            threshold = 60

        notes = input("Notes (optional): ").strip() or None

        if self.db.add_watched_auction(url, title, threshold, notes):
            print(f"✓ Added auction to watch list")

            # Do an immediate check
            print("\nPerforming initial check...")
            watched = self.db.get_watched_auctions()
            for auction in watched:
                if auction['url'] == url:
                    self.check_auction(auction)
                    break
        else:
            print("✗ Failed to add auction (may already exist)")


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(description='GovDeals Auction Monitor')
    parser.add_argument('--config', default='config/config.json', help='Config file path')
    parser.add_argument('--interval', type=int, default=300,
                       help='Check interval in seconds (default: 300)')
    parser.add_argument('--add', action='store_true',
                       help='Add auction interactively')
    parser.add_argument('--list', action='store_true',
                       help='List watched auctions')
    parser.add_argument('--check-now', action='store_true',
                       help='Check all auctions once and exit')

    args = parser.parse_args()

    monitor = AuctionMonitor(args.config, args.interval)

    if args.add:
        monitor.add_auction_interactive()
    elif args.list:
        auctions = monitor.db.get_watched_auctions()
        print(f"\n=== Watching {len(auctions)} Auction(s) ===")
        for auction in auctions:
            print(f"\nTitle: {auction.get('title', 'N/A')}")
            print(f"URL: {auction['url']}")
            print(f"Alert threshold: {auction.get('alert_threshold_minutes', 60)} minutes")
            print(f"Added: {auction.get('added_at')}")
    elif args.check_now:
        watched_auctions = monitor.db.get_watched_auctions(active_only=True)
        print(f"Checking {len(watched_auctions)} auction(s)...")
        for auction in watched_auctions:
            monitor.check_auction(auction)
    else:
        # Start continuous monitoring
        monitor.run()


if __name__ == "__main__":
    main()
