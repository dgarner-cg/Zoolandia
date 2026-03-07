#!/usr/bin/env python3
"""
Test script to verify all components are working
"""

import sys
import json

def test_imports():
    """Test that all required modules can be imported"""
    print("Testing imports...")
    try:
        import requests
        print("  ✓ requests")
        import bs4
        print("  ✓ beautifulsoup4")
        import flask
        print("  ✓ Flask")
        import sqlite3
        print("  ✓ sqlite3")
        print("✓ All imports successful\n")
        return True
    except ImportError as e:
        print(f"✗ Import error: {e}\n")
        return False

def test_database():
    """Test database initialization"""
    print("Testing database...")
    try:
        from src.database import AuctionDatabase
        db = AuctionDatabase("test_auctions.db")

        # Try adding a test auction
        success = db.add_watched_auction(
            "https://www.govdeals.com/test",
            "Test Auction",
            60,
            "Test notes"
        )

        if success:
            print("  ✓ Added test auction")

            # Try retrieving it
            auctions = db.get_watched_auctions()
            if len(auctions) > 0:
                print("  ✓ Retrieved auctions")
            else:
                print("  ✗ Failed to retrieve auctions")
                return False

            # Clean up
            import os
            os.remove("test_auctions.db")
            print("  ✓ Database test passed\n")
            return True
        else:
            print("  ✗ Failed to add auction\n")
            return False
    except Exception as e:
        print(f"  ✗ Database test failed: {e}\n")
        return False

def test_scraper():
    """Test scraper initialization"""
    print("Testing scraper...")
    try:
        from src.scraper import GovDealsScraper
        scraper = GovDealsScraper()
        print("  ✓ Scraper initialized")

        # Test time parsing
        from src.alerts import AlertManager
        alert_mgr = AlertManager({})
        test_time = "2 hours 30 minutes"
        minutes = alert_mgr._parse_time_remaining(test_time)
        if minutes == 150:
            print(f"  ✓ Time parsing works ('{test_time}' = {minutes} min)")
        else:
            print(f"  ✗ Time parsing issue (expected 150, got {minutes})")
            return False

        print("✓ Scraper test passed\n")
        return True
    except Exception as e:
        print(f"  ✗ Scraper test failed: {e}\n")
        return False

def test_config():
    """Test config file"""
    print("Testing configuration...")
    try:
        with open('config/config.json', 'r') as f:
            config = json.load(f)

        if 'alerts' in config:
            print("  ✓ Config file is valid")

            # Check alert settings
            email_enabled = config.get('alerts', {}).get('email', {}).get('enabled')
            ntfy_enabled = config.get('alerts', {}).get('ntfy', {}).get('enabled')

            print(f"  ℹ Email alerts: {'enabled' if email_enabled else 'disabled'}")
            print(f"  ℹ Ntfy alerts: {'enabled' if ntfy_enabled else 'disabled'}")

            if not email_enabled and not ntfy_enabled:
                print("  ⚠ Warning: No alert methods are enabled")
                print("    Edit config.json to enable email or ntfy alerts")

            print("✓ Config test passed\n")
            return True
        else:
            print("  ✗ Invalid config format\n")
            return False
    except FileNotFoundError:
        print("  ✗ config.json not found")
        print("    Run setup.sh or create config.json manually\n")
        return False
    except json.JSONDecodeError as e:
        print(f"  ✗ Invalid JSON in config.json: {e}\n")
        return False

def test_alerts():
    """Test alert system"""
    print("Testing alerts...")
    try:
        from alerts import AlertManager

        # Create test config
        config = {
            'email': {'enabled': False},
            'ntfy': {'enabled': False}
        }
        alert_mgr = AlertManager(config)

        # Test time parsing
        test_cases = [
            ("2 hours 30 minutes", 150),
            ("45 minutes", 45),
            ("1 day", 1440),
            ("30 seconds", 0)
        ]

        for time_str, expected in test_cases:
            result = alert_mgr._parse_time_remaining(time_str)
            if result == expected:
                print(f"  ✓ '{time_str}' = {result} min")
            else:
                print(f"  ✗ '{time_str}' expected {expected}, got {result}")
                return False

        print("✓ Alert test passed\n")
        return True
    except Exception as e:
        print(f"  ✗ Alert test failed: {e}\n")
        return False

def main():
    """Run all tests"""
    print("=" * 50)
    print("GovDeals Auction Tracker - System Test")
    print("=" * 50)
    print()

    tests = [
        ("Imports", test_imports),
        ("Database", test_database),
        ("Scraper", test_scraper),
        ("Configuration", test_config),
        ("Alerts", test_alerts)
    ]

    results = []
    for name, test_func in tests:
        result = test_func()
        results.append((name, result))

    # Summary
    print("=" * 50)
    print("Test Summary:")
    print("=" * 50)

    passed = sum(1 for _, result in results if result)
    total = len(results)

    for name, result in results:
        status = "✓ PASS" if result else "✗ FAIL"
        print(f"{status:8} {name}")

    print()
    print(f"Results: {passed}/{total} tests passed")

    if passed == total:
        print()
        print("✓ All tests passed! System is ready to use.")
        print()
        print("Quick start:")
        print("  1. python3 monitor.py --add     (add auction to watch)")
        print("  2. python3 dashboard.py         (start web dashboard)")
        print("  3. python3 monitor.py           (start monitoring)")
        return 0
    else:
        print()
        print("✗ Some tests failed. Please fix the issues above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
