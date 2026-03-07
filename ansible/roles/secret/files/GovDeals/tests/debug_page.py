#!/usr/bin/env python3
"""
Debug script to see what's actually on a GovDeals page
"""

from src.scraper_advanced import GovDealsAdvancedScraper
from bs4 import BeautifulSoup

url = "https://www.govdeals.com/en/asset/7631/16416"

print(f"Fetching {url}...")
print("=" * 80)

scraper = GovDealsAdvancedScraper()

try:
    response = scraper.session.get(url, timeout=20)
    print(f"Status Code: {response.status_code}")
    print(f"Final URL: {response.url}")
    print(f"Content Length: {len(response.content)} bytes")
    print("\n" + "=" * 80)

    soup = BeautifulSoup(response.content, 'html.parser')

    # Show title
    if soup.title:
        print(f"Page Title: {soup.title.string}")
    print()

    # Show all h1 tags
    print("H1 Tags:")
    for h1 in soup.find_all('h1'):
        print(f"  - {h1.get_text(strip=True)}")
    print()

    # Show meta tags
    print("Meta Tags:")
    for meta in soup.find_all('meta', limit=10):
        if meta.get('property') or meta.get('name'):
            prop = meta.get('property') or meta.get('name')
            content = meta.get('content', '')
            print(f"  {prop}: {content[:80]}")
    print()

    # Look for any text mentioning 'bid', 'auction', 'price'
    page_text = soup.get_text().lower()

    keywords = ['auction', 'bid', 'price', 'sold', 'closed', 'ended', 'active']
    print("Page Content Analysis:")
    for keyword in keywords:
        if keyword in page_text:
            print(f"  ✓ Contains '{keyword}'")
        else:
            print(f"  ✗ Does NOT contain '{keyword}'")
    print()

    # Show snippet of page text
    print("Page Text Snippet (first 500 chars):")
    text = soup.get_text(separator=' ', strip=True)
    print(text[:500])
    print()

    # Look for any elements with class/id containing common auction terms
    print("Elements with auction-related classes/IDs:")
    terms = ['bid', 'price', 'time', 'auction', 'item', 'asset']
    found = False
    for term in terms:
        elements = soup.find_all(class_=lambda x: x and term in x.lower())
        elements += soup.find_all(id=lambda x: x and term in x.lower())
        if elements:
            found = True
            for elem in elements[:3]:  # Limit to first 3
                classes = elem.get('class', [])
                elem_id = elem.get('id', '')
                print(f"  - {elem.name} class={classes} id={elem_id}")
                print(f"    Text: {elem.get_text(strip=True)[:100]}")
    if not found:
        print("  (None found)")

    print("\n" + "=" * 80)

    # Save HTML to file for inspection
    with open('debug_page.html', 'w', encoding='utf-8') as f:
        f.write(response.text)
    print("Full HTML saved to: debug_page.html")

except Exception as e:
    print(f"Error: {e}")
