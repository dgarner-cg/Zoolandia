# Project State

**Last updated:** January 27, 2026

## Current Status: MVP Complete

A static multi-page website for hack3r.gg is fully built and functional. All pages are styled, themed, responsive, and interlinked.

## What's Done

- [x] Blog homepage with featured post, 6 post cards, category filters, newsletter signup
- [x] Article detail page with TOC sidebar, code blocks, callout boxes, author bio, related posts
- [x] Research page with focus areas, featured research card, chronological paper list, responsible disclosure section
- [x] About page with mission, values grid, stats, team bios (4 members), company timeline (2022-2026), CTA
- [x] Contact page with form (name, email, subject select, message, PGP checkbox), contact info sidebar, PGP key card, FAQ (6 items)
- [x] Light/dark theme toggle with system preference detection and localStorage persistence
- [x] Search modal with Ctrl/Cmd+K shortcut and client-side filtering
- [x] Category filtering on blog homepage
- [x] Mobile responsive layout across all breakpoints
- [x] Mobile hamburger menu
- [x] Scroll-aware navbar (hides on scroll down)
- [x] Fade-in animations via Intersection Observer
- [x] Cross-page navigation (all nav bars and footers link correctly)

## What's Not Built Yet

These are placeholder or missing features that would be needed for a production site:

### Content & Backend
- [ ] Real blog posts (current posts are sample/placeholder content)
- [ ] CMS or markdown-based content pipeline
- [ ] Server-side rendering or static site generator (currently pure static HTML)
- [ ] Newsletter form backend (currently client-side only with console log)
- [ ] Contact form backend (currently client-side only with simulated success)
- [ ] Search backed by real index (currently searches a hardcoded JS array)

### Pages & Sections
- [ ] Tools page (linked in footer but not created)
- [ ] Cheatsheets page
- [ ] Wordlists page
- [ ] Labs page
- [ ] Individual author profile pages
- [ ] Tag/category archive pages
- [ ] Pagination for blog listing

### Features
- [ ] RSS feed
- [ ] Syntax highlighting for code blocks (e.g., Prism.js or Highlight.js)
- [ ] Reading progress bar on article page (CSS exists in post.css but no JS)
- [ ] Table of contents active-state tracking on scroll
- [ ] Social share links with actual URLs
- [ ] Image assets (currently using SVG placeholders)
- [ ] Favicon and Open Graph meta tags
- [ ] SEO meta tags per page
- [ ] Analytics integration
- [ ] Cookie consent banner

### Infrastructure
- [ ] Domain setup (hack3r.gg)
- [ ] Hosting (Vercel, Netlify, Cloudflare Pages, etc.)
- [ ] SSL certificate
- [ ] Git repository initialization
- [ ] CI/CD pipeline

## Sample Content

The site includes placeholder content for demonstration:

**Blog posts** (index.html):
1. Supply Chain Attacks in Modern CI/CD Pipelines (featured, full article in post.html)
2. Memory Safety: Buffer Overflow Prevention in Rust
3. Setting Up a Secure Home Lab for Penetration Testing
4. NIST Guidelines for Post-Quantum Cryptography
5. Binary Exploitation Challenge from DefCon CTF Quals
6. API Security: GraphQL Introspection Attacks
7. OAuth 2.0 Misconfigurations

**Research papers** (research.html):
1. Supply Chain Attacks in CI/CD Pipelines - Jan 2026
2. GraphQL Introspection Attacks Taxonomy - Jan 2026
3. Post-Quantum Key Encapsulation Pitfalls - Dec 2025
4. Container Escape via eBPF in Kubernetes - Nov 2025
5. OAuth 2.0 State Machine Vulnerabilities - Oct 2025
6. Typosquatting Detection on PyPI - Sep 2025
7. AWS IAM Privilege Escalation: 12 New Paths - Aug 2025

**Team** (about.html):
- Alex Hayes - Founder & Lead Researcher
- Sarah Kim - Security Researcher
- Marcus Rivera - Threat Intelligence Lead
- Jenna Park - Content & Community Lead

## Key Design Decisions

1. **No build step** - Pure HTML/CSS/JS for simplicity. Migrate to a framework (Next.js, Astro, Hugo) when content volume justifies it.
2. **No icon library** - Inline SVGs to avoid external dependencies.
3. **CSS custom properties for theming** - Single source of truth for light/dark modes.
4. **Sticky category bar** - Stays below navbar for quick filtering without scrolling back up.
5. **JetBrains Mono for branding** - Monospace font reinforces the technical/hacker identity.
6. **Green accent (#10a37f)** - Bridges the OpenAI-inspired clean aesthetic with a "terminal green" security vibe.
