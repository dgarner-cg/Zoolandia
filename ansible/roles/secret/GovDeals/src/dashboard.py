#!/usr/bin/env python3
"""
Web dashboard for GovDeals auction tracker
"""

import sys
import os
# Add src directory to path to support both direct execution and imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from flask import Flask, render_template, jsonify, request, redirect, url_for
from database import AuctionDatabase
from scraper import GovDealsScraper
from scraper_advanced import GovDealsAdvancedScraper
import json
from datetime import datetime, timedelta

# Try to import Selenium scraper (optional)
try:
    from scraper_selenium import GovDealsSeleniumScraper
    SELENIUM_AVAILABLE = True
except ImportError:
    SELENIUM_AVAILABLE = False

app = Flask(__name__)
db = AuctionDatabase()
scraper = GovDealsScraper()
advanced_scraper = GovDealsAdvancedScraper()

@app.route('/')
def index():
    """Main dashboard page"""
    return render_template('index.html')

@app.route('/api/auctions')
def get_auctions():
    """Get all watched auctions with latest data"""
    watched = db.get_watched_auctions(active_only=True)

    # Enrich with latest snapshot data
    for auction in watched:
        latest = db.get_latest_snapshot(auction['url'])
        if latest:
            auction['latest'] = {
                'current_bid': latest.get('current_bid'),
                'time_remaining': latest.get('time_remaining'),
                'num_bids': latest.get('num_bids'),
                'status': latest.get('status'),
                'scraped_at': latest.get('scraped_at')
            }
        else:
            auction['latest'] = None

    return jsonify(watched)

@app.route('/api/auction/<int:auction_id>')
def get_auction_detail(auction_id):
    """Get detailed data for a specific auction"""
    watched = db.get_watched_auctions(active_only=False)
    auction = next((a for a in watched if a['id'] == auction_id), None)

    if not auction:
        return jsonify({'error': 'Not found'}), 404

    # Get history
    history = db.get_auction_history(auction['url'], limit=50)

    return jsonify({
        'auction': auction,
        'history': history
    })

@app.route('/api/auction/add', methods=['POST'])
def add_auction():
    """Add a new auction to watch"""
    import traceback

    print("\n" + "="*60)
    print("ADD AUCTION REQUEST")
    print("="*60)

    data = request.json
    print(f"Received data: {data}")

    url = data.get('url')
    title = data.get('title')
    threshold = data.get('alert_threshold_minutes', 60)
    notes = data.get('notes')

    print(f"URL: {url}")
    print(f"Title: {title}")
    print(f"Threshold: {threshold}")

    if not url:
        print("ERROR: No URL provided")
        return jsonify({'error': 'URL required'}), 400

    # Try to scrape title if not provided
    if not title:
        print("No title provided, attempting to scrape...")

        # Try basic scraper first
        print("  Trying basic scraper...")
        try:
            auction_data = scraper.scrape_auction(url)
            if auction_data and auction_data.get('title') and auction_data.get('title') not in ['Unknown', 'Home']:
                print(f"  ✓ Basic scraper got title: {auction_data.get('title')}")
            else:
                print(f"  ✗ Basic scraper failed (title={auction_data.get('title') if auction_data else 'None'})")
                auction_data = None
        except Exception as e:
            print(f"  ✗ Basic scraper exception: {e}")
            auction_data = None

        # If failed, try advanced scraper
        if not auction_data:
            print("  Trying advanced scraper...")
            try:
                auction_data = advanced_scraper.scrape_auction(url)
                # Only accept if we got useful data (not just generic "Home" or "Unknown")
                if auction_data and auction_data.get('title') and auction_data.get('title') not in ['Unknown', 'Home']:
                    print(f"  ✓ Advanced scraper got title: {auction_data.get('title')}")
                else:
                    print(f"  ✗ Advanced scraper failed or got generic title (title={auction_data.get('title') if auction_data else 'None'})")
                    auction_data = None
            except Exception as e:
                print(f"  ✗ Advanced scraper exception: {e}")
                auction_data = None

        # If both failed, try Selenium as fallback (this should work!)
        if not auction_data and SELENIUM_AVAILABLE:
            print("  Trying Selenium scraper...")
            try:
                with GovDealsSeleniumScraper(headless=True) as selenium_scraper:
                    auction_data = selenium_scraper.scrape_auction(url)
                    if auction_data and auction_data.get('title'):
                        print(f"  ✓ Selenium scraper got title: {auction_data.get('title')}")
                    else:
                        print("  ✗ Selenium scraper returned no data")
            except Exception as e:
                print(f"  ✗ Selenium scraper exception: {e}")
                traceback.print_exc()
                auction_data = None
        elif not auction_data:
            print("  ✗ Selenium not available and other scrapers failed")

        if auction_data:
            title = auction_data.get('title')
            print(f"Final extracted title: {title}")
        else:
            print("WARNING: Could not scrape title, will add without title")

    print(f"Attempting to add to database: url={url}, title={title}")

    try:
        success = db.add_watched_auction(url, title, threshold, notes)
        print(f"Database add result: {success}")

        if success:
            # If we successfully scraped data, save it as initial snapshot
            if auction_data:
                print("Saving initial snapshot with scraped data...")
                db.save_auction_snapshot(auction_data)
                print(f"  ✓ Saved snapshot: bid=${auction_data.get('current_bid')}, "
                      f"time={auction_data.get('time_remaining')}, "
                      f"bids={auction_data.get('num_bids')}")

            print("✓ Successfully added auction")
            return jsonify({'success': True})
        else:
            print("✗ Database returned False (likely already exists)")
            return jsonify({'error': 'Failed to add auction (may already exist)'}), 400
    except Exception as e:
        print(f"✗ Database exception: {e}")
        traceback.print_exc()
        return jsonify({'error': f'Database error: {str(e)}'}), 500

@app.route('/api/auction/<int:auction_id>/remove', methods=['POST'])
def remove_auction(auction_id):
    """Remove an auction from watch list"""
    watched = db.get_watched_auctions(active_only=False)
    auction = next((a for a in watched if a['id'] == auction_id), None)

    if not auction:
        return jsonify({'error': 'Not found'}), 404

    success = db.remove_watched_auction(auction['url'])

    if success:
        return jsonify({'success': True})
    else:
        return jsonify({'error': 'Failed to remove auction'}), 400

@app.route('/api/auction/<int:auction_id>/refresh', methods=['POST'])
def refresh_auction(auction_id):
    """Manually refresh auction data"""
    import traceback

    print("\n" + "="*60)
    print(f"REFRESH AUCTION REQUEST (ID: {auction_id})")
    print("="*60)

    watched = db.get_watched_auctions(active_only=False)
    auction = next((a for a in watched if a['id'] == auction_id), None)

    if not auction:
        print(f"ERROR: Auction ID {auction_id} not found")
        return jsonify({'error': 'Not found'}), 404

    url = auction['url']
    print(f"Refreshing: {url}")

    # Scrape latest data - try basic scraper first
    print("  Trying basic scraper...")
    try:
        auction_data = scraper.scrape_auction(url)
        # Only accept if we got useful data
        if auction_data and auction_data.get('title') and auction_data.get('title') not in ['Unknown', 'Home']:
            print(f"  ✓ Basic scraper success")
        else:
            print(f"  ✗ Basic scraper returned minimal data")
            auction_data = None
    except Exception as e:
        print(f"  ✗ Basic scraper exception: {e}")
        auction_data = None

    # If regular scraper failed, try advanced scraper
    if not auction_data:
        print("  Trying advanced scraper...")
        try:
            auction_data = advanced_scraper.scrape_auction(url)
            # Only accept if we got useful data
            if auction_data and auction_data.get('title') and auction_data.get('title') not in ['Unknown', 'Home']:
                print(f"  ✓ Advanced scraper success")
            else:
                print(f"  ✗ Advanced scraper returned minimal data")
                auction_data = None
        except Exception as e:
            print(f"  ✗ Advanced scraper exception: {e}")
            auction_data = None

    # If both failed, try Selenium as fallback (this should work!)
    if not auction_data and SELENIUM_AVAILABLE:
        print("  Trying Selenium scraper...")
        try:
            with GovDealsSeleniumScraper(headless=True) as selenium_scraper:
                auction_data = selenium_scraper.scrape_auction(url)
                if auction_data and auction_data.get('title'):
                    print(f"  ✓ Selenium scraper success: {auction_data.get('title')}")
                else:
                    print(f"  ✗ Selenium scraper returned no data")
        except Exception as e:
            print(f"  ✗ Selenium scraper exception: {e}")
            traceback.print_exc()
            auction_data = None
    elif not auction_data:
        print("  ✗ Selenium not available and other scrapers failed")

    if auction_data:
        db.save_auction_snapshot(auction_data)
        return jsonify({
            'success': True,
            'data': auction_data
        })
    else:
        error_msg = 'Failed to scrape with all available methods'
        return jsonify({'error': error_msg}), 500

@app.route('/api/alerts/recent')
def get_recent_alerts():
    """Get recent alerts"""
    hours = request.args.get('hours', 24, type=int)
    alerts = db.get_recent_alerts(hours=hours)

    return jsonify(alerts)

@app.route('/api/stats')
def get_stats():
    """Get dashboard statistics"""
    watched = db.get_watched_auctions(active_only=True)
    alerts = db.get_recent_alerts(hours=24)

    # Count auctions by status
    active_count = 0
    ending_soon_count = 0

    for auction in watched:
        latest = db.get_latest_snapshot(auction['url'])
        if latest:
            status = latest.get('status', 'unknown')
            if status == 'active':
                active_count += 1

            # Check if ending soon
            time_remaining = latest.get('time_remaining')
            if time_remaining and ('hour' not in time_remaining.lower() or \
               (time_remaining.lower().startswith('1') and 'hour' in time_remaining.lower())):
                ending_soon_count += 1

    return jsonify({
        'total_watched': len(watched),
        'active_auctions': active_count,
        'ending_soon': ending_soon_count,
        'alerts_24h': len(alerts)
    })

@app.template_filter('timeago')
def timeago_filter(timestamp_str):
    """Convert timestamp to relative time"""
    try:
        timestamp = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
        now = datetime.now(timestamp.tzinfo) if timestamp.tzinfo else datetime.now()
        diff = now - timestamp

        if diff.days > 0:
            return f"{diff.days} day{'s' if diff.days != 1 else ''} ago"
        elif diff.seconds >= 3600:
            hours = diff.seconds // 3600
            return f"{hours} hour{'s' if hours != 1 else ''} ago"
        elif diff.seconds >= 60:
            minutes = diff.seconds // 60
            return f"{minutes} minute{'s' if minutes != 1 else ''} ago"
        else:
            return "Just now"
    except:
        return timestamp_str


def main():
    """Run the dashboard"""
    import argparse

    parser = argparse.ArgumentParser(description='GovDeals Dashboard')
    parser.add_argument('--host', default='127.0.0.1', help='Host to bind to')
    parser.add_argument('--port', type=int, default=5000, help='Port to bind to')
    parser.add_argument('--debug', action='store_true', help='Enable debug mode')

    args = parser.parse_args()

    print(f"Starting dashboard at http://{args.host}:{args.port}")
    app.run(host=args.host, port=args.port, debug=args.debug)


if __name__ == '__main__':
    main()
