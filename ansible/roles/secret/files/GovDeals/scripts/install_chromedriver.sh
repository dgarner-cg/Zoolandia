#!/bin/bash
# Automatic ChromeDriver installer for GovDeals scraper

echo "GovDeals ChromeDriver Installer"
echo "================================"
echo ""

# Check if running on a Debian/Ubuntu system
if ! command -v apt-get &> /dev/null; then
    echo "This script is designed for Debian/Ubuntu systems"
    echo "For other systems, please install Chrome/Chromium and ChromeDriver manually"
    echo "See INSTALL_CHROMEDRIVER.md for more information"
    exit 1
fi

# Check for Chromium first (easiest option)
if command -v chromium-browser &> /dev/null || command -v chromium &> /dev/null; then
    echo "✓ Chromium already installed"
else
    echo "Installing Chromium browser..."
    sudo apt-get update
    sudo apt-get install -y chromium-browser

    if [ $? -eq 0 ]; then
        echo "✓ Chromium installed successfully"
    else
        echo "✗ Failed to install Chromium"
        exit 1
    fi
fi

# Install ChromeDriver
if command -v chromedriver &> /dev/null; then
    echo "✓ ChromeDriver already installed"
    chromedriver --version
else
    echo "Installing ChromeDriver..."
    sudo apt-get install -y chromium-chromedriver

    if [ $? -eq 0 ]; then
        echo "✓ ChromeDriver installed successfully"
        chromedriver --version
    else
        echo "✗ Failed to install ChromeDriver via apt"
        echo "Attempting manual download..."

        # Try manual download
        LATEST_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE")

        if [ -z "$LATEST_VERSION" ]; then
            echo "✗ Could not determine ChromeDriver version"
            exit 1
        fi

        echo "Downloading ChromeDriver version $LATEST_VERSION..."
        wget -q "https://chromedriver.storage.googleapis.com/${LATEST_VERSION}/chromedriver_linux64.zip"

        if [ $? -ne 0 ]; then
            echo "✗ Download failed"
            exit 1
        fi

        unzip -o chromedriver_linux64.zip
        chmod +x chromedriver
        sudo mv chromedriver /usr/local/bin/
        rm chromedriver_linux64.zip

        echo "✓ ChromeDriver installed manually"
        chromedriver --version
    fi
fi

# Verify ChromeDriver works
echo ""
echo "Verifying ChromeDriver installation..."

if chromedriver --version &> /dev/null; then
    echo "✓ ChromeDriver is working"
else
    echo "✗ ChromeDriver verification failed"
    exit 1
fi

# Test with Python
echo ""
echo "Testing Selenium with Python..."

python3 -c "
try:
    from selenium import webdriver
    from selenium.webdriver.chrome.options import Options

    options = Options()
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')

    driver = webdriver.Chrome(options=options)
    driver.get('https://www.google.com')
    print('✓ Selenium test successful')
    print('  Page title:', driver.title)
    driver.quit()
except Exception as e:
    print('✗ Selenium test failed:', e)
    exit(1)
"

if [ $? -eq 0 ]; then
    echo ""
    echo "================================"
    echo "✓ Installation complete!"
    echo ""
    echo "You can now use the Selenium scraper:"
    echo "  python3 scraper_selenium.py"
    echo "  python3 monitor.py --check-now"
    echo ""
else
    echo ""
    echo "✗ Installation completed but Selenium test failed"
    echo "See INSTALL_CHROMEDRIVER.md for troubleshooting"
    exit 1
fi
