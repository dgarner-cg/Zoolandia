# Changelog

All notable changes to the AI Chat Exporter extension will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.2.2] - 2025-10-11

### Fixed
- **Significantly improved single-page PDF measurement accuracy**
  - Now measures content height using multiple methods (scrollHeight, offsetHeight, clientHeight) and takes the maximum
  - Increased buffer from 2 inches to 3 inches for safety margin
  - Added forced page-break prevention for all elements in single-page mode using `!important` rules
  - Increased measurement wait time from 300ms to 500ms for better rendering
  - Increased print wait time from 500ms to 800ms to ensure content is fully loaded
  - Fixed issue where content would overflow onto a second blank page
  - Fixed issue where last portion of content would be cut off and moved to page 2

### Technical Details
- Content height now calculated as: `Math.max(body.scrollHeight, body.offsetHeight, html.clientHeight, html.scrollHeight, html.offsetHeight)`
- Added `* { page-break-before: avoid !important; page-break-after: avoid !important; page-break-inside: avoid !important; }` for single-page mode
- Made iframe visibility hidden instead of just positioning off-screen
- Height calculation: `Math.ceil((contentHeight / 96) + 3)` (was +2, now +3 inches)

---

## [1.2.1] - 2025-10-11

### Improved
- **Dynamic page sizing for single page PDFs**
  - Page height is now automatically calculated based on actual content length
  - No more massive 500-inch canvas for short conversations
  - Uses hidden iframe to measure content before generating final PDF
  - Adds 2-inch buffer to measured height for safety
  - Page size perfectly fits content (e.g., 15-inch page for 15 inches of content)

### Technical Details
- Added content measurement step before PDF generation in single page mode
- Creates temporary hidden iframe (positioned at -9999px) to render and measure content
- Calculates height using: `Math.ceil((scrollHeight / 96) + 2)` (96 DPI + 2" buffer)
- Passes `measuring: true` flag for initial render, then `pageHeight` for final render
- Clean up of measurement frame after calculation

### Fixed
- Single page PDFs no longer show unnecessarily large canvas/artboard
- Page size dynamically adapts to conversation length

---

## [1.2.0] - 2025-10-11

### Added
- **Single page PDF (one tall page)** export option
  - New checkbox: "Single page PDF (one tall page)"
  - Creates a truly continuous single-page PDF (8.5in x 500in)
  - Print dialog shows exactly ONE page
  - Perfect for archiving entire conversations as a single scrollable document
  - No page breaks whatsoever in the print preview

### Changed
- **Renamed "One page PDF (continuous)" to "Remove page breaks (continuous flow)"**
  - Better describes what the option actually does
  - Removes page-break rules but still allows browser pagination
  - Background colors extend to page edges
  - More accurate naming for user expectations

### Improved
- Both new page options (`noPageBreaks` and `singlePage`) now properly disable all page-break CSS rules
- Cleaner conditional logic for page styling options
- Users can now choose between three modes:
  1. **Standard paginated** (default): Intelligent page breaks, letter-sized pages
  2. **Remove page breaks**: Continuous flow with background to edges, browser handles pagination
  3. **Single page PDF**: One extremely tall page containing entire conversation

### Technical Details
- Page size for single page mode: `8.5in x 500in` (can handle very long conversations)
- Updated all conditional CSS to check both `noPageBreaks` and `singlePage` flags
- Refactored `pageStyle` generation to use if-else logic for three distinct modes
- Variable name changes: `onePage` → `noPageBreaks` and added `singlePage`

---

## [1.1.0] - 2025-10-11

### Added
- **One Page PDF (continuous)** export option
  - New checkbox in export modal: "One page PDF (continuous)"
  - Creates truly continuous PDF without page breaks when enabled
  - Ideal for long conversations that benefit from scrolling rather than pagination
  - All page-break rules are conditionally removed when this option is active

### Changed
- Improved PDF page break handling
  - When "One Page PDF" is disabled, maintains intelligent page breaks
  - Prevents awkward splits in code blocks, lists, headers, and blockquotes
  - Better orphan/widow control for text flow across pages

### Technical Details
- Added `onePage` parameter throughout export chain
- Conditional CSS generation based on user's one-page selection
- Modified `@page` rules to use `size: auto` with zero margins for continuous layout
- All page-break CSS rules now wrapped in conditional logic:
  - `page-break-inside: avoid` for pre, ul, ol, li, blockquote elements
  - `page-break-after: avoid` for h1, h2, h3, and message-header elements
  - Orphan/widow controls for paragraphs
- Print media query adjustments for continuous page mode

---

## [1.0.0] - 2025-10-10

### Added
- Initial release of AI Chat Exporter
- **Multi-platform support**: ChatGPT, Claude, Gemini, Microsoft Copilot, Perplexity AI
- **Three export formats**: PDF, HTML, and Markdown
- Beautiful dark theme for all exports
- Professional gradient header design
- Color-coded message blocks (blue for user, green for AI)

### Features
- **Export Options**:
  - Include/exclude timestamps
  - Toggle syntax highlighting for code blocks
- **PDF Export**:
  - Professional typography with dark theme (#1a1a1a background, #e8e8e8 text)
  - Code blocks with dark GitHub-style syntax highlighting (#0d1117 background)
  - Intelligent page breaks to avoid awkward content splits
  - Proper margins (0.75in) to keep content within print boundaries
  - Word wrapping and overflow handling for long code lines
  - Proper spacing at page tops (12px margin on message headers)
  - First code blocks get 18px top margin for breathing room
- **HTML Export**:
  - Standalone files with embedded CSS styling
  - Functional "Copy" buttons for each code block
  - JavaScript-powered clipboard functionality
  - Same visual styling as PDF exports
- **Markdown Export**:
  - Clean, portable markdown format
  - Preserves code blocks with language tags
  - Compatible with all markdown editors
  - Converts HTML structure to markdown syntax

### UI/UX
- Floating purple gradient export button (bottom-right corner)
- Non-intrusive design that doesn't interfere with chat experience
- Modal dialog for export format selection and options
- Beautiful animations (fade-in for modal, slide-up for content)
- Responsive design for mobile and desktop

### Code Quality
- Clean content extraction removes UI artifacts:
  - Removes "Copy code" buttons from PDF/Markdown exports
  - Strips all buttons, SVGs, and toolbar elements
  - Cleans empty wrapper divs
- Platform-specific message extraction with fallback selectors
- Proper error handling and user feedback

### Bug Fixes
- Fixed text running off page edges with proper word-wrap and white-space: pre-wrap
- Fixed "Copy code" buttons appearing in PDF exports
- Fixed awkward page breaks splitting conversations mid-message
- Fixed lack of spacing at page tops by adding margin-top to message headers
- Fixed code blocks touching top of message containers
- Removed export button from appearing in exported documents

---

## Version History Summary

- **v1.2.2** - Fixed single-page PDF measurement issues (content overflow, blank pages, cut-off text)
- **v1.2.1** - Dynamic page sizing for single-page PDFs (no more huge canvas!)
- **v1.2.0** - Added true single-page PDF option, renamed continuous flow option for clarity
- **v1.1.0** - Added continuous flow PDF feature with improved page break handling
- **v1.0.0** - Initial release with PDF, HTML, Markdown export for 5 major AI platforms
