#!/bin/bash
# Complete Setup Script for GovDeals Auction Tracker
# Designed for fresh Ubuntu systems

set -e  # Exit on error

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   GovDeals Auction Tracker - Complete System Setup          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    error "Please do not run as root. Run as normal user (will prompt for sudo when needed)"
    exit 1
fi

# Step 1: Check Python 3
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Checking Python 3"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    success "Python 3 found: $PYTHON_VERSION"
else
    error "Python 3 not found"
    info "Installing Python 3..."
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip python3-venv
    success "Python 3 installed"
fi

# Step 2: Install Google Chrome
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Installing Google Chrome"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v google-chrome &> /dev/null; then
    CHROME_VERSION=$(google-chrome --version)
    success "Chrome already installed: $CHROME_VERSION"
else
    info "Downloading Google Chrome..."
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

    info "Installing Google Chrome..."
    sudo dpkg -i google-chrome-stable_current_amd64.deb 2>/dev/null || true
    sudo apt-get install -f -y

    rm google-chrome-stable_current_amd64.deb
    success "Google Chrome installed"
fi

# Step 3: Install ChromeDriver
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Installing ChromeDriver"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v chromedriver &> /dev/null; then
    DRIVER_VERSION=$(chromedriver --version 2>&1 | head -1)
    success "ChromeDriver already installed: $DRIVER_VERSION"
else
    info "Installing ChromeDriver..."
    sudo apt-get install -y chromium-chromedriver
    success "ChromeDriver installed"
fi

# Step 4: Install Python Dependencies
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Installing Python Dependencies"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

info "Installing Python packages..."
pip3 install -r config/requirements.txt --break-system-packages --quiet

if [ $? -eq 0 ]; then
    success "Python dependencies installed"
else
    error "Failed to install Python dependencies"
    exit 1
fi

# Verify key packages
python3 -c "import flask, selenium, bs4" 2>/dev/null
if [ $? -eq 0 ]; then
    success "Verified: Flask, Selenium, BeautifulSoup4"
else
    error "Package verification failed"
    exit 1
fi

# Step 5: Initialize Database
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5: Initializing Database"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

python3 -c "from src.database import AuctionDatabase; AuctionDatabase()" 2>&1

if [ -f "data/auctions.db" ]; then
    DB_SIZE=$(ls -lh data/auctions.db | awk '{print $5}')
    success "Database initialized (data/auctions.db - $DB_SIZE)"
else
    error "Database initialization failed"
    exit 1
fi

# Step 6: Create Configuration
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 6: Creating Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "config/config.json" ]; then
    success "config/config.json already exists (keeping existing configuration)"
else
    cat > config/config.json << 'EOF'
{
  "alerts": {
    "email": {
      "enabled": false,
      "smtp_server": "smtp.gmail.com",
      "smtp_port": 587,
      "username": "your_email@gmail.com",
      "password": "your_app_password",
      "from_addr": "your_email@gmail.com",
      "to_addr": "recipient@example.com"
    },
    "ntfy": {
      "enabled": true,
      "topic": "govdeals_alerts_changeme",
      "server": "https://ntfy.sh"
    }
  },
  "monitoring": {
    "check_interval": 300,
    "alert_cooldown": 3600
  }
}
EOF
    success "Created default config/config.json"
    info "Edit config/config.json to configure your alerts"
fi

# Step 7: Run System Tests
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 7: Running System Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

python3 tests/test_full_system.py > /tmp/govdeals_test.log 2>&1
TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -eq 0 ]; then
    success "All system tests passed"
else
    error "Some tests failed (see /tmp/govdeals_test.log)"
    info "This may be normal if you haven't configured alerts yet"
fi

# Summary
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    SETUP COMPLETE!                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Installation Summary:"
echo "   • Python 3: Installed and verified"
echo "   • Google Chrome: Installed"
echo "   • ChromeDriver: Installed"
echo "   • Python packages: Installed"
echo "   • Database: Initialized"
echo "   • Configuration: Created"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. Configure alerts (optional):"
echo "   nano config/config.json"
echo ""
echo "2. Start the dashboard:"
echo "   scripts/launch.sh"
echo "   # Or manually: python3 src/dashboard.py"
echo ""
echo "3. Open dashboard in browser:"
echo "   http://127.0.0.1:5000"
echo ""
echo "4. Add your first auction:"
echo "   Click '+ Add Auction' in the dashboard"
echo ""
echo "📚 Documentation:"
echo "   • docs/COMPREHENSIVE_README.md - Full documentation"
echo "   • docs/STATUS_TRACKING.md - Current system status"
echo "   • docs/README.md - Quick start guide"
echo ""
echo "🔧 Useful Commands:"
echo "   scripts/launch.sh          - Start dashboard and monitor"
echo "   python3 src/monitor.py --add  - Add auction via CLI"
echo "   python3 src/monitor.py --list - List watched auctions"
echo ""

# Ask if user wants to launch now
echo ""
read -p "Would you like to launch the dashboard now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    info "Launching dashboard..."
    echo ""
    echo "Dashboard will start on http://127.0.0.1:5000"
    echo "Press Ctrl+C to stop"
    echo ""
    sleep 2
    python3 src/dashboard.py
fi
