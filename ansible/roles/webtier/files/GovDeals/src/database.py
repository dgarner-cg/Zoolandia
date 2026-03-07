#!/usr/bin/env python3
"""
Database management for GovDeals auction tracker
"""

import sqlite3
from datetime import datetime
from typing import List, Dict, Optional
import json

class AuctionDatabase:
    def __init__(self, db_path: str = "data/auctions.db"):
        self.db_path = db_path
        self.init_database()

    def init_database(self):
        """Initialize database schema"""
        conn = sqlite3.connect(self.db_path, timeout=10, check_same_thread=False)
        cursor = conn.cursor()

        # Watched auctions table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS watched_auctions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                url TEXT UNIQUE NOT NULL,
                title TEXT,
                added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                alert_threshold_minutes INTEGER DEFAULT 60,
                is_active BOOLEAN DEFAULT 1,
                notes TEXT
            )
        ''')

        # Auction history table - stores snapshots
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS auction_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                url TEXT NOT NULL,
                scraped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                current_bid REAL,
                time_remaining TEXT,
                end_time TEXT,
                num_bids INTEGER,
                status TEXT,
                seller TEXT,
                location TEXT,
                raw_data TEXT,
                FOREIGN KEY (url) REFERENCES watched_auctions(url)
            )
        ''')

        # Alerts table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS alerts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                url TEXT NOT NULL,
                alert_type TEXT NOT NULL,
                message TEXT,
                sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                delivery_method TEXT,
                FOREIGN KEY (url) REFERENCES watched_auctions(url)
            )
        ''')

        # Create indexes
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_history_url ON auction_history(url)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_history_time ON auction_history(scraped_at)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_alerts_url ON alerts(url)')

        conn.commit()
        conn.close()

    def add_watched_auction(self, url: str, title: str = None,
                           alert_threshold_minutes: int = 60, notes: str = None) -> bool:
        """Add an auction to watch list (or reactivate if previously removed)"""
        try:
            conn = sqlite3.connect(self.db_path, timeout=10, check_same_thread=False)
            cursor = conn.cursor()

            # Check if auction already exists
            cursor.execute('SELECT id, is_active FROM watched_auctions WHERE url = ?', (url,))
            existing = cursor.fetchone()

            if existing:
                auction_id, is_active = existing
                if is_active:
                    print(f"Auction {url} is already being watched (active)")
                    conn.close()
                    return False
                else:
                    # Reactivate inactive auction and update fields
                    print(f"Reactivating previously removed auction: {url}")
                    cursor.execute('''
                        UPDATE watched_auctions
                        SET is_active = 1,
                            title = COALESCE(?, title),
                            alert_threshold_minutes = ?,
                            notes = COALESCE(?, notes),
                            added_at = CURRENT_TIMESTAMP
                        WHERE url = ?
                    ''', (title, alert_threshold_minutes, notes, url))
                    conn.commit()
                    conn.close()
                    return True
            else:
                # Insert new auction
                cursor.execute('''
                    INSERT INTO watched_auctions (url, title, alert_threshold_minutes, notes)
                    VALUES (?, ?, ?, ?)
                ''', (url, title, alert_threshold_minutes, notes))
                conn.commit()
                conn.close()
                return True

        except Exception as e:
            print(f"Error adding auction: {e}")
            return False

    def remove_watched_auction(self, url: str) -> bool:
        """Remove an auction from watch list"""
        try:
            conn = sqlite3.connect(self.db_path, timeout=10, check_same_thread=False)
            cursor = conn.cursor()

            cursor.execute('UPDATE watched_auctions SET is_active = 0 WHERE url = ?', (url,))

            conn.commit()
            conn.close()
            return True
        except Exception as e:
            print(f"Error removing auction: {e}")
            return False

    def get_watched_auctions(self, active_only: bool = True) -> List[Dict]:
        """Get list of watched auctions"""
        conn = sqlite3.connect(self.db_path, timeout=10, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        query = 'SELECT * FROM watched_auctions'
        if active_only:
            query += ' WHERE is_active = 1'

        cursor.execute(query)
        rows = cursor.fetchall()

        auctions = [dict(row) for row in rows]
        conn.close()

        return auctions

    def save_auction_snapshot(self, auction_data: Dict) -> bool:
        """Save auction data snapshot"""
        try:
            conn = sqlite3.connect(self.db_path, timeout=10, check_same_thread=False)
            cursor = conn.cursor()

            cursor.execute('''
                INSERT INTO auction_history
                (url, current_bid, time_remaining, end_time, num_bids,
                 status, seller, location, raw_data)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                auction_data.get('url'),
                auction_data.get('current_bid'),
                auction_data.get('time_remaining'),
                auction_data.get('end_time'),
                auction_data.get('num_bids'),
                auction_data.get('status'),
                auction_data.get('seller'),
                auction_data.get('location'),
                json.dumps(auction_data)
            ))

            conn.commit()
            conn.close()
            return True
        except Exception as e:
            print(f"Error saving snapshot: {e}")
            return False

    def get_latest_snapshot(self, url: str) -> Optional[Dict]:
        """Get most recent snapshot for an auction"""
        conn = sqlite3.connect(self.db_path, timeout=10, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        cursor.execute('''
            SELECT * FROM auction_history
            WHERE url = ?
            ORDER BY scraped_at DESC
            LIMIT 1
        ''', (url,))

        row = cursor.fetchone()
        conn.close()

        if row:
            data = dict(row)
            if data.get('raw_data'):
                data['parsed_data'] = json.loads(data['raw_data'])
            return data
        return None

    def get_auction_history(self, url: str, limit: int = 100) -> List[Dict]:
        """Get historical data for an auction"""
        conn = sqlite3.connect(self.db_path, timeout=10, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        cursor.execute('''
            SELECT * FROM auction_history
            WHERE url = ?
            ORDER BY scraped_at DESC
            LIMIT ?
        ''', (url, limit))

        rows = cursor.fetchall()
        history = [dict(row) for row in rows]
        conn.close()

        return history

    def log_alert(self, url: str, alert_type: str, message: str,
                  delivery_method: str) -> bool:
        """Log that an alert was sent"""
        try:
            conn = sqlite3.connect(self.db_path, timeout=10, check_same_thread=False)
            cursor = conn.cursor()

            cursor.execute('''
                INSERT INTO alerts (url, alert_type, message, delivery_method)
                VALUES (?, ?, ?, ?)
            ''', (url, alert_type, message, delivery_method))

            conn.commit()
            conn.close()
            return True
        except Exception as e:
            print(f"Error logging alert: {e}")
            return False

    def get_recent_alerts(self, url: str = None, hours: int = 24) -> List[Dict]:
        """Get recent alerts"""
        conn = sqlite3.connect(self.db_path, timeout=10, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        if url:
            cursor.execute('''
                SELECT * FROM alerts
                WHERE url = ? AND sent_at > datetime('now', '-' || ? || ' hours')
                ORDER BY sent_at DESC
            ''', (url, hours))
        else:
            cursor.execute('''
                SELECT * FROM alerts
                WHERE sent_at > datetime('now', '-' || ? || ' hours')
                ORDER BY sent_at DESC
            ''', (hours,))

        rows = cursor.fetchall()
        alerts = [dict(row) for row in rows]
        conn.close()

        return alerts

    def export_to_csv(self, output_file: str = "auctions_export.csv"):
        """Export auction history to CSV"""
        import csv

        conn = sqlite3.connect(self.db_path, timeout=10, check_same_thread=False)
        cursor = conn.cursor()

        cursor.execute('''
            SELECT h.*, w.title, w.alert_threshold_minutes
            FROM auction_history h
            LEFT JOIN watched_auctions w ON h.url = w.url
            ORDER BY h.scraped_at DESC
        ''')

        rows = cursor.fetchall()

        if rows:
            with open(output_file, 'w', newline='') as f:
                writer = csv.writer(f)
                # Write header
                writer.writerow([desc[0] for desc in cursor.description])
                # Write data
                writer.writerows(rows)

            print(f"Exported {len(rows)} records to {output_file}")

        conn.close()


if __name__ == "__main__":
    # Test database
    db = AuctionDatabase()

    # Add test auction
    db.add_watched_auction(
        "https://www.govdeals.com/en/asset/7631/16416",
        title="Test Auction",
        alert_threshold_minutes=30
    )

    # Get watched auctions
    auctions = db.get_watched_auctions()
    print(f"Watching {len(auctions)} auctions:")
    for auction in auctions:
        print(f"  - {auction['url']}")
