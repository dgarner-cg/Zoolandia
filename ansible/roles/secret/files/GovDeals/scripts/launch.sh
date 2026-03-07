#!/bin/bash
# Launch Script for GovDeals Auction Tracker
# Starts both dashboard and monitor services

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         GovDeals Auction Tracker - Launcher                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if already running
if pgrep -f "dashboard.py" > /dev/null; then
    echo -e "${YELLOW}⚠${NC}  Dashboard already running (PID: $(pgrep -f dashboard.py))"
    echo ""
    read -p "Kill existing dashboard and restart? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pkill -f dashboard.py
        sleep 1
    else
        echo "Exiting..."
        exit 0
    fi
fi

# Start dashboard in background
echo -e "${BLUE}►${NC} Starting dashboard..."
python3 src/dashboard.py > /dev/null 2>&1 &
DASHBOARD_PID=$!

# Wait for dashboard to start
sleep 2

# Check if dashboard started successfully
if ps -p $DASHBOARD_PID > /dev/null; then
    echo -e "${GREEN}✓${NC} Dashboard started (PID: $DASHBOARD_PID)"
    echo "  → http://127.0.0.1:5000"
else
    echo -e "${RED}✗${NC} Dashboard failed to start"
    exit 1
fi

# Try to open browser
echo ""
echo -e "${BLUE}►${NC} Opening browser..."
if command -v xdg-open &> /dev/null; then
    xdg-open http://127.0.0.1:5000 &> /dev/null &
elif command -v open &> /dev/null; then
    open http://127.0.0.1:5000 &> /dev/null &
else
    echo "  Could not auto-open browser"
    echo "  Manually visit: http://127.0.0.1:5000"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Dashboard is running!"
echo ""
echo "Options:"
echo "  1. Use dashboard only (current mode)"
echo "  2. Start monitoring service as well"
echo "  3. Quit"
echo ""
read -p "Select option (1/2/3): " -n 1 -r
echo ""
echo ""

if [[ $REPLY == "2" ]]; then
    echo -e "${BLUE}►${NC} Starting monitoring service..."
    echo ""
    echo "Press Ctrl+C to stop both services"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Trap Ctrl+C
    trap "echo ''; echo 'Stopping services...'; kill $DASHBOARD_PID 2>/dev/null; echo 'Stopped.'; exit 0" INT

    # Run monitor in foreground
    python3 src/monitor.py

elif [[ $REPLY == "3" ]]; then
    echo "Stopping dashboard..."
    kill $DASHBOARD_PID 2>/dev/null
    echo "Stopped."
    exit 0
else
    # Dashboard only mode
    echo "Dashboard running in background (PID: $DASHBOARD_PID)"
    echo ""
    echo "To stop:"
    echo "  kill $DASHBOARD_PID"
    echo "  # or"
    echo "  pkill -f dashboard.py"
    echo ""
    echo "To start monitor later:"
    echo "  python3 src/monitor.py"
    echo ""
fi
