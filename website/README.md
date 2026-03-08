# hack3r.gg

A modern information security blog and research platform. Clean, minimal design inspired by OpenAI's blog, adapted with a cybersecurity aesthetic.

## Quick Start

```bash
cd /home/cicero/proj/website
python3 -m http.server 8080
```

Open http://localhost:8080 in your browser.

## Pages

| File | Route | Description |
|------|-------|-------------|
| `index.html` | `/` | Blog homepage with featured post, card grid, category filters, newsletter signup |
| `post.html` | `/post.html` | Sample article page with table of contents, code blocks, callouts, author bio |
| `research.html` | `/research.html` | Research hub with focus areas, featured paper, chronological paper list, disclosure policy |
| `about.html` | `/about.html` | About page with mission, values, stats, team bios, company timeline |
| `contact.html` | `/contact.html` | Contact form, email/PGP/social info, FAQ section |

## Stylesheets

| File | Purpose |
|------|---------|
| `style.css` | Global styles, CSS variables, nav, footer, blog cards, newsletter, search modal, responsive breakpoints |
| `pages.css` | Shared styles for About, Research, and Contact pages (values grid, team cards, timeline, form, FAQ, etc.) |
| `post.css` | Article-specific styles (reading layout, TOC, code blocks, callouts, share buttons, author bio) |

## JavaScript (`script.js`)

- **Theme toggle** - Light/dark mode with localStorage persistence and system preference detection
- **Mobile menu** - Hamburger menu for small screens
- **Search modal** - Opens with button click or `Ctrl/Cmd + K`, filters sample post data, highlights matches
- **Category filtering** - Filters blog cards and featured post by category tag
- **Newsletter form** - Client-side submit with success feedback
- **Scroll behavior** - Navbar auto-hides on scroll down, reappears on scroll up
- **Animations** - Intersection Observer fade-in for post cards

## Design System

### Colors (CSS custom properties)

The site uses CSS variables on `:root` (light) and `[data-theme="dark"]` for full theme support.

| Variable | Light | Dark |
|----------|-------|------|
| `--bg-primary` | `#ffffff` | `#0d0d0d` |
| `--bg-secondary` | `#f7f7f8` | `#1a1a1a` |
| `--text-primary` | `#0d0d0d` | `#ececf1` |
| `--text-secondary` | `#4a4a4a` | `#b4b4b4` |
| `--accent-primary` | `#10a37f` | `#10a37f` |
| `--border-color` | `#e5e5e5` | `#2d2d2d` |

### Typography

- **Body**: Inter (400, 500, 600, 700) via Google Fonts
- **Code / Logo**: JetBrains Mono (400, 500) via Google Fonts

### Breakpoints

- `1024px` - 2-column grids, stacked featured post
- `768px` - Single column, mobile nav, stacked forms
- `480px` - Tighter padding, single-column footer

## Project Structure

```
website/
  index.html        # Blog homepage
  post.html         # Article detail page
  about.html        # About page
  research.html     # Research page
  contact.html      # Contact page
  style.css         # Global styles + themes
  pages.css         # About / Research / Contact styles
  post.css          # Article page styles
  script.js         # All client-side interactivity
  README.md         # This file
  STATE.md          # Current project state and next steps
```

## Tech Stack

- Pure HTML, CSS, JavaScript (no frameworks, no build step)
- Google Fonts (Inter, JetBrains Mono)
- SVG icons (inline, no icon library dependency)
- CSS custom properties for theming
- CSS Grid + Flexbox for layout
- Intersection Observer API for scroll animations

## Navigation Map

All pages share the same nav bar and footer with consistent links:

```
Nav:    Blog (index) | Research | About | Contact
Footer: Blog | Research | Tutorials | CTF Writeups | Tools | Cheatsheets | About | Contact
```
