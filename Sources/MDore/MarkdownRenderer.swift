import Foundation

enum MarkdownRenderer {
    static func render(_ markdown: String, theme: ReaderTheme, textScale: Double,
                       palette customPalette: ThemePalette? = nil, pageWidth: Double = 720,
                       backgroundImageURL: URL? = nil) -> String {
        let body = blocks(markdown.replacingOccurrences(of: "\r\n", with: "\n"))
        let palette = customPalette ?? theme.palette
        let darkMode = isDark(palette.bg)
        let size = String(format: "%.2f", 17 * textScale)
        let width = String(format: "%.0f", pageWidth)
        let background = backgroundImageURL.map { "url('\($0.absoluteString.replacingOccurrences(of: "'", with: "%27"))')" } ?? "none"
        return """
        <!doctype html><html><head><meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        :root{color-scheme:\(darkMode ? "dark" : "light")}
        *{box-sizing:border-box}html,body{margin:0;min-height:100%;background:\(palette.bg);color:\(palette.text)}
        body{font-family:-apple-system,BlinkMacSystemFont,"SF Pro Text",system-ui,sans-serif;font-size:\(size)px;line-height:1.74;letter-spacing:-.008em;padding:96px 34px 20vh;overflow-wrap:break-word;background-image:linear-gradient(color-mix(in srgb,\(palette.bg) 88%,transparent),color-mix(in srgb,\(palette.bg) 88%,transparent)),\(background);background-size:cover;background-position:center;background-attachment:fixed}
        article{max-width:\(width)px;margin:0 auto;animation:arrive .22s ease-out both;outline:none}
        @keyframes arrive{from{opacity:0;transform:translateY(5px)}to{opacity:1;transform:none}}
        h1,h2,h3,h4,h5,h6{font-family:"New York",ui-serif,Georgia,serif;line-height:1.16;letter-spacing:-.032em;margin:2.25em 0 .7em}
        h1{font-size:2.48em;margin-top:.3em}h2{font-size:1.72em;border-bottom:1px solid \(palette.line);padding-bottom:.38em}h3{font-size:1.3em}h4{font-size:1.09em}h5,h6{font-size:1em}
        p{margin:0 0 1.25em}a{color:\(palette.accent);text-decoration-thickness:1px;text-underline-offset:3px}a:hover{text-decoration-thickness:2px}
        strong{font-weight:650}hr{border:0;border-top:1px solid \(palette.line);margin:2.6em 0}
        mark{background:color-mix(in srgb,\(palette.accent) 24%,transparent);color:inherit;padding:.04em .16em;border-radius:3px}
        blockquote{margin:1.6em 0;padding:.05em 0 .05em 1.15em;border-left:3px solid \(palette.accent);color:\(palette.muted)}blockquote>:last-child{margin-bottom:0}
        .toc{display:flex;flex-direction:column;gap:.35em;margin:1.4em 0 2em;padding-left:1em;border-left:1px solid \(palette.line)}.toc a{text-decoration:none;font-size:.9em}.toc-level-2{padding-left:1em}.toc-level-3,.toc-level-4,.toc-level-5,.toc-level-6{padding-left:2em;color:\(palette.muted)}
        .footnotes{margin-top:3em;color:\(palette.muted);font-size:.84em}.footnotes ol{padding-left:1.3em}.footnote-ref{font-size:.7em;vertical-align:super}.footnote-ref a{text-decoration:none}
        ul,ol{padding-left:1.45em;margin:0 0 1.3em}li{padding-left:.2em;margin:.28em 0}li::marker{color:\(palette.muted)}
        code{font-family:"SFMono-Regular",ui-monospace,monospace;font-size:.84em;background:\(palette.code);padding:.14em .35em;border-radius:5px}
        .code-block{position:relative;margin:1.5em 0}.code-block pre{margin:0}.code-label{position:absolute;top:.65em;right:.8em;color:\(palette.muted);font:600 .66em -apple-system,system-ui,sans-serif;letter-spacing:.04em;text-transform:uppercase}
        pre{overflow:auto;background:\(palette.code);border:1px solid \(palette.line);padding:1.15em 1.2em;border-radius:11px;line-height:1.55}pre code{padding:0;background:none;white-space:pre;overflow-wrap:normal}
        .hljs-keyword,.hljs-selector-tag,.hljs-literal{color:\(palette.accent)}.hljs-string,.hljs-title,.hljs-section{color:color-mix(in srgb,\(palette.accent) 76%,\(palette.text))}.hljs-comment,.hljs-quote{color:\(palette.muted);font-style:italic}.hljs-number,.hljs-symbol,.hljs-bullet{color:color-mix(in srgb,\(palette.accent) 62%,#B06A8F)}.hljs-built_in,.hljs-type,.hljs-params{color:color-mix(in srgb,\(palette.text) 74%,\(palette.accent))}
        code.line-numbers{counter-reset:line}.code-line{display:inline-block;min-width:100%;counter-increment:line}.code-line:before{content:counter(line);display:inline-block;width:2.6em;margin-right:1em;text-align:right;color:\(palette.muted);opacity:.55;user-select:none}
        .table-wrap{width:min(920px,calc(100vw - 48px));margin:1.8em 50% 2.1em;transform:translateX(-50%);overflow:auto;border:1px solid \(palette.line);border-radius:12px;background:\(palette.bg);box-shadow:0 1px 0 rgba(0,0,0,.025)}
        table{border-collapse:separate;border-spacing:0;width:100%;min-width:max-content;font-size:.9em;line-height:1.5;font-variant-numeric:tabular-nums}
        th,td{min-width:8.5em;max-width:28em;padding:.76em .9em;border-right:1px solid \(palette.line);border-bottom:1px solid \(palette.line);vertical-align:top}
        th:last-child,td:last-child{border-right:0}tbody tr:last-child td{border-bottom:0}
        th{font-weight:650;background:\(palette.code);white-space:nowrap}tbody tr:nth-child(even) td{background:color-mix(in srgb,\(palette.code) 42%,transparent)}tbody tr:hover td{background:color-mix(in srgb,\(palette.accent) 8%,transparent)}
        td code{white-space:nowrap}.table-wrap::-webkit-scrollbar{height:9px}.table-wrap::-webkit-scrollbar-thumb{background:\(palette.line);border:2px solid \(palette.bg);border-radius:9px}
        img{display:block;max-width:100%;height:auto;border-radius:9px;margin:1.8em auto}body.editing img.mdore-selected{outline:2px solid \(palette.accent);outline-offset:4px}del{color:\(palette.muted)}
        .math-block{position:relative;margin:1.5em 0;padding:1.35em 1.2em;border:1px solid \(palette.line);border-radius:11px;background:\(palette.code);text-align:center}.math-block code{font-size:1em;background:none}.math-label{position:absolute;top:.55em;right:.75em;color:\(palette.muted);font-size:.62em;font-weight:650;letter-spacing:.06em;text-transform:uppercase}.math-inline{font-family:"New York",ui-serif,serif;font-style:italic;color:\(palette.accent)}
        .math-preview{overflow:auto;padding:.35em}.diagram-preview{padding:1.15em;overflow:auto;text-align:center}.diagram-preview svg{max-width:100%;height:auto}.diagram.rendered pre,.diagram.rendered .code-label,.math-block.rendered>code,.math-block.rendered>.math-label{display:none}
        body.editing article{cursor:text;caret-color:\(palette.accent)}body.editing article:empty:before{content:'Start writing…';color:\(palette.muted)}
        body.editing .code-block,body.editing .math-block,body.editing .table-wrap{box-shadow:0 0 0 1px transparent;transition:box-shadow .15s ease}body.editing .code-block:focus-within,body.editing .math-block:focus-within,body.editing .table-wrap:focus-within{box-shadow:0 0 0 2px color-mix(in srgb,\(palette.accent) 48%,transparent)}
        article.focus-mode>*{opacity:.22;transition:opacity .16s ease}article.focus-mode>.mdore-current{opacity:1}
        input[type=checkbox]{accent-color:\(palette.accent);margin-right:.55em}details.frontmatter{margin:0 0 1.7em;color:\(palette.muted);font-size:.84em}details.frontmatter pre{margin-top:.7em}
        @media(max-width:600px){body{padding:76px 23px 15vh}h1{font-size:2em}.table-wrap{width:calc(100vw - 28px)}th,td{min-width:7.5em;padding:.68em .75em}}
        @media print{body{padding:0;background:white;color:black}.table-wrap{width:100%;margin:1.5em 0;transform:none;overflow:visible}table{min-width:100%}}
        </style></head><body><article>\(body)</article></body></html>
        """
    }

    private static func blocks(_ source: String) -> String {
        var lines = source.components(separatedBy: "\n")
        var output: [String] = []
        var paragraph: [String] = []
        var listType: String?
        var index = 0
        var footnotes: [(id: String, text: String)] = []

        for lineIndex in lines.indices {
            let candidate = lines[lineIndex].trimmingCharacters(in: .whitespaces)
            guard candidate.hasPrefix("[^"), let marker = candidate.range(of: "]:") else { continue }
            let id = String(candidate[candidate.index(candidate.startIndex, offsetBy: 2)..<marker.lowerBound])
            let text = String(candidate[marker.upperBound...]).trimmingCharacters(in: .whitespaces)
            guard !id.isEmpty, !text.isEmpty else { continue }
            footnotes.append((id, text))
            lines[lineIndex] = ""
        }

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            let text = paragraph.map { line in
                line.hasSuffix("  ") ? inline(String(line.dropLast(2))) + "<br>" : inline(line)
            }.joined(separator: " ")
            output.append("<p>\(text)</p>")
            paragraph.removeAll()
        }
        func closeList() {
            if let listType { output.append("</\(listType)>") }
            listType = nil
        }
        func flushOpenBlocks() { flushParagraph(); closeList() }

        if lines.count > 2, lines[0].trimmingCharacters(in: .whitespaces) == "---",
           let end = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" }) {
            let metadata = lines[1..<end].joined(separator: "\n")
            output.append("<details class=\"frontmatter\"><summary>Document metadata</summary><pre><code>\(escape(metadata))</code></pre></details>")
            index = end + 1
        }

        while index < lines.count {
            let raw = lines[index]
            let line = raw.trimmingCharacters(in: .whitespaces)

            if line == "$$" {
                flushOpenBlocks()
                var formula: [String] = []
                index += 1
                while index < lines.count && lines[index].trimmingCharacters(in: .whitespaces) != "$$" {
                    formula.append(lines[index]); index += 1
                }
                let source = formula.joined(separator: "\n")
                output.append("<div class=\"math-block\" data-math=\"\(escapeAttribute(source))\"><span class=\"math-label\">LaTeX</span><code>\(escape(source))</code></div>")
                index += 1
                continue
            }

            if line.hasPrefix("```") || line.hasPrefix("~~~") {
                flushOpenBlocks()
                let fence = String(line.prefix(3))
                let language = safeLanguage(String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces))
                var code: [String] = []
                index += 1
                while index < lines.count && !lines[index].trimmingCharacters(in: .whitespaces).hasPrefix(fence) {
                    code.append(lines[index]); index += 1
                }
                let label = language.isEmpty ? "" : "<span class=\"code-label\">\(escape(language))</span>"
                let diagramClass = ["mermaid", "flowchart", "sequence"].contains(language.lowercased()) ? " diagram" : ""
                output.append("<div class=\"code-block\(diagramClass)\" data-language=\"\(escapeAttribute(language))\">\(label)<pre><code>\(escape(code.joined(separator: "\n")))</code></pre></div>")
                index += 1
                continue
            }

            if index + 1 < lines.count, isTableHeader(line, separator: lines[index + 1]) {
                flushOpenBlocks()
                let headers = splitTableRow(line)
                let alignments = tableAlignments(lines[index + 1])
                var rows: [[String]] = []
                index += 2
                while index < lines.count {
                    let candidate = lines[index].trimmingCharacters(in: .whitespaces)
                    guard !candidate.isEmpty, candidate.contains("|") else { break }
                    rows.append(splitTableRow(candidate)); index += 1
                }
                output.append(renderTable(headers: headers, alignments: alignments, rows: rows))
                continue
            }

            if index + 1 < lines.count, !line.isEmpty, let level = setextLevel(lines[index + 1]) {
                flushOpenBlocks()
                output.append("<h\(level) id=\"\(slug(line))\">\(inline(line))</h\(level)>")
                index += 2
                continue
            }

            if line.hasPrefix(">") {
                flushOpenBlocks()
                var quoteLines: [String] = []
                while index < lines.count {
                    let candidate = lines[index].trimmingCharacters(in: .whitespaces)
                    guard candidate.hasPrefix(">") else { break }
                    var content = String(candidate.dropFirst())
                    if content.hasPrefix(" ") { content.removeFirst() }
                    quoteLines.append(content); index += 1
                }
                output.append("<blockquote>\(blocks(quoteLines.joined(separator: "\n")))</blockquote>")
                continue
            }

            if line.isEmpty {
                flushOpenBlocks(); index += 1; continue
            }
            if line.uppercased() == "[TOC]" {
                flushOpenBlocks()
                let items = lines.compactMap(heading).map { "<a class=\"toc-level-\($0.level)\" href=\"#\(slug($0.text))\">\(inline($0.text))</a>" }.joined()
                output.append("<nav class=\"toc\">\(items)</nav>")
            } else if let heading = heading(line) {
                flushOpenBlocks(); output.append("<h\(heading.level) id=\"\(slug(heading.text))\">\(inline(heading.text))</h\(heading.level)>")
            } else if isHorizontalRule(line) {
                flushOpenBlocks(); output.append("<hr>")
            } else if let item = listItem(line) {
                flushParagraph()
                if listType != item.type {
                    closeList(); listType = item.type; output.append("<\(item.type)>")
                }
                output.append("<li>\(item.isHTML ? item.text : inline(item.text))</li>")
            } else {
                closeList(); paragraph.append(line)
            }
            index += 1
        }
        flushOpenBlocks()
        if !footnotes.isEmpty {
            let items = footnotes.map { "<li id=\"fn-\(escapeAttribute($0.id))\">\(inline($0.text))</li>" }.joined()
            output.append("<section class=\"footnotes\"><hr><ol>\(items)</ol></section>")
        }
        return output.joined(separator: "\n")
    }

    private static func renderTable(headers: [String], alignments: [String], rows: [[String]]) -> String {
        guard !headers.isEmpty else { return "" }
        func style(_ column: Int) -> String {
            let alignment = column < alignments.count ? alignments[column] : "left"
            return " style=\"text-align:\(alignment)\""
        }
        let head = headers.enumerated().map { "<th\(style($0.offset))>\(inline($0.element))</th>" }.joined()
        let body = rows.map { row in
            let cells = (0..<headers.count).map { column in
                let value = column < row.count ? row[column] : ""
                return "<td\(style(column))>\(inline(value))</td>"
            }.joined()
            return "<tr>\(cells)</tr>"
        }.joined()
        return "<div class=\"table-wrap\"><table><thead><tr>\(head)</tr></thead><tbody>\(body)</tbody></table></div>"
    }

    private static func isTableHeader(_ line: String, separator: String) -> Bool {
        guard line.contains("|") else { return false }
        let headers = splitTableRow(line)
        let markers = splitTableRow(separator.trimmingCharacters(in: .whitespaces))
        guard !headers.isEmpty, headers.count == markers.count else { return false }
        return markers.allSatisfy { $0.range(of: #"^:?-{3,}:?$"#, options: .regularExpression) != nil }
    }

    private static func tableAlignments(_ separator: String) -> [String] {
        splitTableRow(separator).map { marker in
            if marker.hasPrefix(":"), marker.hasSuffix(":") { return "center" }
            if marker.hasSuffix(":") { return "right" }
            return "left"
        }
    }

    private static func splitTableRow(_ row: String) -> [String] {
        var text = row.trimmingCharacters(in: .whitespaces)
        if text.hasPrefix("|") { text.removeFirst() }
        if text.hasSuffix("|") { text.removeLast() }
        var cells: [String] = []
        var cell = ""
        var escapedPipe = false
        for character in text {
            if escapedPipe {
                if character == "|" { cell.append("|") }
                else { cell.append("\\"); cell.append(character) }
                escapedPipe = false
            } else if character == "\\" {
                escapedPipe = true
            } else if character == "|" {
                cells.append(cell.trimmingCharacters(in: .whitespaces)); cell = ""
            } else {
                cell.append(character)
            }
        }
        if escapedPipe { cell.append("\\") }
        cells.append(cell.trimmingCharacters(in: .whitespaces))
        return cells
    }

    private static func setextLevel(_ line: String) -> Int? {
        let marker = line.trimmingCharacters(in: .whitespaces)
        if marker.range(of: #"^=+$"#, options: .regularExpression) != nil { return 1 }
        if marker.range(of: #"^-{3,}$"#, options: .regularExpression) != nil { return 2 }
        return nil
    }

    private static func heading(_ line: String) -> (level: Int, text: String)? {
        let count = line.prefix(while: { $0 == "#" }).count
        guard (1...6).contains(count), line.dropFirst(count).first == " " else { return nil }
        let text = String(line.dropFirst(count + 1)).replacingOccurrences(of: #"\s+#+\s*$"#, with: "", options: .regularExpression)
        return (count, text)
    }

    private static func isHorizontalRule(_ line: String) -> Bool {
        let compact = line.replacingOccurrences(of: " ", with: "")
        guard compact.count >= 3, let first = compact.first, ["-", "*", "_"].contains(String(first)) else { return false }
        return compact.allSatisfy { $0 == first }
    }

    private static func listItem(_ line: String) -> (type: String, text: String, isHTML: Bool)? {
        for marker in ["- ", "* ", "+ "] where line.hasPrefix(marker) {
            var text = String(line.dropFirst(2))
            if text.hasPrefix("[ ] ") {
                text = "<input type=checkbox disabled>" + inline(String(text.dropFirst(4)))
                return ("ul", text, true)
            }
            if text.lowercased().hasPrefix("[x] ") {
                text = "<input type=checkbox checked disabled>" + inline(String(text.dropFirst(4)))
                return ("ul", text, true)
            }
            return ("ul", text, false)
        }
        if let match = line.range(of: #"^\d+[.)]\s+"#, options: .regularExpression) {
            return ("ol", String(line[match.upperBound...]), false)
        }
        return nil
    }

    private static func safeLanguage(_ language: String) -> String {
        language.replacingOccurrences(of: #"[^A-Za-z0-9_+.-]"#, with: "", options: .regularExpression)
    }

    private static func slug(_ text: String) -> String {
        text.lowercased().replacingOccurrences(of: #"[^\p{L}\p{N}]+"#, with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private static func inline(_ raw: String) -> String {
        var text = escape(raw)
        let rules: [(String, String)] = [
            (#"\[\^([^\]]+)\]"#, ##"<sup class="footnote-ref"><a href="#fn-$1">[$1]</a></sup>"##),
            (#"!\[([^\]]*)\]\(([^)\s]+)\)\{width=(\d+)%\}"#, #"<img src="$2" alt="$1" style="width:$3%" data-width="$3">"#),
            (#"!\[([^\]]*)\]\(([^)\s]+)(?:\s+&quot;[^&]*&quot;)?\)"#, #"<img src="$2" alt="$1">"#),
            (#"\[([^\]]+)\]\(([^)\s]+)(?:\s+&quot;[^&]*&quot;)?\)"#, #"<a href="$2">$1</a>"#),
            (#"&lt;(https?://[^&]+)&gt;"#, #"<a href="$1">$1</a>"#),
            (#"`([^`]+)`"#, #"<code>$1</code>"#),
            (#"\*\*([^*]+)\*\*"#, #"<strong>$1</strong>"#),
            (#"__([^_]+)__"#, #"<strong>$1</strong>"#),
            (#"~~([^~]+)~~"#, #"<del>$1</del>"#),
            (#"==([^=]+)=="#, #"<mark>$1</mark>"#),
            (#"\^([^\^\n]+)\^"#, #"<sup>$1</sup>"#),
            (#"(?<!~)~([^~\n]+)~(?!~)"#, #"<sub>$1</sub>"#),
            (#"(?<!\\)\$([^$\n]+)\$"#, #"<span class="math-inline" data-math="$1">$1</span>"#),
            (#"(?<!\*)\*([^*]+)\*(?!\*)"#, #"<em>$1</em>"#),
            (#"(?<!_)_([^_]+)_(?!_)"#, #"<em>$1</em>"#)
        ]
        for (pattern, replacement) in rules {
            text = text.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
        }
        return text
    }

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func escapeAttribute(_ text: String) -> String { escape(text).replacingOccurrences(of: "\n", with: "&#10;") }

    private static func isDark(_ hex: String) -> Bool {
        let value = UInt64(hex.dropFirst(), radix: 16) ?? 0
        let red = Double((value >> 16) & 255), green = Double((value >> 8) & 255), blue = Double(value & 255)
        return red * 0.299 + green * 0.587 + blue * 0.114 < 138
    }
}
