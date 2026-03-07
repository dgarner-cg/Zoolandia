#!/usr/bin/env python3
"""
Enhanced GovDeals scraper using Selenium for JavaScript-heavy pages
This is needed when the basic scraper gets blocked or times out
"""

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
import time
from datetime import datetime
from typing import Dict, Optional
import re

class GovDealsSeleniumScraper:
    def __init__(self, headless: bool = True):
        """
        Initialize Selenium scraper

        Args:
            headless: Run browser in headless mode (no GUI)
        """
        self.headless = headless
        self.driver = None

    def _init_driver(self):
        """Initialize Chrome driver"""
        if self.driver:
            return

        chrome_options = Options()
        if self.headless:
            chrome_options.add_argument('--headless=new')
        chrome_options.add_argument('--no-sandbox')
        chrome_options.add_argument('--disable-dev-shm-usage')
        chrome_options.add_argument('--disable-gpu')
        chrome_options.add_argument('--disable-software-rasterizer')
        chrome_options.add_argument('--disable-extensions')
        chrome_options.add_argument('--disable-setuid-sandbox')
        chrome_options.add_argument('--disable-blink-features=AutomationControlled')
        chrome_options.add_argument('--remote-debugging-port=9222')
        chrome_options.add_argument('user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')

        # Additional options for snap-based Chromium
        chrome_options.add_argument('--disable-dev-tools')
        chrome_options.add_argument('--no-first-run')
        chrome_options.add_argument('--no-default-browser-check')
        chrome_options.add_argument('--disable-background-networking')

        # Set preferences
        chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
        chrome_options.add_experimental_option('useAutomationExtension', False)

        # Find Chrome/Chromium binary - prefer Google Chrome over Chromium
        import os
        import shutil

        chrome_binary = None
        # Prefer Google Chrome (more stable) over Chromium
        possible_paths = [
            '/usr/bin/google-chrome-stable',
            '/usr/bin/google-chrome',
            '/usr/bin/chromium',
            '/usr/bin/chromium-browser',
            '/snap/bin/chromium',  # Snap installation (last resort)
        ]

        # First try to find google-chrome or chromium in PATH
        for cmd in ['google-chrome-stable', 'google-chrome', 'chromium']:
            cmd_path = shutil.which(cmd)
            if cmd_path:
                chrome_binary = cmd_path
                break

        # If not found in PATH, check known paths
        if not chrome_binary:
            for path in possible_paths:
                if os.path.exists(path):
                    chrome_binary = path
                    break

        if chrome_binary:
            chrome_options.binary_location = chrome_binary

        # Try to initialize driver
        try:
            self.driver = webdriver.Chrome(options=chrome_options)
        except Exception as e:
            print(f"Error initializing Chrome driver: {e}")
            print(f"\nChrome binary location: {chrome_binary if chrome_binary else 'Not found'}")
            print("\nTo fix this, install Chrome/Chromium and chromedriver:")
            print("  Ubuntu/Debian: sudo apt-get install chromium-browser chromium-chromedriver")
            print("  Or download from: https://chromedriver.chromium.org/")
            raise

    def scrape_auction(self, url: str) -> Optional[Dict]:
        """
        Scrape auction details using Selenium

        Args:
            url: Full URL to the auction page

        Returns:
            Dictionary with auction details or None if failed
        """
        try:
            self._init_driver()

            print(f"Loading {url} with Selenium...")
            self.driver.get(url)

            # Wait for page to load
            wait = WebDriverWait(self.driver, 15)

            # Try to wait for key elements
            try:
                # Wait for the page to have loaded some content
                wait.until(EC.presence_of_element_located((By.TAG_NAME, "body")))
                time.sleep(2)  # Additional wait for JavaScript
            except:
                pass

            # Extract data
            auction_data = {
                'url': url,
                'scraped_at': datetime.now().isoformat(),
                'title': self._extract_title(),
                'current_bid': self._extract_current_bid(),
                'time_remaining': self._extract_time_remaining(),
                'end_time': self._extract_end_time(),
                'num_bids': self._extract_num_bids(),
                'seller': self._extract_seller(),
                'location': self._extract_location(),
                'description': self._extract_description(),
                'status': self._extract_status()
            }

            return auction_data

        except Exception as e:
            print(f"Error scraping {url}: {e}")
            return None

    def _extract_title(self) -> str:
        """Extract auction title"""
        selectors = [
            (By.CSS_SELECTOR, "h1.item-title"),
            (By.CSS_SELECTOR, "h1"),
            (By.CSS_SELECTOR, ".asset-title"),
            (By.XPATH, "//h1"),
            (By.XPATH, "//*[contains(@class, 'title')]")
        ]

        for selector_type, selector in selectors:
            try:
                element = self.driver.find_element(selector_type, selector)
                if element and element.text:
                    return element.text.strip()
            except:
                continue

        return "Unknown"

    def _extract_current_bid(self) -> Optional[float]:
        """Extract current bid amount"""
        selectors = [
            (By.CSS_SELECTOR, ".current-bid"),
            (By.CSS_SELECTOR, ".current-price"),
            (By.XPATH, "//*[contains(text(), 'Current Bid')]//following-sibling::*"),
            (By.XPATH, "//*[contains(text(), '$')]")
        ]

        for selector_type, selector in selectors:
            try:
                element = self.driver.find_element(selector_type, selector)
                if element:
                    text = element.text.strip()
                    # Extract numeric value
                    match = re.search(r'\$?([\d,]+\.?\d*)', text)
                    if match:
                        return float(match.group(1).replace(',', ''))
            except:
                continue

        # Try to find in page source
        try:
            page_source = self.driver.page_source
            bid_match = re.search(r'current[Bb]id["\']?\s*[:=]\s*["\']?\$?([\d,]+\.?\d*)', page_source)
            if bid_match:
                return float(bid_match.group(1).replace(',', ''))
        except:
            pass

        return None

    def _extract_time_remaining(self) -> Optional[str]:
        """Extract time remaining"""
        selectors = [
            (By.CSS_SELECTOR, ".time-remaining"),
            (By.CSS_SELECTOR, ".countdown"),
            (By.XPATH, "//*[contains(@class, 'time')]"),
            (By.XPATH, "//*[contains(text(), 'Time Remaining')]//following-sibling::*")
        ]

        for selector_type, selector in selectors:
            try:
                element = self.driver.find_element(selector_type, selector)
                if element and element.text:
                    return element.text.strip()
            except:
                continue

        return None

    def _extract_end_time(self) -> Optional[str]:
        """Extract auction end time"""
        selectors = [
            (By.CSS_SELECTOR, ".end-time"),
            (By.CSS_SELECTOR, ".closing-time"),
            (By.XPATH, "//*[contains(text(), 'End Time')]//following-sibling::*"),
            (By.XPATH, "//*[contains(text(), 'Closing')]")
        ]

        for selector_type, selector in selectors:
            try:
                element = self.driver.find_element(selector_type, selector)
                if element and element.text:
                    return element.text.strip()
            except:
                continue

        return None

    def _extract_num_bids(self) -> int:
        """Extract number of bids"""
        selectors = [
            (By.CSS_SELECTOR, ".num-bids"),
            (By.CSS_SELECTOR, ".bid-count"),
            (By.XPATH, "//*[contains(text(), 'Bid')]")
        ]

        for selector_type, selector in selectors:
            try:
                element = self.driver.find_element(selector_type, selector)
                if element:
                    text = element.text.strip()
                    match = re.search(r'(\d+)', text)
                    if match:
                        return int(match.group(1))
            except:
                continue

        return 0

    def _extract_seller(self) -> Optional[str]:
        """Extract seller information"""
        selectors = [
            (By.CSS_SELECTOR, ".seller-name"),
            (By.CSS_SELECTOR, ".agency"),
            (By.XPATH, "//*[contains(text(), 'Seller')]//following-sibling::*")
        ]

        for selector_type, selector in selectors:
            try:
                element = self.driver.find_element(selector_type, selector)
                if element and element.text:
                    return element.text.strip()
            except:
                continue

        return None

    def _extract_location(self) -> Optional[str]:
        """Extract item location"""
        selectors = [
            (By.CSS_SELECTOR, ".location"),
            (By.CSS_SELECTOR, ".address"),
            (By.XPATH, "//*[contains(text(), 'Location')]//following-sibling::*")
        ]

        for selector_type, selector in selectors:
            try:
                element = self.driver.find_element(selector_type, selector)
                if element and element.text:
                    return element.text.strip()
            except:
                continue

        return None

    def _extract_description(self) -> str:
        """Extract item description"""
        selectors = [
            (By.CSS_SELECTOR, ".description"),
            (By.CSS_SELECTOR, ".item-details"),
            (By.XPATH, "//*[contains(@class, 'description')]")
        ]

        for selector_type, selector in selectors:
            try:
                element = self.driver.find_element(selector_type, selector)
                if element and element.text:
                    return element.text.strip()[:500]
            except:
                continue

        return ""

    def _extract_status(self) -> str:
        """Extract auction status"""
        selectors = [
            (By.CSS_SELECTOR, ".status"),
            (By.XPATH, "//*[contains(@class, 'status')]")
        ]

        for selector_type, selector in selectors:
            try:
                element = self.driver.find_element(selector_type, selector)
                if element and element.text:
                    return element.text.strip().lower()
            except:
                continue

        # Check if auction ended
        try:
            page_text = self.driver.find_element(By.TAG_NAME, "body").text.lower()
            if 'ended' in page_text or 'closed' in page_text:
                return 'ended'
            elif 'active' in page_text or 'open' in page_text:
                return 'active'
        except:
            pass

        return "unknown"

    def close(self):
        """Close the browser"""
        if self.driver:
            self.driver.quit()
            self.driver = None

    def __enter__(self):
        """Context manager entry"""
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        self.close()


if __name__ == "__main__":
    # Test the Selenium scraper
    import json

    url = "https://www.govdeals.com/en/asset/7631/16416"

    print("Testing Selenium scraper...")
    print("=" * 60)

    with GovDealsSeleniumScraper(headless=True) as scraper:
        data = scraper.scrape_auction(url)

        if data:
            print("\nExtracted Data:")
            print(json.dumps(data, indent=2))
        else:
            print("\nFailed to scrape auction data")

    print("\n" + "=" * 60)
    print("Test complete")
