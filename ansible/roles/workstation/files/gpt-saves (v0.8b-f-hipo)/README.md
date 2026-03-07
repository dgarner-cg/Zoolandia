# AI Chat Exporter

A professional Chrome extension that allows you to export conversations from AI chat platforms (ChatGPT, Claude, Gemini, Copilot, and Perplexity) to PDF, HTML, and Markdown formats with beautiful formatting and code block preservation.

## Features

- **Universal Compatibility**: Works with ChatGPT, Claude, Gemini, Microsoft Copilot, and Perplexity AI
- **Multiple Export Formats**:
  - **PDF**: Professional, print-ready documents with beautiful styling
  - **HTML**: Standalone HTML files with embedded styling
  - **Markdown**: Clean, portable markdown files
- **Code Block Preservation**: Maintains syntax highlighting and formatting for code snippets
- **Customizable Options**:
  - Include/exclude timestamps
  - Toggle syntax highlighting
- **Beautiful UI**: Sleek, modern floating export button and modal interface
- **Non-Intrusive**: Minimal design that doesn't interfere with your chat experience

## Installation

### Method 1: Load as Unpacked Extension (Development)

1. **Download or Clone** this repository to your local machine

2. **Generate Icons** (if not already present):
   - Open `create-icons.html` in your browser
   - Click "Generate Icons"
   - Move the downloaded `icon16.png`, `icon48.png`, and `icon128.png` files to the `icons/` folder

3. **Open Chrome Extensions Page**:
   - Navigate to `chrome://extensions/`
   - Or click Menu (⋮) → Extensions → Manage Extensions

4. **Enable Developer Mode**:
   - Toggle the "Developer mode" switch in the top-right corner

5. **Load the Extension**:
   - Click "Load unpacked"
   - Select the `gpt-saves` folder containing the extension files

6. **Verify Installation**:
   - The extension should now appear in your extensions list
   - Visit any supported AI chat platform to see the export button

### Method 2: Chrome Web Store (Coming Soon)

The extension will be available on the Chrome Web Store for easy one-click installation.

## Usage

1. **Navigate** to any supported AI chat platform:
   - ChatGPT (chat.openai.com or chatgpt.com)
   - Claude (claude.ai)
   - Google Gemini (gemini.google.com)
   - Microsoft Copilot (copilot.microsoft.com)
   - Perplexity AI (perplexity.ai)

2. **Look for the Export Button**:
   - A floating purple "Export" button appears in the bottom-right corner

3. **Click Export**:
   - Choose your desired format (PDF, HTML, or Markdown)
   - Configure options (timestamps, syntax highlighting)
   - Click the format button to download

4. **Access Your Export**:
   - For PDF: The print dialog will open (use "Save as PDF" as the destination)
   - For HTML/Markdown: The file downloads automatically

## Export Format Details

### PDF Export
- Professional typography with beautiful gradient header
- Color-coded message blocks (blue for user, green for AI)
- Properly formatted code blocks with dark theme
- Optimized for printing and sharing
- Preserves all formatting and structure

### HTML Export
- Standalone file with embedded CSS
- Fully styled and ready to view in any browser
- Maintains all visual formatting from the PDF version
- Easy to share and archive

### Markdown Export
- Clean, readable markdown format
- Preserves code blocks with language tags
- Compatible with all markdown editors
- Great for documentation and note-taking
- Easy to convert to other formats

## Supported Platforms

- ✅ ChatGPT (OpenAI)
- ✅ Claude (Anthropic)
- ✅ Google Gemini
- ✅ Microsoft Copilot
- ✅ Perplexity AI

## File Structure

```
gpt-saves/
├── manifest.json          # Extension configuration
├── content.js            # Main content script with export logic
├── styles.css            # Styling for UI elements
├── create-icons.html     # Icon generator utility
├── icons/
│   ├── icon.svg         # Source SVG icon
│   ├── icon16.png       # 16x16 icon
│   ├── icon48.png       # 48x48 icon
│   └── icon128.png      # 128x128 icon
└── README.md            # This file
```

## How It Works

The extension uses content scripts to:

1. **Detect AI Chat Platforms**: Identifies the current platform based on URL
2. **Inject Export Button**: Adds a floating button to the page
3. **Extract Messages**: Platform-specific selectors extract conversation data
4. **Generate Exports**: Converts messages to the selected format
5. **Download Files**: Provides the exported file to the user

## Code Highlights

### Professional PDF Styling
- Gradient headers with beautiful color schemes
- Typography optimized for readability
- Code blocks with dark theme syntax highlighting
- Proper spacing and visual hierarchy

### Smart Message Extraction
- Platform-specific selectors for accurate extraction
- Handles various HTML structures across platforms
- Preserves formatting, code blocks, and lists
- Falls back gracefully when structure changes

## Troubleshooting

### Export Button Not Appearing
- Ensure you're on a supported platform URL
- Try refreshing the page
- Check that the extension is enabled in `chrome://extensions/`

### Messages Not Exporting Correctly
- The platform may have updated their HTML structure
- Open a GitHub issue with details about the platform and any error messages

### Icons Not Showing
- Run the `create-icons.html` file to generate PNG icons
- Ensure icons are in the `icons/` folder

## Privacy & Security

- **No Data Collection**: This extension does not collect, store, or transmit any user data
- **Local Processing**: All exports are generated locally in your browser
- **No External Requests**: No data is sent to external servers
- **Open Source**: All code is available for review

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on multiple platforms
5. Submit a pull request

### Areas for Contribution
- Support for additional AI chat platforms
- Enhanced export formats
- Improved message extraction
- UI/UX improvements
- Bug fixes

## License

MIT License - feel free to use, modify, and distribute as needed.

## Future Enhancements

- [ ] Support for more AI platforms
- [ ] JSON export format
- [ ] Batch export of multiple conversations
- [ ] Cloud sync integration
- [ ] Custom styling themes
- [ ] Export filtering (date ranges, message types)
- [ ] PDF with table of contents for long chats
- [ ] Syntax highlighting theme options

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check existing issues for solutions

---

Made with care for the AI community. Export your valuable conversations beautifully!
