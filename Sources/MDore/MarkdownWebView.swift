import SwiftUI
import WebKit
import UniformTypeIdentifiers

struct MarkdownWebView: NSViewRepresentable {
    let markdown: String
    let documentID: UUID
    let baseURL: URL?
    let theme: ReaderTheme
    let palette: ThemePalette
    let textScale: Double
    let pageWidth: Double
    let backgroundImageURL: URL?
    let isEditing: Bool
    let focusMode: Bool
    let typewriterMode: Bool
    let showCodeLineNumbers: Bool
    let command: EditorCommand?
    let searchQuery: String
    let findRevision: Int
    let onChange: (String) -> Void
    let onScroll: () -> Void
    let onOpenLink: (URL) -> Void
    let onDropFiles: ([URL]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "mdoreChanged")
        controller.addUserScript(WKUserScript(source: "window.MathJax={tex:{inlineMath:[['$','$'],['\\\\(','\\\\)']]},svg:{fontCache:'local'},startup:{typeset:false}};", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        if let mathJax = Self.vendorScript(named: "mathjax-tex-svg") {
            controller.addUserScript(WKUserScript(source: mathJax, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }
        if let mermaid = Self.vendorScript(named: "mermaid.min") {
            controller.addUserScript(WKUserScript(source: mermaid, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }
        if let highlight = Self.vendorScript(named: "highlight.min") {
            controller.addUserScript(WKUserScript(source: highlight, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }
        controller.addUserScript(WKUserScript(source: Self.editorScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        let view = ScrollAwareWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.setValue(false, forKey: "drawsBackground")
        view.onScroll = { [weak coordinator = context.coordinator] in coordinator?.onScroll?() }
        return view
    }

    private static func vendorScript(named name: String) -> String? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "js", subdirectory: "Vendor") else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "mdoreChanged")
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onChange = onChange
        coordinator.onScroll = onScroll
        coordinator.onOpenLink = onOpenLink
        coordinator.searchQuery = searchQuery
        coordinator.findRevision = findRevision
        coordinator.isEditing = isEditing
        coordinator.focusMode = focusMode
        coordinator.typewriterMode = typewriterMode
        coordinator.showCodeLineNumbers = showCodeLineNumbers
        (webView as? ScrollAwareWebView)?.onFileDrop = onDropFiles

        let signature = "\(documentID):\(markdown.hashValue):\(theme.rawValue):\(palette.bg):\(palette.accent):\(textScale):\(pageWidth):\(backgroundImageURL?.path ?? "")"
        if coordinator.lastEmittedMarkdown == markdown {
            coordinator.lastEmittedMarkdown = nil
            coordinator.signature = signature
            coordinator.applyMode(in: webView)
        } else if coordinator.signature != signature {
            let html = MarkdownRenderer.render(markdown, theme: theme, textScale: textScale, palette: palette,
                                               pageWidth: pageWidth, backgroundImageURL: backgroundImageURL)
            let isInitialLoad = coordinator.signature.isEmpty
            coordinator.signature = signature
            if isInitialLoad { webView.loadHTMLString(html, baseURL: baseURL) }
            else { coordinator.reloadPreservingPosition(in: webView, html: html, baseURL: baseURL) }
        } else {
            coordinator.applyMode(in: webView)
            if coordinator.lastSearchQuery != searchQuery || coordinator.lastFindRevision != findRevision {
                coordinator.performSearch(in: webView)
            }
        }

        if let command, command.id != coordinator.lastCommandID {
            coordinator.lastCommandID = command.id
            coordinator.perform(command.action, in: webView)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var signature = ""
        var lastEmittedMarkdown: String?
        var lastCommandID: UUID?
        var onChange: ((String) -> Void)?
        var onScroll: (() -> Void)?
        var onOpenLink: ((URL) -> Void)?
        var searchQuery = ""
        var findRevision = 0
        var lastSearchQuery = ""
        var lastFindRevision = 0
        var pendingScrollY: Double?
        var isEditing = false
        var focusMode = false
        var typewriterMode = false
        var showCodeLineNumbers = false
        var appliedModeSignature = ""

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "mdoreChanged", let markdown = message.body as? String else { return }
            lastEmittedMarkdown = markdown
            onChange?(markdown)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let pendingScrollY {
                self.pendingScrollY = nil
                webView.evaluateJavaScript("window.scrollTo(0, \(pendingScrollY));")
            }
            appliedModeSignature = ""
            applyMode(in: webView)
            performSearch(in: webView)
        }

        func applyMode(in webView: WKWebView) {
            let state = "\(isEditing):\(focusMode):\(typewriterMode):\(showCodeLineNumbers)"
            guard state != appliedModeSignature else { return }
            appliedModeSignature = state
            webView.evaluateJavaScript("window.MDore && MDore.setMode(\(isEditing), \(focusMode), \(typewriterMode), \(showCodeLineNumbers));")
        }

        func reloadPreservingPosition(in webView: WKWebView, html: String, baseURL: URL?) {
            webView.evaluateJavaScript("window.scrollY") { [weak self, weak webView] value, _ in
                guard let self, let webView else { return }
                self.pendingScrollY = (value as? NSNumber)?.doubleValue
                webView.loadHTMLString(html, baseURL: baseURL)
            }
        }

        func performSearch(in webView: WKWebView) {
            let backwards = findRevision < lastFindRevision
            lastSearchQuery = searchQuery
            lastFindRevision = findRevision
            guard !searchQuery.isEmpty else { return }
            let configuration = WKFindConfiguration()
            configuration.backwards = backwards
            configuration.wraps = true
            Task { @MainActor in _ = try? await webView.find(searchQuery, configuration: configuration) }
        }

        func perform(_ action: EditorAction, in webView: WKWebView) {
            if action == .exportPDF { exportPDF(from: webView); return }
            if action == .exportHTML { exportHTML(from: webView); return }
            let payload: [String: Any]
            switch action {
            case .paragraph: payload = ["type": "block", "tag": "p"]
            case .heading(let level): payload = ["type": "block", "tag": "h\(level)"]
            case .bold: payload = ["type": "native", "command": "bold"]
            case .italic: payload = ["type": "native", "command": "italic"]
            case .strike: payload = ["type": "native", "command": "strikeThrough"]
            case .inlineCode: payload = ["type": "wrap", "tag": "code"]
            case .highlight: payload = ["type": "wrap", "tag": "mark"]
            case .underline: payload = ["type": "native", "command": "underline"]
            case .superscript: payload = ["type": "native", "command": "superscript"]
            case .subscriptStyle: payload = ["type": "native", "command": "subscript"]
            case .unorderedList: payload = ["type": "native", "command": "insertUnorderedList"]
            case .orderedList: payload = ["type": "native", "command": "insertOrderedList"]
            case .taskList: payload = ["type": "task"]
            case .quote: payload = ["type": "block", "tag": "blockquote"]
            case .codeFence(let language): payload = ["type": "code", "language": language]
            case .table(let rows, let columns): payload = ["type": "table", "rows": rows, "columns": columns]
            case .tableOperation(let operation): payload = ["type": "tableOperation", "operation": operation]
            case .math: payload = ["type": "math"]
            case .diagram: payload = ["type": "diagram"]
            case .divider: payload = ["type": "divider"]
            case .link(let url): payload = ["type": "link", "url": url]
            case .image(let path, let alt): payload = ["type": "image", "path": path, "alt": alt]
            case .imageScale(let percent): payload = ["type": "imageScale", "percent": percent]
            case .jumpToHeading(let title): payload = ["type": "jump", "title": title]
            case .exportPDF, .exportHTML: return
            case .undo: payload = ["type": "native", "command": "undo"]
            case .redo: payload = ["type": "native", "command": "redo"]
            }
            guard let data = try? JSONSerialization.data(withJSONObject: payload),
                  let json = String(data: data, encoding: .utf8) else { return }
            webView.evaluateJavaScript("window.MDore && MDore.command(\(json));")
        }

        private func exportPDF(from webView: WKWebView) {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.pdf]
            panel.nameFieldStringValue = "Document.pdf"
            guard panel.runModal() == .OK, let url = panel.url else { return }
            webView.createPDF(configuration: WKPDFConfiguration()) { result in
                if case .success(let data) = result { try? data.write(to: url) }
            }
        }

        private func exportHTML(from webView: WKWebView) {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.html]
            panel.nameFieldStringValue = "Document.html"
            guard panel.runModal() == .OK, let url = panel.url else { return }
            webView.evaluateJavaScript("document.documentElement.outerHTML") { value, _ in
                if let html = value as? String { try? html.write(to: url, atomically: true, encoding: .utf8) }
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if action.navigationType == .linkActivated, let url = action.request.url, url.fragment != nil {
                decisionHandler(.allow)
            } else if action.navigationType == .linkActivated, let url = action.request.url {
                if !isEditing { onOpenLink?(url) }
                decisionHandler(.cancel)
            } else { decisionHandler(.allow) }
        }
    }

    private static let editorScript = #"""
    (() => {
      const article = document.querySelector('article');
      if (!article) return;
      let emitState = { timer: null };
      let selectedImage = { node: null };
      const htmlEscape = value => String(value || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
      const attrEscape = value => htmlEscape(value).replace(/"/g,'&quot;');
      const text = node => Array.from(node.childNodes).map(inline).join('');
      function inline(node) {
        if (node.nodeType === Node.TEXT_NODE) return node.nodeValue || '';
        if (node.nodeType !== Node.ELEMENT_NODE) return '';
        const tag = node.tagName.toLowerCase();
        if (tag === 'br') return '  \n';
        if (tag === 'strong' || tag === 'b') return `**${text(node)}**`;
        if (tag === 'em' || tag === 'i') return `*${text(node)}*`;
        if (tag === 'del' || tag === 's' || tag === 'strike') return `~~${text(node)}~~`;
        if (tag === 'code') return `\`${node.textContent || ''}\``;
        if (tag === 'mark') return `==${text(node)}==`;
        if (tag === 'u') return `<u>${text(node)}</u>`;
        if (tag === 'sup' && node.classList.contains('footnote-ref')) return `[^${node.querySelector('a')?.getAttribute('href')?.replace('#fn-','') || node.textContent.replace(/[\[\]]/g,'')}]`;
        if (tag === 'sup') return `^${text(node)}^`;
        if (tag === 'sub') return `~${text(node)}~`;
        if (tag === 'a') return `[${text(node)}](${node.getAttribute('href') || ''})`;
        if (tag === 'img') return `![${node.getAttribute('alt') || ''}](${node.getAttribute('src') || ''})${node.dataset.width ? `{width=${node.dataset.width}%}` : ''}`;
        if (tag === 'input' && node.type === 'checkbox') return node.checked ? '[x] ' : '[ ] ';
        if (node.classList.contains('math-inline')) return `$${node.dataset.math || node.textContent || ''}$`;
        return text(node);
      }
      function tableMarkdown(table) {
        if (!table) return '';
        const rows = Array.from(table.rows).map(row => Array.from(row.cells).map(cell => text(cell).trim().replace(/\|/g, '\\|')));
        if (!rows.length) return '';
        const head = rows[0], separator = head.map(() => '---');
        return `| ${head.join(' | ')} |\n| ${separator.join(' | ')} |` + rows.slice(1).map(row => `\n| ${row.join(' | ')} |`).join('');
      }
      function listMarkdown(list, depth = 0) {
        return Array.from(list.children).filter(n => n.tagName === 'LI').map((li, index) => {
          const nested = Array.from(li.children).find(n => n.tagName === 'UL' || n.tagName === 'OL');
          const clone = li.cloneNode(true);
          Array.from(clone.children).filter(n => n.tagName === 'UL' || n.tagName === 'OL').forEach(n => n.remove());
          const checkbox = clone.querySelector('input[type=checkbox]');
          const marker = list.tagName === 'OL' ? `${index + 1}. ` : '- ';
          const own = inline(clone).trim().replace(/^\[[ x]\]\s*/, '');
          const line = `${'  '.repeat(depth)}${marker}${checkbox ? (checkbox.checked ? '[x] ' : '[ ] ') : ''}${own}`;
          return nested ? `${line}\n${listMarkdown(nested, depth + 1)}` : line;
        }).join('\n');
      }
      function block(node) {
        if (node.nodeType === Node.TEXT_NODE) return (node.nodeValue || '').trim();
        if (node.nodeType !== Node.ELEMENT_NODE) return '';
        const tag = node.tagName.toLowerCase();
        if (/^h[1-6]$/.test(tag)) return `${'#'.repeat(Number(tag[1]))} ${text(node).trim()}`;
        if (tag === 'p') return text(node).trim();
        if (tag === 'blockquote') return Array.from(node.children).map(block).join('\n\n').split('\n').map(s => `> ${s}`).join('\n');
        if (tag === 'ul' || tag === 'ol') return listMarkdown(node);
        if (tag === 'hr') return '---';
        if (tag === 'pre') return `\`\`\`${node.dataset.language || ''}\n${node.textContent || ''}\n\`\`\``;
        if (tag === 'table') return tableMarkdown(node);
        if (node.classList.contains('table-wrap')) return tableMarkdown(node.querySelector('table'));
        if (node.classList.contains('code-block')) {
          const pre = node.querySelector('pre');
          const lang = node.dataset.language || node.querySelector('.code-label')?.textContent || '';
          return `\`\`\`${lang.trim()}\n${pre?.textContent || ''}\n\`\`\``;
        }
        if (node.classList.contains('math-block')) return `$$\n${node.querySelector('code')?.textContent || node.dataset.math || ''}\n$$`;
        if (tag === 'details' && node.classList.contains('frontmatter')) return `---\n${node.querySelector('code')?.textContent || ''}\n---`;
        if (tag === 'nav' && node.classList.contains('toc')) return '[TOC]';
        if (tag === 'section' && node.classList.contains('footnotes')) return Array.from(node.querySelectorAll('li')).map(li => `[^${li.id.replace('fn-','')}]: ${text(li).trim()}`).join('\n');
        if (tag === 'img') return inline(node);
        if (tag === 'div') return Array.from(node.childNodes).map(block).filter(Boolean).join('\n\n');
        return text(node).trim();
      }
      function serialize() { return Array.from(article.childNodes).map(block).filter(Boolean).join('\n\n').replace(/\n{3,}/g, '\n\n').trimEnd() + '\n'; }
      function emit() { clearTimeout(emitState.timer); emitState.timer = setTimeout(() => window.webkit.messageHandlers.mdoreChanged.postMessage(serialize()), 160); }
      function currentBlock() {
        const selection = window.getSelection(); let node = selection?.anchorNode;
        if (node?.nodeType === Node.TEXT_NODE) node = node.parentElement;
        while (node && node.parentElement !== article) node = node.parentElement;
        return node;
      }
      function updateFocus() {
        article.querySelectorAll('.mdore-current').forEach(n => n.classList.remove('mdore-current'));
        const current = currentBlock();
        if (current) { current.classList.add('mdore-current'); if (article.classList.contains('typewriter')) current.scrollIntoView({block:'center',behavior:'smooth'}); }
      }
      function insertHTML(html) { article.focus(); document.execCommand('insertHTML', false, html); emit(); }
      async function renderEnhancements(editing, lineNumbers) {
        article.querySelectorAll('.code-block:not(.diagram) pre code').forEach(code => {
          const source = code.textContent || ''; code.textContent = source; code.removeAttribute('data-highlighted');
          if (!editing && window.hljs) { const language = code.closest('.code-block')?.dataset.language; if (language) code.className = `language-${language}`; hljs.highlightElement(code); if (lineNumbers) { code.classList.add('line-numbers'); code.innerHTML = code.innerHTML.split('\n').map(line => `<span class="code-line">${line || ' '}</span>`).join('\n'); } }
        });
        article.querySelectorAll('.math-inline').forEach(span => {
          const source = span.dataset.math || span.textContent || ''; span.textContent = source;
          if (!editing && window.MathJax?.typesetPromise) { span.textContent = `\\(${source}\\)`; MathJax.typesetPromise([span]).catch(() => { span.textContent = source; }); }
        });
        article.querySelectorAll('.math-block').forEach(block => {
          block.classList.remove('rendered'); block.querySelector('.math-preview')?.remove();
          if (!editing && window.MathJax?.typesetPromise) {
            const preview = document.createElement('div'); preview.className = 'math-preview';
            preview.textContent = `\\[${block.dataset.math || block.querySelector('code')?.textContent || ''}\\]`;
            block.appendChild(preview); block.classList.add('rendered');
            MathJax.typesetPromise([preview]).catch(() => block.classList.remove('rendered'));
          }
        });
        article.querySelectorAll('.diagram').forEach(async block => {
          block.classList.remove('rendered'); block.querySelector('.diagram-preview')?.remove();
          if (!editing && window.mermaid) {
            const preview = document.createElement('div'); preview.className = 'diagram-preview mermaid';
            preview.textContent = block.querySelector('pre')?.textContent || '';
            block.appendChild(preview);
            try { mermaid.initialize({startOnLoad:false,theme:getComputedStyle(document.documentElement).colorScheme === 'dark' ? 'dark' : 'neutral',securityLevel:'strict'}); await mermaid.run({nodes:[preview]}); block.classList.add('rendered'); } catch (_) { preview.remove(); }
          }
        });
      }
      window.MDore = {
        setMode(editing, focus, typewriter, lineNumbers) {
          article.contentEditable = editing ? 'true' : 'false'; document.body.classList.toggle('editing', editing);
          article.classList.toggle('focus-mode', editing && focus); article.classList.toggle('typewriter', editing && typewriter); article.spellcheck = true;
          renderEnhancements(editing, lineNumbers);
        },
        command(command) {
          article.focus();
          if (command.type === 'native') document.execCommand(command.command, false, null);
          if (command.type === 'block') document.execCommand('formatBlock', false, command.tag);
          if (command.type === 'wrap') {
            const selection = window.getSelection();
            if (selection && selection.rangeCount) { const element = document.createElement(command.tag); try { selection.getRangeAt(0).surroundContents(element); } catch (_) { document.execCommand('insertHTML', false, `<${command.tag}>${selection}</${command.tag}>`); } }
          }
          if (command.type === 'task') insertHTML('<ul><li><input type="checkbox"> Task</li></ul><p><br></p>');
          if (command.type === 'code') insertHTML(`<div class="code-block" data-language="${attrEscape(command.language || '')}"><span class="code-label">${htmlEscape(command.language || 'code')}</span><pre>${htmlEscape(window.getSelection()?.toString() || 'code')}</pre></div><p><br></p>`);
          if (command.type === 'table') {
            let html = '<div class="table-wrap"><table><thead><tr>';
            for (let c=0;c<command.columns;c++) html += `<th>Column ${c+1}</th>`;
            html += '</tr></thead><tbody>';
            for (let r=1;r<command.rows;r++) { html += '<tr>'; for (let c=0;c<command.columns;c++) html += '<td><br></td>'; html += '</tr>'; }
            insertHTML(html + '</tbody></table></div><p><br></p>');
          }
          if (command.type === 'tableOperation') {
            const cell = currentBlock()?.closest?.('td,th') || window.getSelection()?.anchorNode?.parentElement?.closest?.('td,th');
            const table = cell?.closest('table');
            if (cell && table) {
              const row = cell.parentElement, column = cell.cellIndex;
              if (command.operation === 'addRow') { const added = table.querySelector('tbody').insertRow(row.rowIndex); for (let i=0;i<row.cells.length;i++) added.insertCell().innerHTML = '<br>'; }
              if (command.operation === 'deleteRow' && table.rows.length > 2) row.remove();
              if (command.operation === 'addColumn') Array.from(table.rows).forEach((r,i) => { const added = r.insertCell(column + 1); added.innerHTML = i === 0 ? 'Column' : '<br>'; });
              if (command.operation === 'deleteColumn' && row.cells.length > 1) Array.from(table.rows).forEach(r => r.cells[column]?.remove());
            }
          }
          if (command.type === 'math') insertHTML('<div class="math-block" data-math="E = mc^2"><span class="math-label">LaTeX</span><code>E = mc^2</code></div><p><br></p>');
          if (command.type === 'diagram') insertHTML('<div class="code-block diagram" data-language="mermaid"><span class="code-label">mermaid</span><pre>graph TD\n  A[Start] --> B[Done]</pre></div><p><br></p>');
          if (command.type === 'divider') insertHTML('<hr><p><br></p>');
          if (command.type === 'link') document.execCommand('createLink', false, command.url);
          if (command.type === 'image') insertHTML(`<img src="${attrEscape(command.path)}" alt="${attrEscape(command.alt || '')}"><p><br></p>`);
          if (command.type === 'imageScale' && selectedImage.node) { selectedImage.node.dataset.width = command.percent; selectedImage.node.style.width = `${command.percent}%`; emit(); }
          if (command.type === 'jump') { const heading = Array.from(article.querySelectorAll('h1,h2,h3,h4,h5,h6')).find(node => node.textContent.trim() === command.title); heading?.scrollIntoView({block:'start',behavior:'smooth'}); }
          updateFocus(); emit();
        }
      };
      article.addEventListener('input', emit); article.addEventListener('change', emit);
      article.addEventListener('click', event => {
        article.querySelectorAll('img.mdore-selected').forEach(image => image.classList.remove('mdore-selected'));
        if (event.target.matches('img')) { selectedImage.node = event.target; event.target.classList.add('mdore-selected'); }
        if (event.target.matches('input[type=checkbox]')) { event.target.toggleAttribute('checked', event.target.checked); emit(); }
      });
      article.addEventListener('keydown', event => {
        const current = currentBlock();
        const pairs = {'(':')','[':']','{':'}','"':'"','`':'`'};
        if (!event.metaKey && !event.altKey && !event.ctrlKey && pairs[event.key] && window.getSelection()?.isCollapsed) {
          event.preventDefault(); document.execCommand('insertText', false, event.key + pairs[event.key]); window.getSelection()?.modify('move', 'backward', 'character'); emit(); return;
        }
        if (!event.metaKey && !event.altKey && !event.ctrlKey && [')',']','}'].includes(event.key)) {
          const selection = window.getSelection(), node = selection?.anchorNode, offset = selection?.anchorOffset;
          if (node?.nodeType === Node.TEXT_NODE && node.nodeValue?.[offset] === event.key) { event.preventDefault(); selection.modify('move','forward','character'); return; }
        }
        if (event.key === 'Tab' && current?.tagName === 'LI') { event.preventDefault(); document.execCommand(event.shiftKey ? 'outdent' : 'indent'); emit(); return; }
        if (event.key === ' ' && current?.tagName === 'P') {
          const marker = current.textContent.trim();
          if (/^#{1,6}$/.test(marker)) { event.preventDefault(); current.textContent = ''; document.execCommand('formatBlock', false, `h${marker.length}`); emit(); return; }
          if (marker === '-' || marker === '*') { event.preventDefault(); current.textContent = ''; document.execCommand('insertUnorderedList'); emit(); return; }
          if (marker === '1.') { event.preventDefault(); current.textContent = ''; document.execCommand('insertOrderedList'); emit(); return; }
          if (marker === '>') { event.preventDefault(); current.textContent = ''; document.execCommand('formatBlock', false, 'blockquote'); emit(); return; }
          if (marker === '- [ ]' || marker === '- [x]') { event.preventDefault(); current.outerHTML = `<ul><li><input type="checkbox" ${marker.includes('x') ? 'checked' : ''}> </li></ul>`; emit(); return; }
        }
        if (event.key === 'Enter' && current?.tagName === 'P') {
          const marker = current.textContent.trim();
          if (marker === '---' || marker === '***') { event.preventDefault(); current.outerHTML = '<hr><p><br></p>'; emit(); return; }
          if (/^```[A-Za-z0-9_+.-]*$/.test(marker)) { event.preventDefault(); const language = marker.slice(3); current.outerHTML = `<div class="code-block" data-language="${attrEscape(language)}"><span class="code-label">${htmlEscape(language || 'code')}</span><pre><br></pre></div><p><br></p>`; emit(); return; }
        }
        if (event.key === 'Backspace' && current && /^H[1-6]$/.test(current.tagName) && !current.textContent) document.execCommand('formatBlock', false, 'p');
      });
      document.addEventListener('selectionchange', updateFocus);
    })();
    """#
}

final class ScrollAwareWebView: WKWebView {
    var onScroll: (() -> Void)?
    var onFileDrop: (([URL]) -> Void)?

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        fileURLs(from: sender).isEmpty ? super.draggingEntered(sender) : .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = fileURLs(from: sender)
        guard !urls.isEmpty else { return super.performDragOperation(sender) }
        onFileDrop?(urls)
        return true
    }

    private func fileURLs(from sender: NSDraggingInfo) -> [URL] {
        (sender.draggingPasteboard.readObjects(forClasses: [NSURL.self],
                                              options: [.urlReadingFileURLsOnly: true]) as? [URL]) ?? []
    }

    override func scrollWheel(with event: NSEvent) {
        if abs(event.scrollingDeltaY) > 0.5 { onScroll?() }
        super.scrollWheel(with: event)
    }
}
