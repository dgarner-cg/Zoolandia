# GovDeals Auction Tracker

A comprehensive monitoring system for GovDeals auctions that tracks auction data, sends alerts when items are ending soon, and provides a live web dashboard for tracking your watched items.

## Features

- **Web Scraping**: Automatically fetches auction details (current bid, time remaining, number of bids, etc.)
- **Database Storage**: Stores auction history in SQLite database with full historical tracking
- **Live Web Dashboard**: Beautiful, responsive dashboard to monitor all watched auctions
- **Alert System**: Sends notifications via email and/or ntfy when auctions are ending soon
- **Flexible Configuration**: Customize alert thresholds, check intervals, and notification methods
- **Auto-refresh**: Dashboard auto-updates every 60 seconds
- **Manual Controls**: Refresh individual auctions or all at once

## Quick Start

### 1. Installation

```bash
# Install Python dependencies
pip install -r requirements.txt

# Or install individually
pip install beautifulsoup4 requests Flask selenium lxml
```

### 2. Configuration

Edit `config.json` to configure your alert methods:

**For Email Alerts (Gmail example):**
```json
{
  "alerts": {
    "email": {
      "enabled": true,
      "smtp_server": "smtp.gmail.com",
      "smtp_port": 587,
      "username": "your_email@gmail.com",
      "password": "your_app_password",
      "from_addr": "your_email@gmail.com",
      "to_addr": "recipient@example.com"
    }
  }
}
```

**For ntfy Alerts:**
```json
{
  "alerts": {
    "ntfy": {
      "enabled": true,
      "topic": "your_unique_topic_name",
      "server": "https://ntfy.sh"
    }
  }
}
```

**Gmail App Password Setup:**
1. Go to Google Account settings
2. Enable 2-factor authentication
3. Generate an App Password for "Mail"
4. Use that password in the config (not your regular password)

**ntfy Setup:**
1. Install ntfy app on your phone or use https://ntfy.sh in browser
2. Subscribe to your chosen topic name
3. Notifications will appear instantly when alerts are sent

### 3. Add Auctions to Watch

**Option A: Using the Web Dashboard**
```bash
# Start the dashboard
python dashboard.py

# Open browser to http://127.0.0.1:5000
# Click "Add Auction" and enter the URL
```

**Option B: Using Command Line**
```bash
# Interactive mode
python monitor.py --add

# Follow the prompts to enter auction details
```

**Option C: Using Python**
```python
from database import AuctionDatabase

db = AuctionDatabase()
db.add_watched_auction(
    url="https://www.govdeals.com/en/asset/7631/16416",
    title="My Auction Item",
    alert_threshold_minutes=60,  # Alert when < 60 minutes remain
    notes="Want to bid on this"
)
```

### 4. Start Monitoring

```bash
# Start the background monitor (checks every 5 minutes by default)
python monitor.py

# Or customize the check interval
python monitor.py --interval 300  # Check every 300 seconds (5 min)

# Check all auctions once without continuous monitoring
python monitor.py --check-now

# List all watched auctions
python monitor.py --list
```

### 5. View Dashboard

```bash
# Start the web dashboard
python dashboard.py

# Access at http://127.0.0.1:5000
# Or bind to all interfaces
python dashboard.py --host 0.0.0.0 --port 8080
```

## Usage Guide

### Web Dashboard

The dashboard provides:
- **Statistics**: Total watched, active auctions, ending soon count, alerts in last 24h
- **Auction Cards**: Each showing current bid, time remaining, number of bids
- **Color Coding**: Red border for auctions ending soon
- **Actions**: Refresh, view on GovDeals, remove from watchlist
- **Auto-refresh**: Dashboard updates automatically every 60 seconds

### Command Line Tools

**Test the scraper:**
```bash
python scraper.py
```

**Test the database:**
```bash
python database.py
```

**Test alerts:**
```bash
python alerts.py
```

**Export data to CSV:**
```python
from database import AuctionDatabase
db = AuctionDatabase()
db.export_to_csv("my_export.csv")
```

### Alert Thresholds

Each auction can have its own alert threshold. When the time remaining drops below this threshold, you'll receive notifications via your configured methods.

Examples:
- `60` minutes = Alert when less than 1 hour remains
- `120` minutes = Alert when less than 2 hours remain
- `30` minutes = Alert when less than 30 minutes remain

### Monitoring Service

The monitor runs continuously and:
1. Checks all active auctions at regular intervals (default: 5 minutes)
2. Scrapes current auction data
3. Saves historical snapshots to database
4. Compares against alert thresholds
5. Sends notifications when thresholds are crossed
6. Tracks price changes and bid updates

## Project Structure

```
GovDeals/
├── scraper.py          # Web scraping logic
├── database.py         # SQLite database management
├── alerts.py           # Email and ntfy notification system
├── monitor.py          # Background monitoring service
├── dashboard.py        # Flask web dashboard
├── templates/
│   └── index.html      # Dashboard HTML template
├── config.json         # Configuration file
├── requirements.txt    # Python dependencies
├── auctions.db         # SQLite database (created automatically)
└── README.md           # This file
```

## Advanced Usage

### Running Monitor as a Service

**Linux (systemd):**

Create `/etc/systemd/system/govdeals-monitor.service`:
```ini
[Unit]
Description=GovDeals Auction Monitor
After=network.target

[Service]
Type=simple
User=your_username
WorkingDirectory=/path/to/GovDeals
ExecStart=/usr/bin/python3 /path/to/GovDeals/monitor.py
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable govdeals-monitor
sudo systemctl start govdeals-monitor
```

**Using screen/tmux:**
```bash
# Using screen
screen -S govdeals
python monitor.py
# Press Ctrl+A then D to detach

# Reattach later
screen -r govdeals

# Using tmux
tmux new -s govdeals
python monitor.py
# Press Ctrl+B then D to detach

# Reattach later
tmux attach -t govdeals
```

### Running Dashboard as a Service

Similar to monitor, create a service file for `dashboard.py`:
```bash
ExecStart=/usr/bin/python3 /path/to/GovDeals/dashboard.py --host 0.0.0.0 --port 5000
```

### Database Queries

Access the SQLite database directly:
```bash
sqlite3 auctions.db

# View watched auctions
SELECT * FROM watched_auctions;

# View auction history
SELECT * FROM auction_history ORDER BY scraped_at DESC LIMIT 10;

# View recent alerts
SELECT * FROM alerts ORDER BY sent_at DESC LIMIT 10;
```

### Using with Selenium (for JavaScript-heavy pages)

If the basic scraper doesn't work due to JavaScript rendering, modify `scraper.py` to use Selenium:

```python
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait

# Initialize Chrome driver
driver = webdriver.Chrome()
driver.get(url)

# Wait for elements to load
wait = WebDriverWait(driver, 10)
# ... extract data using Selenium methods
```

## Troubleshooting

### Scraper returns empty data
- GovDeals may have changed their HTML structure
- Try using Selenium instead of requests/BeautifulSoup
- Check if the URL is correct and auction is still active

### Email alerts not working
- Verify SMTP settings in config.json
- For Gmail, ensure you're using an App Password, not your regular password
- Check if 2-factor authentication is enabled
- Test with a different SMTP server

### ntfy notifications not arriving
- Verify you're subscribed to the correct topic
- Check if the ntfy server is accessible
- Try sending a test notification manually:
  ```bash
  curl -d "Test notification" https://ntfy.sh/your_topic
  ```

### Dashboard not loading
- Check if Flask is installed: `pip install Flask`
- Verify port 5000 is not in use: `netstat -an | grep 5000`
- Check browser console for JavaScript errors

### Database locked errors
- Only run one instance of monitor.py at a time
- Close any open database connections
- Delete `auctions.db` and restart (warning: loses history)

## API Endpoints

The dashboard provides a REST API:

- `GET /api/auctions` - Get all watched auctions with latest data
- `GET /api/auction/<id>` - Get detailed auction data with history
- `POST /api/auction/add` - Add new auction to watchlist
- `POST /api/auction/<id>/remove` - Remove auction from watchlist
- `POST /api/auction/<id>/refresh` - Manually refresh auction data
- `GET /api/alerts/recent?hours=24` - Get recent alerts
- `GET /api/stats` - Get dashboard statistics

Example API usage:
```bash
# Add auction via API
curl -X POST http://localhost:5000/api/auction/add \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.govdeals.com/...", "alert_threshold_minutes": 60}'

# Get all auctions
curl http://localhost:5000/api/auctions
```

## Security Considerations

- Store `config.json` securely (contains email password)
- Add `config.json` to `.gitignore` if using version control
- Use app passwords instead of main passwords
- Consider using environment variables for sensitive data
- Don't expose the dashboard publicly without authentication

## License

This is a personal project created for monitoring government surplus auctions. Use responsibly and in accordance with GovDeals terms of service.

## Tips

1. **Be respectful**: Don't set check intervals too low (< 60 seconds)
2. **Monitor wisely**: Only watch auctions you're actually interested in
3. **Set realistic thresholds**: 60-120 minutes gives you time to react
4. **Check regularly**: Even with alerts, manually check the dashboard
5. **Backup your data**: Export to CSV periodically

## Future Enhancements

Potential improvements:
- SMS alerts via Twilio
- Browser push notifications
- Price prediction based on historical data
- Multiple user support with authentication
- Mobile app
- Automatic bidding (use with extreme caution!)
- Export to Excel with charts
- Telegram bot integration

---

Happy bidding!
