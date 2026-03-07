#!/usr/bin/env python3
"""
Advanced GovDeals scraper with better session handling and retry logic
This works around the Selenium/snap Chromium issues
"""

import requests
from bs4 import BeautifulSoup
import json
import re
from datetime import datetime
from typing import Dict, Optional
import time
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

class GovDealsAdvancedScraper:
    def __init__(self):
        self.session = self._create_session()

    def _create_session(self):
        """Create a requests session with retry logic and proper headers"""
        session = requests.Session()

        # Retry strategy
        retry_strategy = Retry(
            total=3,
            backoff_factor=1,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["HEAD", "GET", "OPTIONS"]
        )
        adapter = HTTPAdapter(max_retries=retry_strategy)
        session.mount("http://", adapter)
        session.mount("https://", adapter)

        # Comprehensive headers to mimic a real browser
        session.headers.update({
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
            'Sec-Fetch-Dest': 'document',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Site': 'none',
            'Sec-Fetch-User': '?1',
            'Cache-Control': 'max-age=0',
        })

        return session

    def scrape_auction(self, url: str) -> Optional[Dict]:
        """
        Scrape auction details with advanced techniques

        Args:
            url: Full URL to the auction page

        Returns:
            Dictionary with auction details or None if failed
        """
        try:
            # Add a small delay to be polite
            time.sleep(1)

            response = self.session.get(url, timeout=20)
            response.raise_for_status()

            soup = BeautifulSoup(response.content, 'html.parser')

            # Extract data from the page
            auction_data = {
                'url': url,
                'scraped_at': datetime.now().isoformat(),
                'title': self._extract_title(soup),
                'current_bid': self._extract_current_bid(soup, response.text),
                'time_remaining': self._extract_time_remaining(soup, response.text),
                'end_time': self._extract_end_time(soup, response.text),
                'num_bids': self._extract_num_bids(soup, response.text),
                'seller': self._extract_seller(soup),
                'location': self._extract_location(soup),
                'description': self._extract_description(soup),
                'status': self._extract_status(soup, response.text)
            }

            # Verify we got at least some data
            if auction_data['title'] == "Unknown" and not auction_data['current_bid']:
                print("    Warning: Minimal data extracted, page may have changed")

            return auction_data

        except requests.exceptions.Timeout:
            print(f"    Timeout fetching {url}")
            return None
        except requests.exceptions.RequestException as e:
            print(f"    Request error: {e}")
            return None
        except Exception as e:
            print(f"    Parse error: {e}")
            return None

    def _extract_title(self, soup: BeautifulSoup) -> str:
        """Extract auction title with multiple strategies"""
        # Try meta tags first
        meta_title = soup.find('meta', property='og:title')
        if meta_title and meta_title.get('content'):
            return meta_title['content'].strip()

        # Try various selectors
        selectors = [
            'h1.item-title',
            'h1.asset-title',
            'h1[itemprop="name"]',
            'h1',
            '.item-title',
            '.asset-title',
            '[class*="item"][class*="title"]',
            '[class*="asset"][class*="title"]'
        ]

        for selector in selectors:
            element = soup.select_one(selector)
            if element and element.get_text(strip=True):
                return element.get_text(strip=True)

        # Try title tag as last resort
        if soup.title and soup.title.string:
            title = soup.title.string.strip()
            # Remove common suffixes
            title = re.sub(r'\s*[-|]\s*GovDeals.*$', '', title)
            if title:
                return title

        return "Unknown"

    def _extract_current_bid(self, soup: BeautifulSoup, page_text: str) -> Optional[float]:
        """Extract current bid amount"""
        # Try to find in JSON-LD structured data
        json_ld = soup.find('script', type='application/ld+json')
        if json_ld:
            try:
                data = json.loads(json_ld.string)
                if isinstance(data, dict) and 'offers' in data:
                    price = data['offers'].get('price')
                    if price:
                        return float(price)
            except:
                pass

        # Try CSS selectors
        selectors = [
            '.current-bid',
            '.current-price',
            '[class*="current"][class*="bid"]',
            '[class*="price"][class*="current"]',
            '[id*="current"][id*="bid"]'
        ]

        for selector in selectors:
            element = soup.select_one(selector)
            if element:
                text = element.get_text(strip=True)
                match = re.search(r'\$?\s*([\d,]+\.?\d*)', text)
                if match:
                    try:
                        return float(match.group(1).replace(',', ''))
                    except:
                        pass

        # Try finding in page text with context
        bid_patterns = [
            r'current\s+bid[:\s]+\$?([\d,]+\.?\d*)',
            r'current\s+price[:\s]+\$?([\d,]+\.?\d*)',
            r'high\s+bid[:\s]+\$?([\d,]+\.?\d*)',
            r'"currentBid"[:\s]+([\d,]+\.?\d*)',
            r'"price"[:\s]+([\d,]+\.?\d*)'
        ]

        for pattern in bid_patterns:
            match = re.search(pattern, page_text, re.IGNORECASE)
            if match:
                try:
                    return float(match.group(1).replace(',', ''))
                except:
                    pass

        return None

    def _extract_time_remaining(self, soup: BeautifulSoup, page_text: str) -> Optional[str]:
        """Extract time remaining"""
        selectors = [
            '.time-remaining',
            '.countdown',
            '[class*="time"][class*="remaining"]',
            '[class*="time"][class*="left"]',
            '[id*="countdown"]'
        ]

        for selector in selectors:
            element = soup.select_one(selector)
            if element and element.get_text(strip=True):
                return element.get_text(strip=True)

        # Try patterns in page text
        patterns = [
            r'time\s+remaining[:\s]+([^<\n]+)',
            r'ends\s+in[:\s]+([^<\n]+)',
            r'"timeRemaining"[:\s]+"([^"]+)"'
        ]

        for pattern in patterns:
            match = re.search(pattern, page_text, re.IGNORECASE)
            if match:
                return match.group(1).strip()

        return None

    def _extract_end_time(self, soup: BeautifulSoup, page_text: str) -> Optional[str]:
        """Extract auction end time"""
        selectors = [
            '.end-time',
            '.closing-time',
            '[class*="end"][class*="time"]',
            '[class*="closing"]',
            '[itemprop="endDate"]'
        ]

        for selector in selectors:
            element = soup.select_one(selector)
            if element:
                # Check for datetime attribute first
                if element.get('datetime'):
                    return element['datetime']
                text = element.get_text(strip=True)
                if text:
                    return text

        # Try patterns
        patterns = [
            r'end\s+time[:\s]+([^<\n]+)',
            r'closing\s+time[:\s]+([^<\n]+)',
            r'"endTime"[:\s]+"([^"]+)"'
        ]

        for pattern in patterns:
            match = re.search(pattern, page_text, re.IGNORECASE)
            if match:
                return match.group(1).strip()

        return None

    def _extract_num_bids(self, soup: BeautifulSoup, page_text: str) -> int:
        """Extract number of bids"""
        selectors = [
            '.num-bids',
            '.bid-count',
            '[class*="bid"][class*="count"]',
            '[id*="bidcount"]'
        ]

        for selector in selectors:
            element = soup.select_one(selector)
            if element:
                text = element.get_text(strip=True)
                match = re.search(r'(\d+)', text)
                if match:
                    return int(match.group(1))

        # Try patterns
        patterns = [
            r'(\d+)\s+bid',
            r'bid\s+count[:\s]+(\d+)',
            r'"bidCount"[:\s]+(\d+)'
        ]

        for pattern in patterns:
            match = re.search(pattern, page_text, re.IGNORECASE)
            if match:
                return int(match.group(1))

        return 0

    def _extract_seller(self, soup: BeautifulSoup) -> Optional[str]:
        """Extract seller information"""
        selectors = [
            '.seller-name',
            '.agency-name',
            '[class*="seller"]',
            '[class*="agency"]',
            '[itemprop="seller"]'
        ]

        for selector in selectors:
            element = soup.select_one(selector)
            if element and element.get_text(strip=True):
                return element.get_text(strip=True)

        return None

    def _extract_location(self, soup: BeautifulSoup) -> Optional[str]:
        """Extract item location"""
        selectors = [
            '.location',
            '.address',
            '[class*="location"]',
            '[itemprop="address"]',
            '[itemprop="location"]'
        ]

        for selector in selectors:
            element = soup.select_one(selector)
            if element and element.get_text(strip=True):
                return element.get_text(strip=True)

        return None

    def _extract_description(self, soup: BeautifulSoup) -> str:
        """Extract item description"""
        # Try meta description first
        meta_desc = soup.find('meta', property='og:description')
        if meta_desc and meta_desc.get('content'):
            return meta_desc['content'].strip()[:500]

        meta_desc = soup.find('meta', attrs={'name': 'description'})
        if meta_desc and meta_desc.get('content'):
            return meta_desc['content'].strip()[:500]

        selectors = [
            '.description',
            '.item-description',
            '[class*="description"]',
            '[itemprop="description"]'
        ]

        for selector in selectors:
            element = soup.select_one(selector)
            if element and element.get_text(strip=True):
                return element.get_text(strip=True)[:500]

        return ""

    def _extract_status(self, soup: BeautifulSoup, page_text: str) -> str:
        """Extract auction status"""
        selectors = [
            '.status',
            '.auction-status',
            '[class*="status"]'
        ]

        for selector in selectors:
            element = soup.select_one(selector)
            if element:
                text = element.get_text(strip=True).lower()
                if 'active' in text or 'open' in text:
                    return 'active'
                elif 'closed' in text or 'ended' in text:
                    return 'ended'

        # Check page text
        page_lower = page_text.lower()
        if 'auction has ended' in page_lower or 'auction closed' in page_lower:
            return 'ended'
        elif 'auction is open' in page_lower or 'bidding is open' in page_lower:
            return 'active'

        # If we have time remaining, it's probably active
        if self._extract_time_remaining(soup, page_text):
            return 'active'

        return "unknown"


if __name__ == "__main__":
    # Test the advanced scraper
    scraper = GovDealsAdvancedScraper()
    test_url = "https://www.govdeals.com/en/asset/7631/16416"

    print(f"Scraping {test_url}...")
    data = scraper.scrape_auction(test_url)

    if data:
        print("\nExtracted Data:")
        print(json.dumps(data, indent=2))
    else:
        print("Failed to scrape auction data")
