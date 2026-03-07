# GovDeals Auction Tracker - File Structure

**Generated:** 2026-01-06
**Project:** GovDeals Auction Tracker
**Status:** Production Ready

---

## Project Statistics

- **Total Directories:** 11
- **Total Files:** 34
- **Symlinks:** 5 (for backward compatibility)
- **Python Modules:** 8
- **Documentation Files:** 8
- **Shell Scripts:** 5
- **Test Scripts:** 4

---

## Directory Tree

```
GovDeals/
├── src/                          # Core Application (8 modules)
│   ├── __init__.py               # Package initializer (0 bytes)
│   ├── alerts.py                 # Email + ntfy notification system (9.3K)
│   ├── dashboard.py              # Flask web dashboard (13K)
│   ├── database.py               # SQLite database operations (11K)
│   ├── monitor.py                # Background monitoring service (9.9K)
│   ├── scraper.py                # Basic BeautifulSoup scraper (7.4K)
│   ├── scraper_advanced.py       # Advanced scraper with retry logic (13K)
│   └── scraper_selenium.py       # Selenium scraper for JavaScript pages (13K)
│
├── config/                       # Configuration Files
│   ├── config.json               # Alert and monitoring configuration (484 bytes)
│   └── requirements.txt          # Python dependencies (82 bytes)
│
├── data/                         # Database and Data Files
│   ├── auctions.db               # SQLite database (48K)
│   └── exports/                  # CSV export directory
│       └── .gitkeep              # Keep directory in git
│
├── docs/                         # Documentation (8 files)
│   ├── README.md                 # Quick start guide
│   ├── COMPREHENSIVE_README.md   # Complete documentation (3000+ lines)
│   ├── STATUS_TRACKING.md        # Live status tracking (auto-updated)
│   ├── LAST_MESSAGE.md           # Latest change details
│   ├── FIXES_APPLIED.md          # Fix history
│   ├── STATUS.md                 # System status
│   ├── INSTALL_CHROMEDRIVER.md   # ChromeDriver installation guide
│   ├── DIRECTORY_REORGANIZATION.md  # This reorganization log
│   └── FILE_STRUCTURE.md         # This file
│
├── scripts/                      # Setup and Launch Scripts (5 files)
│   ├── setup_complete.sh         # Full automated setup (9.0K)
│   ├── launch.sh                 # Launch dashboard + monitor (3.3K)
│   ├── install_chromedriver.sh   # ChromeDriver installer (3.4K)
│   ├── setup.sh                  # Legacy setup script (2.0K)
│   └── quick_start.sh            # Legacy quick start (801 bytes)
│
├── tests/                        # Test Scripts (4 files)
│   ├── test_full_system.py       # Full system integration test
│   ├── test_system.py            # Component tests
│   ├── example_usage.py          # API usage examples
│   └── debug_page.py             # Debug scraper output
│
├── templates/                    # Flask HTML Templates
│   └── index.html                # Dashboard web interface (17K)
│
├── files/                        # User Files
│   └── 1.png                     # User-uploaded screenshot
│
├── logs/                         # Log Files (created at runtime)
│   └── .gitkeep                  # Keep directory in git
│
├── backups/                      # Database Backups
│   └── .gitkeep                  # Keep directory in git
│
├── .gitignore                    # Git ignore rules
│
└── Symlinks (Backward Compatibility)
    ├── dashboard.py -> src/dashboard.py
    ├── monitor.py -> src/monitor.py
    ├── config.json -> config/config.json
    ├── auctions.db -> data/auctions.db
    └── requirements.txt -> config/requirements.txt
```

---

## Complete File List with Descriptions

### Core Application (`src/`)

| File | Size | Description |
|------|------|-------------|
| `__init__.py` | 0 | Python package initializer |
| `alerts.py` | 9.3K | Email and ntfy.sh notification system with configurable alerts |
| `dashboard.py` | 13K | Flask web server providing REST API and web interface |
| `database.py` | 11K | SQLite database management with concurrent access support |
| `monitor.py` | 9.9K | Background service for continuous auction monitoring |
| `scraper.py` | 7.4K | Basic BeautifulSoup scraper (fast, limited functionality) |
| `scraper_advanced.py` | 13K | Advanced scraper with custom headers and retry logic |
| `scraper_selenium.py` | 13K | Selenium-based scraper for JavaScript-heavy pages |

### Configuration (`config/`)

| File | Size | Description |
|------|------|-------------|
| `config.json` | 484B | Alert configuration (email, ntfy, monitoring intervals) |
| `requirements.txt` | 82B | Python package dependencies for pip installation |

### Data (`data/`)

| File | Size | Description |
|------|------|-------------|
| `auctions.db` | 48K | SQLite database storing watched auctions and history |
| `exports/.gitkeep` | 0 | Placeholder for CSV export directory |

### Documentation (`docs/`)

| File | Lines | Description |
|------|-------|-------------|
| `README.md` | ~200 | Quick start guide and basic usage |
| `COMPREHENSIVE_README.md` | 3000+ | Complete documentation with installation, API, troubleshooting |
| `STATUS_TRACKING.md` | ~300 | Live status tracking, auto-updated with each change |
| `LAST_MESSAGE.md` | ~200 | Details of most recent change/fix |
| `FIXES_APPLIED.md` | ~150 | Historical record of fixes |
| `STATUS.md` | ~150 | Current system status |
| `INSTALL_CHROMEDRIVER.md` | ~150 | ChromeDriver installation instructions |
| `DIRECTORY_REORGANIZATION.md` | ~350 | This reorganization documentation |
| `FILE_STRUCTURE.md` | ~400 | This file - complete file structure reference |

### Scripts (`scripts/`)

| File | Size | Description |
|------|------|-------------|
| `setup_complete.sh` | 9.0K | Full automated setup for fresh Ubuntu systems |
| `launch.sh` | 3.3K | Interactive launcher for dashboard and monitor |
| `install_chromedriver.sh` | 3.4K | ChromeDriver installation script |
| `setup.sh` | 2.0K | Legacy setup script |
| `quick_start.sh` | 801B | Legacy quick start script |

### Tests (`tests/`)

| File | Description |
|------|-------------|
| `test_full_system.py` | Full system integration test (database, scrapers, all components) |
| `test_system.py` | Component-level tests (imports, database, config) |
| `example_usage.py` | API usage examples demonstrating common tasks |
| `debug_page.py` | Debug tool to inspect scraper output and page content |

### Templates (`templates/`)

| File | Size | Description |
|------|------|-------------|
| `index.html` | 17K | Dashboard web interface with real-time updates |

### Root Files

| File | Type | Target | Description |
|------|------|--------|-------------|
| `.gitignore` | File | - | Git ignore rules for database, logs, config secrets |
| `dashboard.py` | Symlink | src/dashboard.py | Backward compatibility symlink |
| `monitor.py` | Symlink | src/monitor.py | Backward compatibility symlink |
| `config.json` | Symlink | config/config.json | Backward compatibility symlink |
| `auctions.db` | Symlink | data/auctions.db | Backward compatibility symlink |
| `requirements.txt` | Symlink | config/requirements.txt | Backward compatibility symlink |

---

## File Categories by Purpose

### Python Source Code (8 files)
```
src/alerts.py
src/dashboard.py
src/database.py
src/monitor.py
src/scraper.py
src/scraper_advanced.py
src/scraper_selenium.py
src/__init__.py
```

### Configuration (2 files)
```
config/config.json
config/requirements.txt
```

### Documentation (9 files)
```
docs/README.md
docs/COMPREHENSIVE_README.md
docs/STATUS_TRACKING.md
docs/LAST_MESSAGE.md
docs/FIXES_APPLIED.md
docs/STATUS.md
docs/INSTALL_CHROMEDRIVER.md
docs/DIRECTORY_REORGANIZATION.md
docs/FILE_STRUCTURE.md
```

### Shell Scripts (5 files)
```
scripts/setup_complete.sh
scripts/launch.sh
scripts/install_chromedriver.sh
scripts/setup.sh
scripts/quick_start.sh
```

### Test Scripts (4 files)
```
tests/test_full_system.py
tests/test_system.py
tests/example_usage.py
tests/debug_page.py
```

### Web Templates (1 file)
```
templates/index.html
```

### Database (1 file)
```
data/auctions.db
```

### Symlinks (5 files)
```
dashboard.py -> src/dashboard.py
monitor.py -> src/monitor.py
config.json -> config/config.json
auctions.db -> data/auctions.db
requirements.txt -> config/requirements.txt
```

---

## Import Structure

### External Dependencies
```python
# Web Framework
flask

# Web Scraping
requests
beautifulsoup4
selenium

# Notifications
requests (for ntfy)
smtplib (built-in, for email)
```

### Internal Module Dependencies
```
dashboard.py
  ├── database.py
  ├── scraper.py
  ├── scraper_advanced.py
  └── scraper_selenium.py

monitor.py
  ├── database.py
  ├── scraper.py
  ├── scraper_advanced.py
  ├── scraper_selenium.py
  └── alerts.py

alerts.py
  └── (no internal dependencies)

database.py
  └── (no internal dependencies)

scraper*.py
  └── (no internal dependencies)
```

---

## Key Entry Points

### For Users
- `scripts/setup_complete.sh` - First-time setup
- `scripts/launch.sh` - Launch application
- `dashboard.py` (symlink) - Direct dashboard launch
- `monitor.py` (symlink) - Direct monitor launch

### For Developers
- `src/dashboard.py` - Web dashboard entry point
- `src/monitor.py` - Monitor service entry point
- `tests/test_full_system.py` - Run all tests
- `docs/COMPREHENSIVE_README.md` - Complete reference

### For Documentation
- `docs/README.md` - Quick start
- `docs/COMPREHENSIVE_README.md` - Complete guide
- `docs/STATUS_TRACKING.md` - Current status
- `docs/FILE_STRUCTURE.md` - This file

---

## Runtime Generated Files

These files are created at runtime and ignored by git:

```
logs/
  └── *.log                    # Application logs

data/
  ├── auctions.db              # Created on first run (if doesn't exist)
  ├── auctions.db-journal      # SQLite journal file
  └── exports/
      └── *.csv                # CSV exports

__pycache__/                   # Python bytecode cache
  └── *.pyc
```

---

## Git Ignore Rules

The `.gitignore` file excludes:

```
# Database files
data/*.db
data/*.db-journal

# Configuration with secrets
config/config.json

# Python cache
__pycache__/
*.pyc

# Logs
logs/*.log

# Exports
data/exports/*.csv

# Backups
backups/*.db

# Selenium logs
geckodriver.log
chromedriver.log
```

---

## Modification History

| Date | Event | Description |
|------|-------|-------------|
| 2026-01-06 | Initial Development | Created all core functionality |
| 2026-01-06 13:31 | Data Population Fix | Added automatic snapshot save on auction add |
| 2026-01-06 18:38 | Directory Reorganization | Reorganized entire project structure |
| 2026-01-06 18:40 | Documentation | Created this file structure document |

---

## Quick Reference Commands

### Using Symlinks (Backward Compatible)
```bash
python3 dashboard.py              # Launch dashboard
python3 monitor.py --add          # Add auction via CLI
nano config.json                  # Edit configuration
```

### Using New Structure Directly
```bash
python3 src/dashboard.py          # Launch dashboard
python3 src/monitor.py --add      # Add auction via CLI
nano config/config.json           # Edit configuration
scripts/launch.sh                 # Launch with script
```

### Development
```bash
python3 tests/test_full_system.py # Run full system tests
python3 tests/example_usage.py    # See API examples
```

### Setup
```bash
scripts/setup_complete.sh         # Automated setup
scripts/launch.sh                 # Launch services
```

---

**End of File Structure Documentation**
