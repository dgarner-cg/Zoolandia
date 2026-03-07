// AI Chat Exporter - Content Script

class ChatExporter {
  constructor() {
    this.exportButton = null;
    this.modal = null;
    this.init();
  }

  init() {
    // Wait for page to be fully loaded
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => this.createExportButton());
    } else {
      this.createExportButton();
    }
  }

  createExportButton() {
    // Check if button already exists
    if (document.getElementById('ai-chat-export-btn')) return;

    const button = document.createElement('button');
    button.id = 'ai-chat-export-btn';
    button.className = 'ai-export-floating-btn';
    button.innerHTML = `
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
        <polyline points="7 10 12 15 17 10"></polyline>
        <line x1="12" y1="15" x2="12" y2="3"></line>
      </svg>
      <span>Export</span>
    `;
    button.title = 'Export Chat';
    button.addEventListener('click', () => this.showExportModal());

    document.body.appendChild(button);
    this.exportButton = button;
  }

  showExportModal() {
    if (this.modal) {
      this.modal.style.display = 'flex';
      return;
    }

    const modal = document.createElement('div');
    modal.className = 'ai-export-modal';
    modal.innerHTML = `
      <div class="ai-export-modal-content">
        <div class="ai-export-modal-header">
          <h2>Export Chat</h2>
          <button class="ai-export-close-btn">&times;</button>
        </div>
        <div class="ai-export-modal-body">
          <p>Choose export format:</p>
          <div class="ai-export-format-buttons">
            <button class="ai-export-format-btn" data-format="pdf">
              <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                <polyline points="14 2 14 8 20 8"></polyline>
                <path d="M10 12h4"></path>
                <path d="M10 16h4"></path>
              </svg>
              <span>PDF</span>
            </button>
            <button class="ai-export-format-btn" data-format="html">
              <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="16 18 22 12 16 6"></polyline>
                <polyline points="8 6 2 12 8 18"></polyline>
              </svg>
              <span>HTML</span>
            </button>
            <button class="ai-export-format-btn" data-format="markdown">
              <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M3 7v10h4l3-3 3 3h8V7H3z"></path>
                <path d="M7 10l3 3 3-3"></path>
              </svg>
              <span>Markdown</span>
            </button>
          </div>
          <div class="ai-export-options">
            <label>
              <input type="checkbox" id="ai-export-include-timestamps" checked>
              Include timestamps
            </label>
            <label>
              <input type="checkbox" id="ai-export-syntax-highlighting" checked>
              Syntax highlighting for code
            </label>
            <label>
              <input type="checkbox" id="ai-export-no-page-breaks">
              Remove page breaks (continuous flow)
            </label>
            <label>
              <input type="checkbox" id="ai-export-single-page">
              Single page PDF (one tall page)
            </label>
          </div>
        </div>
      </div>
    `;

    document.body.appendChild(modal);
    this.modal = modal;

    // Event listeners
    modal.querySelector('.ai-export-close-btn').addEventListener('click', () => {
      modal.style.display = 'none';
    });

    modal.addEventListener('click', (e) => {
      if (e.target === modal) {
        modal.style.display = 'none';
      }
    });

    modal.querySelectorAll('.ai-export-format-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const format = btn.dataset.format;
        this.exportChat(format);
      });
    });
  }

  async exportChat(format) {
    const includeTimestamps = document.getElementById('ai-export-include-timestamps').checked;
    const syntaxHighlighting = document.getElementById('ai-export-syntax-highlighting').checked;
    const noPageBreaks = document.getElementById('ai-export-no-page-breaks').checked;
    const singlePage = document.getElementById('ai-export-single-page').checked;

    try {
      // Extract chat messages
      const messages = this.extractMessages();

      if (messages.length === 0) {
        alert('No messages found to export.');
        return;
      }

      // Generate filename
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
      const filename = `chat-export-${timestamp}`;

      // Export based on format
      switch (format) {
        case 'pdf':
          await this.exportToPDF(messages, filename, { includeTimestamps, syntaxHighlighting, noPageBreaks, singlePage });
          break;
        case 'html':
          this.exportToHTML(messages, filename, { includeTimestamps, syntaxHighlighting });
          break;
        case 'markdown':
          this.exportToMarkdown(messages, filename, { includeTimestamps, syntaxHighlighting });
          break;
      }

      // Close modal
      this.modal.style.display = 'none';
    } catch (error) {
      console.error('Export failed:', error);
      alert('Export failed. Please try again.');
    }
  }

  extractMessages() {
    const hostname = window.location.hostname;

    if (hostname.includes('openai.com') || hostname.includes('chatgpt.com')) {
      return this.extractChatGPTMessages();
    } else if (hostname.includes('claude.ai')) {
      return this.extractClaudeMessages();
    } else if (hostname.includes('gemini.google.com')) {
      return this.extractGeminiMessages();
    } else if (hostname.includes('copilot.microsoft.com')) {
      return this.extractCopilotMessages();
    } else if (hostname.includes('perplexity.ai')) {
      return this.extractPerplexityMessages();
    }

    return [];
  }

  extractChatGPTMessages() {
    const messages = [];
    const messageElements = document.querySelectorAll('[data-message-author-role]');

    messageElements.forEach((element, index) => {
      const role = element.getAttribute('data-message-author-role');
      const contentElement = element.querySelector('.markdown, .whitespace-pre-wrap');

      if (contentElement) {
        messages.push({
          role: role === 'user' ? 'user' : 'assistant',
          content: this.cleanContent(contentElement.innerHTML),
          timestamp: new Date()
        });
      }
    });

    return messages;
  }

  extractClaudeMessages() {
    const messages = [];

    // Claude uses different selectors - try multiple approaches
    const messageContainers = document.querySelectorAll('[class*="font-user"], [class*="font-claude"]');

    if (messageContainers.length === 0) {
      // Fallback: look for common message patterns
      const allMessages = document.querySelectorAll('div[class*="message"], div[data-testid*="message"]');

      allMessages.forEach((element) => {
        const isUser = element.className.includes('user') || element.innerHTML.includes('You');
        const contentElement = element.querySelector('div[class*="content"], .markdown, pre, code') || element;

        if (contentElement && contentElement.textContent.trim()) {
          messages.push({
            role: isUser ? 'user' : 'assistant',
            content: this.cleanContent(contentElement.innerHTML),
            timestamp: new Date()
          });
        }
      });
    } else {
      messageContainers.forEach((element) => {
        const isUser = element.className.includes('user');
        messages.push({
          role: isUser ? 'user' : 'assistant',
          content: this.cleanContent(element.innerHTML),
          timestamp: new Date()
        });
      });
    }

    return messages;
  }

  extractGeminiMessages() {
    const messages = [];
    const messageElements = document.querySelectorAll('.conversation-container message-content, [class*="message"]');

    messageElements.forEach((element) => {
      const isUser = element.className.includes('user') || element.closest('[class*="user"]');
      const contentElement = element.querySelector('.markdown, .message-content') || element;

      if (contentElement && contentElement.textContent.trim()) {
        messages.push({
          role: isUser ? 'user' : 'assistant',
          content: this.cleanContent(contentElement.innerHTML),
          timestamp: new Date()
        });
      }
    });

    return messages;
  }

  extractCopilotMessages() {
    const messages = [];
    const messageElements = document.querySelectorAll('[class*="message"], .response-message, .user-message');

    messageElements.forEach((element) => {
      const isUser = element.className.includes('user');
      messages.push({
        role: isUser ? 'user' : 'assistant',
        content: this.cleanContent(element.innerHTML),
        timestamp: new Date()
      });
    });

    return messages;
  }

  extractPerplexityMessages() {
    const messages = [];
    const messageElements = document.querySelectorAll('[class*="Message"], [class*="query"], [class*="answer"]');

    messageElements.forEach((element) => {
      const isUser = element.className.includes('query') || element.className.includes('user');
      messages.push({
        role: isUser ? 'user' : 'assistant',
        content: this.cleanContent(element.innerHTML),
        timestamp: new Date()
      });
    });

    return messages;
  }

  cleanContent(html) {
    // Create a temporary element to manipulate the HTML
    const temp = document.createElement('div');
    temp.innerHTML = html;

    // Remove elements containing "Copy code" text
    const allElements = temp.querySelectorAll('*');
    allElements.forEach(el => {
      const text = el.textContent.trim();
      // If element's direct text is "Copy code" or similar, remove it
      if (text === 'Copy code' || text === 'Copied!' || text === 'Copy') {
        el.remove();
      }
    });

    // Remove ALL buttons
    temp.querySelectorAll('button').forEach(btn => btn.remove());

    // Remove ALL SVGs
    temp.querySelectorAll('svg').forEach(svg => svg.remove());

    // Remove common wrapper divs
    temp.querySelectorAll('[class*="actions"], [class*="toolbar"], [class*="header"], [class*="code-block-header"], [class*="sticky"]').forEach(el => el.remove());

    // Clean up empty divs
    temp.querySelectorAll('div').forEach(div => {
      if (div.textContent.trim() === '' && div.children.length === 0) {
        div.remove();
      }
    });

    return temp.innerHTML;
  }

  async exportToPDF(messages, filename, options) {
    // If single page mode, we need to measure content first
    if (options.singlePage) {
      // Create a temporary hidden iframe to measure content
      const measureFrame = document.createElement('iframe');
      measureFrame.style.position = 'absolute';
      measureFrame.style.left = '-9999px';
      measureFrame.style.width = '8.5in';
      measureFrame.style.visibility = 'hidden';
      document.body.appendChild(measureFrame);

      // Generate HTML with temporary page size for measurement
      const measureHTML = this.generatePDFHTML(messages, { ...options, measuring: true });
      measureFrame.contentDocument.write(measureHTML);
      measureFrame.contentDocument.close();

      // Wait for content to fully render
      await new Promise(resolve => setTimeout(resolve, 500));

      // Measure the actual content height - use multiple methods for accuracy
      const doc = measureFrame.contentDocument;
      const body = doc.body;
      const html = doc.documentElement;

      // Get the maximum height from multiple sources
      const contentHeight = Math.max(
        body.scrollHeight,
        body.offsetHeight,
        html.clientHeight,
        html.scrollHeight,
        html.offsetHeight
      );

      // Convert pixels to inches (96 DPI standard) and add 3 inch buffer for safety
      const contentHeightInches = Math.ceil((contentHeight / 96) + 3);

      // Clean up measurement frame
      document.body.removeChild(measureFrame);

      // Generate final HTML with exact page size
      options.pageHeight = contentHeightInches;
    }

    // Generate HTML content for PDF
    const htmlContent = this.generatePDFHTML(messages, options);

    // Use browser's print functionality to generate PDF
    const printWindow = window.open('', '_blank');
    printWindow.document.write(htmlContent);
    printWindow.document.close();

    // Wait for content to render before printing
    setTimeout(() => {
      printWindow.print();
    }, 800);
  }

  generatePDFHTML(messages, options) {
    const { includeTimestamps, syntaxHighlighting, noPageBreaks, singlePage, pageHeight, measuring } = options;

    // Get page title (conversation title)
    const pageTitle = document.title || 'AI Chat Conversation';

    const messagesHTML = messages.map(msg => `
      <div class="message ${msg.role}">
        <div class="message-header">
          <span class="role-badge">${msg.role === 'user' ? 'You' : 'AI Assistant'}</span>
          ${includeTimestamps ? `<span class="timestamp">${this.formatTimestamp(msg.timestamp)}</span>` : ''}
        </div>
        <div class="message-content">
          ${msg.content}
        </div>
      </div>
    `).join('');

    // Conditional page setup based on page options
    let pageStyle = '';

    if (singlePage) {
      // Create one tall page sized to content (or use default for measuring)
      const height = measuring ? '500in' : `${pageHeight}in`;
      pageStyle = `
    @page {
      size: 8.5in ${height};
      margin: 0.75in;
    }

    html, body {
      height: auto !important;
      overflow: visible !important;
    }

    @media print {
      html, body {
        height: auto !important;
        overflow: visible !important;
      }

      body {
        max-height: none !important;
      }

      /* Force everything onto single page */
      * {
        page-break-before: avoid !important;
        page-break-after: avoid !important;
        page-break-inside: avoid !important;
      }
    }
      `;
    } else if (noPageBreaks) {
      // Remove page breaks but still paginate
      pageStyle = `
    html, body {
      height: auto !important;
      overflow: visible !important;
    }

    @page {
      size: auto;
      margin: 0;
    }

    @media print {
      html, body {
        height: auto !important;
        margin: 0;
        padding: 0;
      }

      body {
        padding: 0.5in !important;
      }
    }
      `;
    } else {
      // Standard paginated PDF
      pageStyle = `
    @page {
      margin: 0.75in;
      size: letter;
    }
      `;
    }

    return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>${pageTitle}</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    ${pageStyle}

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', sans-serif;
      line-height: 1.6;
      color: #e8e8e8;
      background: #1a1a1a;
      padding: 32px;
      max-width: 100%;
      margin: 0;
    }

    h1 {
      font-size: 26px;
      margin-bottom: 24px;
      color: #ffffff;
      border-bottom: 3px solid #6366f1;
      padding-bottom: 8px;
    }

    .message {
      margin-bottom: 20px;
      padding: 18px;
      border-radius: 8px;
      background: #262626;
      border-left: 4px solid #404040;
      word-wrap: break-word;
      overflow-wrap: break-word;
    }

    .message.user {
      background: #1e293b;
      border-left: 4px solid #3b82f6;
    }

    .message.assistant {
      background: #1e3a28;
      border-left: 4px solid #10b981;
    }

    .message-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 10px;
      font-size: 13px;
    }

    .role-badge {
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      font-size: 11px;
    }

    .message.user .role-badge {
      color: #60a5fa;
    }

    .message.assistant .role-badge {
      color: #34d399;
    }

    .timestamp {
      color: #6b7280;
      font-size: 11px;
    }

    .message-content {
      color: #e5e7eb;
      font-size: 14px;
      word-wrap: break-word;
      overflow-wrap: break-word;
      max-width: 100%;
    }

    .message-content p {
      margin-bottom: 12px;
      word-wrap: break-word;
      overflow-wrap: break-word;
    }

    .message-content pre {
      background: #0d1117;
      color: #c9d1d9;
      padding: 14px;
      border-radius: 6px;
      overflow-x: auto;
      margin: 16px 0;
      font-family: 'SF Mono', 'Monaco', 'Inconsolata', 'Fira Code', 'Consolas', monospace;
      font-size: 12px;
      line-height: 1.6;
      border: 1px solid #30363d;
      word-wrap: break-word;
      white-space: pre-wrap;
      max-width: 100%;
      ${(noPageBreaks || singlePage) ? '' : 'page-break-inside: avoid;'}
    }

    .message-content code {
      background: #0d1117;
      color: #79c0ff;
      padding: 3px 6px;
      border-radius: 4px;
      font-family: 'SF Mono', 'Monaco', 'Inconsolata', 'Fira Code', 'Consolas', monospace;
      font-size: 12px;
      border: 1px solid #30363d;
    }

    .message-content pre code {
      background: transparent;
      padding: 0;
      border: none;
      color: #c9d1d9;
    }

    .message-content ul, .message-content ol {
      margin-left: 24px;
      margin: 16px 0;
      margin-left: 24px;
      ${(noPageBreaks || singlePage) ? '' : 'page-break-inside: avoid;'}
    }

    .message-content li {
      margin-bottom: 6px;
      ${(noPageBreaks || singlePage) ? '' : 'page-break-inside: avoid;'}
    }

    .message-content h1, .message-content h2, .message-content h3 {
      margin-top: 20px;
      margin-bottom: 10px;
      color: #f3f4f6;
      ${(noPageBreaks || singlePage) ? '' : 'page-break-after: avoid;'}
    }

    .message-content blockquote {
      border-left: 4px solid #4b5563;
      padding-left: 16px;
      margin: 16px 0;
      color: #9ca3af;
      font-style: italic;
      ${(noPageBreaks || singlePage) ? '' : 'page-break-inside: avoid;'}
    }

    /* Hide any injected export buttons in the exported document */
    .ai-export-floating-btn {
      display: none !important;
    }

    @media print {
      body {
        background: #1a1a1a;
        color: #e8e8e8;
        padding: 0;
        margin: 0;
      }

      .message {
        background: #262626 !important;
        border: 1px solid #404040;
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
        padding: 18px;
        /* Add extra space at top when message is at top of a page */
        padding-top: max(18px, calc(18px + env(safe-area-inset-top, 0px)));
      }

      /* Target messages that appear at the top of a new page */
      .message {
        margin-top: 20px;
      }

      /* First message in body should have normal spacing */
      body > .messages > .message:first-child {
        margin-top: 0;
      }

      .message.user {
        background: #1e293b !important;
        border-left: 4px solid #3b82f6;
      }

      .message.assistant {
        background: #1e3a28 !important;
        border-left: 4px solid #10b981;
      }

      /* Add breathing room for code blocks */
      .message-content pre {
        background: #0d1117 !important;
        border: 1px solid #30363d;
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
        white-space: pre-wrap;
        word-wrap: break-word;
        ${(noPageBreaks || singlePage) ? '' : 'page-break-inside: avoid;'}
        margin-top: 16px;
        margin-bottom: 16px;
      }

      /* Ensure first code block has proper spacing from top */
      .message-content > pre:first-child {
        margin-top: 18px;
      }

      /* Code blocks after paragraphs */
      .message-content > p:first-child + pre {
        margin-top: 16px;
      }

      /* If message starts with code block, add breathing room */
      .message > .message-content > pre:first-child {
        margin-top: 18px;
      }

      .message-content code {
        background: #0d1117 !important;
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
      }

      ${(noPageBreaks || singlePage) ? '' : `
      .message-content h1,
      .message-content h2,
      .message-content h3 {
        page-break-after: avoid;
        margin-top: 20px;
      }

      .message-content ul,
      .message-content ol,
      .message-content li,
      .message-content blockquote {
        page-break-inside: avoid;
      }

      /* Prevent orphans and widows */
      .message-content p {
        orphans: 3;
        widows: 3;
      }

      /* Add spacing after message header to prevent awkward breaks */
      .message-header {
        page-break-after: avoid;
        margin-bottom: 14px;
        margin-top: 12px;
      }
      `}

      .message-content h1,
      .message-content h2,
      .message-content h3 {
        ${(noPageBreaks || singlePage) ? '' : 'margin-top: 20px;'}
      }

      .message-header {
        ${(noPageBreaks || singlePage) ? 'margin-bottom: 14px;' : ''}
        ${(noPageBreaks || singlePage) ? '' : 'margin-top: 12px;'}
      }

      /* Ensure blockquotes and lists have good spacing at page breaks */
      .message-content blockquote,
      .message-content ul,
      .message-content ol {
        margin-top: 16px;
        margin-bottom: 16px;
      }

      h1 {
        color: #ffffff !important;
        border-bottom-color: #6366f1 !important;
      }

      .ai-export-floating-btn {
        display: none !important;
      }
    }
  </style>
</head>
<body>
  <h1>${pageTitle}</h1>
  <div class="messages">
    ${messagesHTML}
  </div>
</body>
</html>
    `;
  }

  exportToHTML(messages, filename, options) {
    const htmlContent = this.generateHTMLWithCopyButtons(messages, options);
    const blob = new Blob([htmlContent], { type: 'text/html' });
    this.downloadFile(blob, `${filename}.html`);
  }

  generateHTMLWithCopyButtons(messages, options) {
    const { includeTimestamps, syntaxHighlighting } = options;

    // Get page title (conversation title)
    const pageTitle = document.title || 'AI Chat Conversation';

    const messagesHTML = messages.map((msg, index) => {
      // Add copy buttons to code blocks
      let content = msg.content;
      const temp = document.createElement('div');
      temp.innerHTML = content;

      // Add copy buttons to each pre block
      const preBlocks = temp.querySelectorAll('pre');
      preBlocks.forEach((pre, preIndex) => {
        const wrapper = document.createElement('div');
        wrapper.className = 'code-block-wrapper';

        const copyBtn = document.createElement('button');
        copyBtn.className = 'copy-code-btn';
        copyBtn.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg> Copy';
        copyBtn.setAttribute('onclick', `navigator.clipboard.writeText(this.parentElement.querySelector('pre').textContent); this.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"></polyline></svg> Copied!'; setTimeout(() => this.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg> Copy', 2000);`);

        pre.parentNode.insertBefore(wrapper, pre);
        wrapper.appendChild(copyBtn);
        wrapper.appendChild(pre);
      });

      content = temp.innerHTML;

      return `
      <div class="message ${msg.role}">
        <div class="message-header">
          <span class="role-badge">${msg.role === 'user' ? 'You' : 'AI Assistant'}</span>
          ${includeTimestamps ? `<span class="timestamp">${this.formatTimestamp(msg.timestamp)}</span>` : ''}
        </div>
        <div class="message-content">
          ${content}
        </div>
      </div>
    `;
    }).join('');

    return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>${pageTitle}</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', sans-serif;
      line-height: 1.6;
      color: #e8e8e8;
      background: #1a1a1a;
      padding: 32px;
      max-width: 1200px;
      margin: 0 auto;
    }

    h1 {
      font-size: 26px;
      margin-bottom: 24px;
      color: #ffffff;
      border-bottom: 3px solid #6366f1;
      padding-bottom: 8px;
    }

    .message {
      margin-bottom: 20px;
      padding: 18px;
      border-radius: 8px;
      background: #262626;
      border-left: 4px solid #404040;
      word-wrap: break-word;
      overflow-wrap: break-word;
    }

    .message.user {
      background: #1e293b;
      border-left: 4px solid #3b82f6;
    }

    .message.assistant {
      background: #1e3a28;
      border-left: 4px solid #10b981;
    }

    .message-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 10px;
      font-size: 13px;
    }

    .role-badge {
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      font-size: 11px;
    }

    .message.user .role-badge {
      color: #60a5fa;
    }

    .message.assistant .role-badge {
      color: #34d399;
    }

    .timestamp {
      color: #6b7280;
      font-size: 11px;
    }

    .message-content {
      color: #e5e7eb;
      font-size: 14px;
      word-wrap: break-word;
      overflow-wrap: break-word;
      max-width: 100%;
    }

    .message-content p {
      margin-bottom: 12px;
      word-wrap: break-word;
      overflow-wrap: break-word;
    }

    .code-block-wrapper {
      position: relative;
      margin: 12px 0;
    }

    .copy-code-btn {
      position: absolute;
      top: 8px;
      right: 8px;
      background: #374151;
      color: #9ca3af;
      border: 1px solid #4b5563;
      border-radius: 4px;
      padding: 6px 10px;
      font-size: 12px;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 6px;
      transition: all 0.2s;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
      z-index: 10;
    }

    .copy-code-btn:hover {
      background: #4b5563;
      color: #e5e7eb;
    }

    .copy-code-btn svg {
      width: 14px;
      height: 14px;
    }

    .message-content pre {
      background: #0d1117;
      color: #c9d1d9;
      padding: 14px;
      padding-top: 40px;
      border-radius: 6px;
      overflow-x: auto;
      font-family: 'SF Mono', 'Monaco', 'Inconsolata', 'Fira Code', 'Consolas', monospace;
      font-size: 12px;
      line-height: 1.6;
      border: 1px solid #30363d;
      word-wrap: break-word;
      white-space: pre-wrap;
      max-width: 100%;
    }

    .message-content code {
      background: #0d1117;
      color: #79c0ff;
      padding: 3px 6px;
      border-radius: 4px;
      font-family: 'SF Mono', 'Monaco', 'Inconsolata', 'Fira Code', 'Consolas', monospace;
      font-size: 12px;
      border: 1px solid #30363d;
    }

    .message-content pre code {
      background: transparent;
      padding: 0;
      border: none;
      color: #c9d1d9;
    }

    .message-content ul, .message-content ol {
      margin-left: 24px;
      margin-bottom: 12px;
    }

    .message-content li {
      margin-bottom: 6px;
    }

    .message-content h1, .message-content h2, .message-content h3 {
      margin-top: 18px;
      margin-bottom: 10px;
      color: #f3f4f6;
    }

    .message-content blockquote {
      border-left: 4px solid #4b5563;
      padding-left: 16px;
      margin: 12px 0;
      color: #9ca3af;
      font-style: italic;
    }

    /* Hide any injected export buttons in the exported document */
    .ai-export-floating-btn,
    .ai-export-modal {
      display: none !important;
    }
  </style>
</head>
<body>
  <h1>${pageTitle}</h1>
  <div class="messages">
    ${messagesHTML}
  </div>
</body>
</html>
    `;
  }

  exportToMarkdown(messages, filename, options) {
    const { includeTimestamps } = options;

    // Get page title (conversation title)
    const pageTitle = document.title || 'AI Chat Conversation';

    let markdown = `# ${pageTitle}\n\n`;

    messages.forEach((msg, index) => {
      const role = msg.role === 'user' ? '**You**' : '**AI Assistant**';
      const timestamp = includeTimestamps ? ` _(${this.formatTimestamp(msg.timestamp)})_` : '';

      markdown += `### ${role}${timestamp}\n\n`;

      // Convert HTML to markdown-like text
      const tempDiv = document.createElement('div');
      tempDiv.innerHTML = msg.content;

      // Extract text and preserve code blocks
      let content = this.htmlToMarkdown(tempDiv);
      markdown += content + '\n\n';
      markdown += `---\n\n`;
    });

    const blob = new Blob([markdown], { type: 'text/markdown' });
    this.downloadFile(blob, `${filename}.md`);
  }

  htmlToMarkdown(element) {
    let markdown = '';

    element.childNodes.forEach(node => {
      if (node.nodeType === Node.TEXT_NODE) {
        markdown += node.textContent;
      } else if (node.nodeType === Node.ELEMENT_NODE) {
        const tag = node.tagName.toLowerCase();

        switch (tag) {
          case 'pre':
            const code = node.querySelector('code');
            const language = code ? this.detectLanguage(code) : '';
            const codeText = code ? code.textContent : node.textContent;
            markdown += `\n\`\`\`${language}\n${codeText}\n\`\`\`\n`;
            break;
          case 'code':
            if (!node.closest('pre')) {
              markdown += `\`${node.textContent}\``;
            }
            break;
          case 'p':
            markdown += this.htmlToMarkdown(node) + '\n\n';
            break;
          case 'h1':
            markdown += `# ${node.textContent}\n\n`;
            break;
          case 'h2':
            markdown += `## ${node.textContent}\n\n`;
            break;
          case 'h3':
            markdown += `### ${node.textContent}\n\n`;
            break;
          case 'ul':
          case 'ol':
            markdown += this.listToMarkdown(node, tag === 'ol') + '\n';
            break;
          case 'li':
            // Handled by listToMarkdown
            break;
          case 'blockquote':
            const lines = node.textContent.split('\n');
            markdown += lines.map(line => `> ${line}`).join('\n') + '\n\n';
            break;
          case 'strong':
          case 'b':
            markdown += `**${node.textContent}**`;
            break;
          case 'em':
          case 'i':
            markdown += `*${node.textContent}*`;
            break;
          case 'br':
            markdown += '\n';
            break;
          default:
            markdown += this.htmlToMarkdown(node);
        }
      }
    });

    return markdown;
  }

  listToMarkdown(listElement, ordered = false) {
    let markdown = '';
    const items = listElement.querySelectorAll(':scope > li');

    items.forEach((item, index) => {
      const prefix = ordered ? `${index + 1}. ` : '- ';
      markdown += prefix + this.htmlToMarkdown(item).trim() + '\n';
    });

    return markdown;
  }

  detectLanguage(codeElement) {
    const classList = Array.from(codeElement.classList);
    for (const className of classList) {
      if (className.startsWith('language-')) {
        return className.replace('language-', '');
      }
    }
    return '';
  }

  formatTimestamp(date) {
    return date.toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  downloadFile(blob, filename) {
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }
}

// Initialize the exporter
const exporter = new ChatExporter();
