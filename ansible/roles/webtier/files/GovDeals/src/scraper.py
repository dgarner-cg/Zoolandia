#!/usr/bin/env python3
"""
GovDeals Auction Scraper
Fetches auction data from GovDeals website
"""

import requests
from bs4 import BeautifulSoup
import json
import re
from datetime import datetime
from typing import Dict, Optional
import time

class GovDealsScraper:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1'
        })

    def scrape_auction(self, url: str) -> Optional[Dict]:
        """
        Scrape auction details from a GovDeals URL

        Args:
            url: Full URL to the auction page

        Returns:
            Dictionary with auction details or None if failed
        """
        try:
            response = self.session.get(url, timeout=10)
            response.raise_for_status()

            soup = BeautifulSoup(response.content, 'html.parser')

            # Extract data from the page
            auction_data = {
                'url': url,
                'scraped_at': datetime.now().isoformat(),
                'title': self._extract_title(soup),
                'current_bid': self._extract_current_bid(soup),
                'time_remaining': self._extract_time_remaining(soup),
                'end_time': self._extract_end_time(soup),
                'num_bids': self._extract_num_bids(soup),
                'seller': self._extract_seller(soup),
                'location': self._extract_location(soup),
                'description': self._extract_description(soup),
                'status': self._extract_status(soup)
            }

            return auction_data

        except requests.RequestException as e:
            print(f"Error fetching {url}: {e}")
            return None
        except Exception as e:
            print(f"Error parsing {url}: {e}")
            return None

    def _extract_title(self, soup: BeautifulSoup) -> str:
        """Extract auction title"""
        # Try multiple selectors
        selectors = [
            'h1.item-title',
            'h1',
            '.asset-title',
            '[class*="title"]'
        ]
        for selector in selectors:
            element = soup.select_one(selector)
            if element:
                return element.get_text(strip=True)
        return "Unknown"

    def _extract_current_bid(self, soup: BeautifulSoup) -> Optional[float]:
        """Extract current bid amount"""
        selectors = [
            '.current-bid',
            '.current-price',
            '[class*="current"][class*="bid"]',
            '[class*="price"]'
        ]

        for selector in selectors:
            element = soup.select_one(selector)
            if element:
                text = element.get_text(strip=True)
                # Extract numeric value
                match = re.search(r'\$?([\d,]+\.?\d*)', text)
                if match:
                    return float(match.group(1).replace(',', ''))

        # Try to find in script tags (JSON data)
        scripts = soup.find_all('script')
        for script in scripts:
            if script.string:
                # Look for bid information in JavaScript
                bid_match = re.search(r'currentBid["\']?\s*:\s*["\']?\$?([\d,]+\.?\d*)', script.string)
                if bid_match:
                    return float(bid_match.group(1).replace(',', ''))

        return None

    def _extract_time_remaining(self, soup: BeautifulSoup) -> Optional[str]:
        """Extract time remaining string"""
        selectors = [
            '.time-remaining',
            '[class*="countdown"]',
            '[class*="time"][class*="left"]'
        ]

        for selector in selectors:
            element = soup.select_one(selector)
            if element:
                return element.get_text(strip=True)

        return None

    def _extract_end_time(self, soup: BeautifulSoup) -> Optional[str]:
        """Extract auction end time"""
        selectors = [
            '.end-time',
            '[class*="end"][class*="time"]',
            '[class*="closing"]'
        ]

        for selector in selectors:
            element = soup.select_one(selector)
            if element:
                return element.get_text(strip=True)

        # Look in script tags
        scripts = soup.find_all('script')
        for script in scripts:
            if script.string:
                end_match = re.search(r'endTime["\']?\s*:\s*["\']([^"\']+)', script.string)
                if end_match:
                    return end_match.group(1)

        return None

    def _extract_num_bids(self, soup: BeautifulSoup) -> Optional[int]:
        """Extract number of bids"""
        selectors = [
            '.num-bids',
            '[class*="bid"][class*="count"]'
        ]

        for selector in selectors:
            element = soup.select_one(selector)
            if element:
                text = element.get_text(strip=True)
                match = re.search(r'(\d+)', text)
                if match:
                    return int(match.group(1))

        return 0

    def _extract_seller(self, soup: BeautifulSoup) -> Optional[str]:
        """Extract seller information"""
        selectors = [
            '.seller-name',
            '[class*="seller"]',
            '[class*="agency"]'
        ]

        for selector in selectors:
            element = soup.select_one(selector)
            if element:
                return element.get_text(strip=True)

        return None

    def _extract_location(self, soup: BeautifulSoup) -> Optional[str]:
        """Extract item location"""
        selectors = [
            '.location',
            '[class*="location"]',
            '.address'
        ]

        for selector in selectors:
            element = soup.select_one(selector)
            if element:
                return element.get_text(strip=True)

        return None

    def _extract_description(self, soup: BeautifulSoup) -> str:
        """Extract item description"""
        selectors = [
            '.description',
            '[class*="description"]',
            '.item-details'
        ]

        for selector in selectors:
            element = soup.select_one(selector)
            if element:
                return element.get_text(strip=True)[:500]  # Limit length

        return ""

    def _extract_status(self, soup: BeautifulSoup) -> str:
        """Extract auction status (active, ended, etc.)"""
        selectors = [
            '.status',
            '[class*="status"]'
        ]

        for selector in selectors:
            element = soup.select_one(selector)
            if element:
                return element.get_text(strip=True).lower()

        # Check if time remaining exists
        if self._extract_time_remaining(soup):
            return "active"

        return "unknown"


if __name__ == "__main__":
    # Test the scraper
    scraper = GovDealsScraper()
    test_url = "https://www.govdeals.com/en/asset/7631/16416"

    print(f"Scraping {test_url}...")
    data = scraper.scrape_auction(test_url)

    if data:
        print("\nExtracted Data:")
        print(json.dumps(data, indent=2))
    else:
        print("Failed to scrape auction data")
