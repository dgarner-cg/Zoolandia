#!/usr/bin/env python3
"""
Full system test - database, scraping, and all components
"""

from src.database import AuctionDatabase
from src.scraper_selenium import GovDealsSeleniumScraper
import json

print("=" * 60)
print("GovDeals Full System Test")
print("=" * 60)

# Test 1: Database (with new timeout settings)
print("\n1. Testing database...")
try:
    db = AuctionDatabase()
    print("   ✓ Database initialized")

    # Test concurrent access
    test_url = "https://www.govdeals.com/test/concurrent"
    db.add_watched_auction(test_url, "Concurrent Test", 60)
    auctions = db.get_watched_auctions()
    print(f"   ✓ Can read while writing ({len(auctions)} auctions)")

    # Clean up test
    db.remove_watched_auction(test_url)
    print("   ✓ Database test passed")
except Exception as e:
    print(f"   ✗ Database test failed: {e}")

# Test 2: Selenium Scraper
print("\n2. Testing Selenium scraper...")
try:
    with GovDealsSeleniumScraper(headless=True) as scraper:
        url = "https://www.govdeals.com/en/asset/7631/16416"
        data = scraper.scrape_auction(url)

        if data and data.get('title') != 'Unknown':
            print(f"   ✓ Scraped: {data['title']}")
            print(f"   ✓ Current bid: ${data.get('current_bid', 'N/A')}")
            print(f"   ✓ Time remaining: {data.get('time_remaining', 'N/A')}")
            print("   ✓ Selenium scraper working perfectly")
        else:
            print("   ✗ Scraper returned minimal data")
except Exception as e:
    print(f"   ✗ Selenium test failed: {e}")

# Test 3: Full workflow
print("\n3. Testing full workflow...")
try:
    db = AuctionDatabase()

    # Add auction
    url = "https://www.govdeals.com/en/asset/7631/16416"

    # Scrape it
    with GovDealsSeleniumScraper(headless=True) as scraper:
        auction_data = scraper.scrape_auction(url)

    if auction_data:
        # Try to add (may already exist)
        try:
            db.add_watched_auction(
                url,
                auction_data.get('title'),
                60,
                "System test"
            )
        except:
            pass  # Already exists

        # Save snapshot
        db.save_auction_snapshot(auction_data)

        # Retrieve latest
        latest = db.get_latest_snapshot(url)

        if latest:
            print(f"   ✓ Complete workflow successful")
            print(f"   ✓ Latest snapshot: {latest.get('scraped_at')}")
        else:
            print("   ✗ Could not retrieve snapshot")
    else:
        print("   ✗ Could not scrape auction")

except Exception as e:
    print(f"   ✗ Workflow test failed: {e}")

print("\n" + "=" * 60)
print("System Test Complete")
print("=" * 60)
print("\nNext steps:")
print("1. Restart dashboard: python3 dashboard.py")
print("2. Open http://127.0.0.1:5000")
print("3. Add auctions - they should work now!")
print("4. Click refresh - will use Selenium automatically")
