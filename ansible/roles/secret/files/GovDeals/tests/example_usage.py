#!/usr/bin/env python3
"""
Example usage script demonstrating the API
"""

from src.database import AuctionDatabase
from src.scraper import GovDealsScraper
from src.alerts import AlertManager
import json

def example_basic_usage():
    """Basic usage example"""
    print("=" * 60)
    print("Example 1: Basic Usage")
    print("=" * 60)

    # Initialize components
    db = AuctionDatabase()
    scraper = GovDealsScraper()

    # Add an auction to watch
    print("\n1. Adding auction to watch list...")
    url = "https://www.govdeals.com/en/asset/7631/16416"
    db.add_watched_auction(
        url=url,
        title="Example Auction Item",
        alert_threshold_minutes=60,
        notes="Testing the system"
    )
    print("   ✓ Added auction")

    # Scrape the auction
    print("\n2. Scraping auction data...")
    data = scraper.scrape_auction(url)
    if data:
        print(f"   Title: {data.get('title', 'N/A')}")
        print(f"   Current Bid: ${data.get('current_bid', 'N/A')}")
        print(f"   Time Remaining: {data.get('time_remaining', 'Unknown')}")
        print(f"   Status: {data.get('status', 'unknown')}")

        # Save to database
        print("\n3. Saving to database...")
        db.save_auction_snapshot(data)
        print("   ✓ Saved snapshot")
    else:
        print("   ✗ Failed to scrape (website may be blocking)")

    # Retrieve from database
    print("\n4. Retrieving from database...")
    auctions = db.get_watched_auctions()
    print(f"   Currently watching {len(auctions)} auction(s)")

    for auction in auctions:
        print(f"\n   - {auction['title']}")
        print(f"     URL: {auction['url']}")
        print(f"     Alert threshold: {auction['alert_threshold_minutes']} minutes")

        # Get history
        history = db.get_auction_history(auction['url'], limit=5)
        print(f"     History entries: {len(history)}")


def example_alert_configuration():
    """Example of configuring alerts"""
    print("\n" + "=" * 60)
    print("Example 2: Alert Configuration")
    print("=" * 60)

    # Email configuration
    print("\nEmail Alert Configuration:")
    email_config = {
        'email': {
            'enabled': True,
            'smtp_server': 'smtp.gmail.com',
            'smtp_port': 587,
            'username': 'your_email@gmail.com',
            'password': 'your_app_password',
            'from_addr': 'your_email@gmail.com',
            'to_addr': 'recipient@example.com'
        }
    }
    print(json.dumps(email_config, indent=2))

    # Ntfy configuration
    print("\nNtfy Alert Configuration:")
    ntfy_config = {
        'ntfy': {
            'enabled': True,
            'topic': 'govdeals_your_unique_topic',
            'server': 'https://ntfy.sh'
        }
    }
    print(json.dumps(ntfy_config, indent=2))

    # Combined configuration
    print("\nCombined Configuration (both methods):")
    combined_config = {
        'alerts': {
            'email': email_config['email'],
            'ntfy': ntfy_config['ntfy']
        },
        'monitoring': {
            'check_interval': 300,
            'alert_cooldown': 3600
        }
    }
    print(json.dumps(combined_config, indent=2))


def example_time_parsing():
    """Example of time parsing for alerts"""
    print("\n" + "=" * 60)
    print("Example 3: Time Parsing")
    print("=" * 60)

    alert_mgr = AlertManager({})

    test_times = [
        "5 minutes",
        "30 minutes",
        "1 hour",
        "2 hours 30 minutes",
        "1 day 3 hours",
        "45 seconds"
    ]

    print("\nParsing time strings:")
    for time_str in test_times:
        minutes = alert_mgr._parse_time_remaining(time_str)
        print(f"  '{time_str}' = {minutes} minutes")

    print("\nChecking alert thresholds:")
    threshold = 60  # 60 minutes
    for time_str in test_times:
        should_alert = alert_mgr.should_alert(time_str, threshold)
        status = "ALERT" if should_alert else "OK"
        print(f"  '{time_str}' (threshold: {threshold} min) → {status}")


def example_database_queries():
    """Example database queries"""
    print("\n" + "=" * 60)
    print("Example 4: Database Queries")
    print("=" * 60)

    db = AuctionDatabase()

    # Get watched auctions
    print("\n1. Get all watched auctions:")
    print("   auctions = db.get_watched_auctions()")

    # Get specific auction history
    print("\n2. Get auction history:")
    print("   history = db.get_auction_history(url, limit=10)")

    # Get latest snapshot
    print("\n3. Get latest snapshot:")
    print("   latest = db.get_latest_snapshot(url)")

    # Get recent alerts
    print("\n4. Get recent alerts:")
    print("   alerts = db.get_recent_alerts(hours=24)")

    # Export to CSV
    print("\n5. Export to CSV:")
    print("   db.export_to_csv('my_export.csv')")


def example_monitoring_patterns():
    """Example monitoring patterns"""
    print("\n" + "=" * 60)
    print("Example 5: Monitoring Patterns")
    print("=" * 60)

    print("\n1. Check all auctions once:")
    print("   $ python3 monitor.py --check-now")

    print("\n2. Continuous monitoring (5 minute interval):")
    print("   $ python3 monitor.py --interval 300")

    print("\n3. List watched auctions:")
    print("   $ python3 monitor.py --list")

    print("\n4. Add auction interactively:")
    print("   $ python3 monitor.py --add")

    print("\n5. Run as background service:")
    print("   $ nohup python3 monitor.py &")
    print("   or")
    print("   $ screen -S govdeals")
    print("   $ python3 monitor.py")
    print("   [Ctrl+A, D to detach]")


def main():
    """Run all examples"""
    print("\n" + "=" * 60)
    print("GovDeals Auction Tracker - Usage Examples")
    print("=" * 60)

    try:
        example_basic_usage()
        example_alert_configuration()
        example_time_parsing()
        example_database_queries()
        example_monitoring_patterns()

        print("\n" + "=" * 60)
        print("Examples completed!")
        print("=" * 60)
        print("\nFor more information, see README.md")

    except Exception as e:
        print(f"\nError running examples: {e}")
        print("Make sure all dependencies are installed:")
        print("  pip install -r requirements.txt")


if __name__ == "__main__":
    main()
