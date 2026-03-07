#!/bin/bash
# Quick start script - runs both dashboard and monitor

echo "Starting GovDeals Auction Tracker..."
echo ""

# Start dashboard in background
echo "Starting dashboard on http://127.0.0.1:5000"
python3 dashboard.py &
DASHBOARD_PID=$!

# Wait a moment for dashboard to start
sleep 2

# Open browser (try common commands)
if command -v xdg-open &> /dev/null; then
    xdg-open http://127.0.0.1:5000 &> /dev/null
elif command -v open &> /dev/null; then
    open http://127.0.0.1:5000 &> /dev/null
fi

echo "Dashboard started (PID: $DASHBOARD_PID)"
echo ""
echo "Starting monitor..."
echo "Press Ctrl+C to stop both services"
echo ""

# Start monitor in foreground
python3 monitor.py

# Cleanup when monitor stops
echo ""
echo "Stopping dashboard..."
kill $DASHBOARD_PID 2>/dev/null
echo "Done"
