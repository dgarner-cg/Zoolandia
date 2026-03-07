# Installing ChromeDriver for Selenium Scraper

The GovDeals website blocks simple automated requests, so we need to use Selenium with a headless browser to scrape the data properly.

## Quick Install (Recommended)

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install chromium-browser chromium-chromedriver
```

### Alternative: Chrome + ChromeDriver
```bash
# Install Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt-get install -f

# Download ChromeDriver (check version compatibility)
# Visit: https://googlechromelabs.github.io/chrome-for-testing/
# Or use the automatic script below
```

## Automatic ChromeDriver Setup Script

Save this as `install_chromedriver.sh` and run it:

```bash
#!/bin/bash
# Automatic ChromeDriver installer

echo "Installing ChromeDriver..."

# Detect Chrome/Chromium version
if command -v google-chrome &> /dev/null; then
    CHROME_VERSION=$(google-chrome --version | awk '{print $3}' | cut -d'.' -f1)
    echo "Found Google Chrome version: $CHROME_VERSION"
elif command -v chromium-browser &> /dev/null; then
    CHROME_VERSION=$(chromium-browser --version | awk '{print $2}' | cut -d'.' -f1)
    echo "Found Chromium version: $CHROME_VERSION"
else
    echo "Chrome/Chromium not found. Installing Chromium..."
    sudo apt-get update
    sudo apt-get install -y chromium-browser
    CHROME_VERSION=$(chromium-browser --version | awk '{print $2}' | cut -d'.' -f1)
fi

# Download and install ChromeDriver
echo "Downloading ChromeDriver..."
CHROMEDRIVER_URL="https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_VERSION}"
LATEST_VERSION=$(curl -s $CHROMEDRIVER_URL)

if [ -z "$LATEST_VERSION" ]; then
    echo "Could not determine ChromeDriver version. Using latest stable..."
    LATEST_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE")
fi

echo "ChromeDriver version: $LATEST_VERSION"

wget -q "https://chromedriver.storage.googleapis.com/${LATEST_VERSION}/chromedriver_linux64.zip"
unzip -o chromedriver_linux64.zip
chmod +x chromedriver
sudo mv chromedriver /usr/local/bin/
rm chromedriver_linux64.zip

echo "✓ ChromeDriver installed successfully"
chromedriver --version
```

Make it executable and run:
```bash
chmod +x install_chromedriver.sh
./install_chromedriver.sh
```

## Verify Installation

Test that Selenium can run:

```bash
python3 scraper_selenium.py
```

Or test from Python:
```python
from selenium import webdriver
driver = webdriver.Chrome()
driver.get("https://www.google.com")
print(driver.title)
driver.quit()
```

## Troubleshooting

### Error: "chromedriver not found in PATH"

Make sure chromedriver is in your PATH:
```bash
# Check if it's installed
which chromedriver

# If not found, try:
sudo apt-get install chromium-chromedriver

# Or manually download and add to PATH
export PATH=$PATH:/path/to/chromedriver
```

### Error: "Chrome version mismatch"

Your ChromeDriver version must match your Chrome version:
```bash
# Check Chrome version
google-chrome --version
# or
chromium-browser --version

# Check ChromeDriver version
chromedriver --version

# If they don't match, reinstall ChromeDriver
```

### Error: "selenium.common.exceptions.SessionNotCreatedException"

This usually means version mismatch. Try:
```bash
# Update everything
sudo apt-get update
sudo apt-get upgrade chromium-browser chromium-chromedriver
```

### Running in WSL or Headless Server

If you don't have a display, you might need additional packages:
```bash
sudo apt-get install -y xvfb

# Run with virtual display
xvfb-run python3 scraper_selenium.py
```

Or ensure you're using headless mode (which is default):
```python
scraper = GovDealsSeleniumScraper(headless=True)
```

## Alternative: Use Docker

If you prefer using Docker:

```dockerfile
FROM python:3.12-slim

# Install Chrome and ChromeDriver
RUN apt-get update && apt-get install -y \
    chromium \
    chromium-driver \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy application
COPY . /app
WORKDIR /app

CMD ["python3", "monitor.py"]
```

## Testing the Scraper

Once installed, test with:

```bash
# Test Selenium scraper
python3 scraper_selenium.py

# Test in monitor
python3 monitor.py --check-now

# Test via dashboard
python3 dashboard.py
# Then click "Refresh" on an auction
```

## Performance Notes

- Selenium is slower than the regular scraper (5-10 seconds vs 1-2 seconds)
- The system automatically falls back to Selenium only when needed
- Uses headless mode by default (no GUI window)
- Each scrape opens and closes a browser instance

## Security Notes

- Selenium runs real Chrome browser code
- Always use headless=True in production
- Don't run as root if possible
- Keep Chrome/ChromeDriver updated for security patches
