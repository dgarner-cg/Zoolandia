#!/bin/bash
# Setup script for GovDeals Auction Tracker

echo "GovDeals Auction Tracker - Setup"
echo "================================="
echo ""

# Check Python version
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed"
    exit 1
fi

echo "✓ Python 3 found: $(python3 --version)"

# Install dependencies
echo ""
echo "Installing Python dependencies..."
pip3 install -r requirements.txt --break-system-packages

if [ $? -eq 0 ]; then
    echo "✓ Dependencies installed successfully"
else
    echo "✗ Failed to install dependencies"
    exit 1
fi

# Create config if it doesn't exist
if [ ! -f "config.json" ]; then
    echo ""
    echo "Creating default config.json..."
    cat > config.json << 'EOF'
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
      "topic": "govdeals_alerts",
      "server": "https://ntfy.sh"
    }
  },
  "monitoring": {
    "check_interval": 300,
    "alert_cooldown": 3600
  }
}
EOF
    echo "✓ Created config.json"
    echo "  Please edit config.json to configure your alerts"
else
    echo "✓ config.json already exists"
fi

# Initialize database
echo ""
echo "Initializing database..."
python3 -c "from database import AuctionDatabase; AuctionDatabase()"

if [ $? -eq 0 ]; then
    echo "✓ Database initialized"
else
    echo "✗ Failed to initialize database"
    exit 1
fi

echo ""
echo "================================="
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit config.json to configure email/ntfy alerts"
echo "2. Add auctions to watch:"
echo "   python3 monitor.py --add"
echo "3. Start the dashboard:"
echo "   python3 dashboard.py"
echo "4. Start monitoring:"
echo "   python3 monitor.py"
echo ""
echo "See README.md for detailed usage instructions"
