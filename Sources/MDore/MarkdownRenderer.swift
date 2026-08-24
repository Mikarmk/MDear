import Foundation

enum MarkdownRenderer {
    static func render(_ markdown: String, theme: ReaderTheme, textScale: Double) -> String {
        let body = blocks(markdown.replacingOccurrences(of: "\r\n", with: "\n"))
        let palette = theme.palette
        let darkMode = theme == .graphite || theme == .midnight
        let size = String(format: "%.2f", 17 * textScale)
        return """
        <!doctype html><html><head><meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        :root{color-scheme:\(darkMode ? "dark" : "light")}
        *{box-sizing:border-box}html,body{margin:0;min-height:100%;background:\(palette.bg);color:\(palette.text)}
        body{font-family:-apple-system,BlinkMacSystemFont,"SF Pro Text",system-ui,sans-serif;font-size:\(size)px;line-height:1.74;letter-spacing:-.008em;padding:96px 34px 20vh;overflow-wrap:break-word}
        article{max-width:720px;margin:0 auto;animation:arrive .22s ease-out both}
        @keyframes arrive{from{opacity:0;transform:translateY(5px)}to{opacity:1;transform:none}}
        h1,h2,h3,h4,h5,h6{font-family:"New York",ui-serif,Georgia,serif;line-height:1.16;letter-spacing:-.032em;margin:2.25em 0 .7em}
        h1{font-size:2.48em;margin-top:.3em}h2{font-size:1.72em;border-bottom:1px solid \(palette.line);padding-bottom:.38em}h3{font-size:1.3em}h4{font-size:1.09em}h5,h6{font-size:1em}
        p{margin:0 0 1.25em}a{color:\(palette.accent);text-decoration-thickness:1px;text-underline-offset:3px}a:hover{text-decoration-thickness:2px}
        strong{font-weight:650}hr{border:0;border-top:1px solid \(palette.line);margin:2.6em 0}
        blockquote{margin:1.6em 0;padding:.05em 0 .05em 1.15em;border-left:3px solid \(palette.accent);color:\(palette.muted)}blockquote>:last-child{margin-bottom:0}
        ul,ol{padding-left:1.45em;margin:0 0 1.3em}li{padding-left:.2em;margin:.28em 0}li::marker{color:\(palette.muted)}
        code{font-family:"SFMono-Regular",ui-monospace,monospace;font-size:.84em;background:\(palette.code);padding:.14em .35em;border-radius:5px}
        .code-block{position:relative;margin:1.5em 0}.code-block pre{margin:0}.code-label{position:absolute;top:.65em;right:.8em;color:\(palette.muted);font:600 .66em -apple-system,system-ui,sans-serif;letter-spacing:.04em;text-transform:uppercase}
        pre{overflow:auto;background:\(palette.code);border:1px solid \(palette.line);padding:1.15em 1.2em;border-radius:11px;line-height:1.55}pre code{padding:0;background:none;white-space:pre;overflow-wrap:normal}
        .table-wrap{width:min(920px,calc(100vw - 48px));margin:1.8em 50% 2.1em;transform:translateX(-50%);overflow:auto;border:1px solid \(palette.line);border-radius:12px;background:\(palette.bg);box-shadow:0 1px 0 rgba(0,0,0,.025)}
        table{border-collapse:separate;border-spacing:0;width:100%;min-width:max-content;font-size:.9em;line-height:1.5;font-variant-numeric:tabular-nums}
        th,td{min-width:8.5em;max-width:28em;padding:.76em .9em;border-right:1px solid \(palette.line);border-bottom:1px solid \(palette.line);vertical-align:top}
        th:last-child,td:last-child{border-right:0}tbody tr:last-child td{border-bottom:0}
        th{font-weight:650;background:\(palette.code);white-space:nowrap}tbody tr:nth-child(even) td{background:color-mix(in srgb,\(palette.code) 42%,transparent)}tbody tr:hover td{background:color-mix(in srgb,\(palette.accent) 8%,transparent)}
        td code{white-space:nowrap}.table-wrap::-webkit-scrollbar{height:9px}.table-wrap::-webkit-scrollbar-thumb{background:\(palette.line);border:2px solid \(palette.bg);border-radius:9px}
        img{display:block;max-width:100%;height:auto;border-radius:9px;margin:1.8em auto}del{color:\(palette.muted)}
        input[type=checkbox]{accent-color:\(palette.accent);margin-right:.55em}details.frontmatter{margin:0 0 1.7em;color:\(palette.muted);font-size:.84em}details.frontmatter pre{margin-top:.7em}
        @media(max-width:600px){body{padding:76px 23px 15vh}h1{font-size:2em}.table-wrap{width:calc(100vw - 28px)}th,td{min-width:7.5em;padding:.68em .75em}}
        @media print{body{padding:0;background:white;color:black}.table-wrap{width:100%;margin:1.5em 0;transform:none;overflow:visible}table{min-width:100%}}
        </style></head><body><article>\(body)</article></body></html>
        """
    }

    private static func blocks(_ source: String) -> String {
        let lines = source.components(separatedBy: "\n")
        var output: [String] = []
        var paragraph: [String] = []
        var listType: String?
        var index = 0

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
                output.append("<div class=\"code-block\">\(label)<pre><code>\(escape(code.joined(separator: "\n")))</code></pre></div>")
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
                output.append("<h\(level)>\(inline(line))</h\(level)>")
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
            if let heading = heading(line) {
                flushOpenBlocks(); output.append("<h\(heading.level)>\(inline(heading.text))</h\(heading.level)>")
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

    private static func inline(_ raw: String) -> String {
        var text = escape(raw)
        let rules: [(String, String)] = [
            (#"!\[([^\]]*)\]\(([^)\s]+)(?:\s+&quot;[^&]*&quot;)?\)"#, #"<img src="$2" alt="$1">"#),
            (#"\[([^\]]+)\]\(([^)\s]+)(?:\s+&quot;[^&]*&quot;)?\)"#, #"<a href="$2">$1</a>"#),
            (#"&lt;(https?://[^&]+)&gt;"#, #"<a href="$1">$1</a>"#),
            (#"`([^`]+)`"#, #"<code>$1</code>"#),
            (#"\*\*([^*]+)\*\*"#, #"<strong>$1</strong>"#),
            (#"__([^_]+)__"#, #"<strong>$1</strong>"#),
            (#"~~([^~]+)~~"#, #"<del>$1</del>"#),
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
}
