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
        body{font-family:-apple-system,BlinkMacSystemFont,"SF Pro Text",system-ui,sans-serif;font-size:\(size)px;line-height:1.74;letter-spacing:-.008em;padding:96px 34px 20vh}
        article{max-width:720px;margin:0 auto;animation:arrive .22s ease-out both}
        @keyframes arrive{from{opacity:0;transform:translateY(5px)}to{opacity:1;transform:none}}
        h1,h2,h3,h4{font-family:"New York",ui-serif,Georgia,serif;line-height:1.16;letter-spacing:-.032em;margin:2.25em 0 .7em}
        h1{font-size:2.48em;margin-top:.3em}h2{font-size:1.72em;border-bottom:1px solid \(palette.line);padding-bottom:.38em}h3{font-size:1.3em}h4{font-size:1.09em}
        p{margin:0 0 1.25em}a{color:\(palette.accent);text-decoration-thickness:1px;text-underline-offset:3px}
        strong{font-weight:650}hr{border:0;border-top:1px solid \(palette.line);margin:2.6em 0}
        blockquote{margin:1.6em 0;padding:.1em 0 .1em 1.15em;border-left:3px solid \(palette.accent);color:\(palette.muted)}
        ul,ol{padding-left:1.45em;margin:0 0 1.3em}li{padding-left:.2em;margin:.28em 0}li::marker{color:\(palette.muted)}
        code{font-family:"SFMono-Regular",ui-monospace,monospace;font-size:.84em;background:\(palette.code);padding:.14em .35em;border-radius:5px}
        pre{overflow:auto;background:\(palette.code);border:1px solid \(palette.line);padding:1.1em 1.2em;border-radius:10px;line-height:1.55;margin:1.5em 0}pre code{padding:0;background:none}
        table{border-collapse:collapse;width:100%;margin:1.5em 0;font-size:.94em}th,td{text-align:left;padding:.65em .8em;border-bottom:1px solid \(palette.line)}th{font-weight:650}
        img{display:block;max-width:100%;height:auto;border-radius:9px;margin:1.8em auto}del{color:\(palette.muted)}
        input[type=checkbox]{accent-color:\(palette.accent);margin-right:.55em}
        @media(max-width:600px){body{padding:76px 23px 15vh}h1{font-size:2em}}
        </style></head><body><article>\(body)</article></body></html>
        """
    }

    private static func blocks(_ source: String) -> String {
        let lines = source.components(separatedBy: "\n")
        var output: [String] = []
        var paragraph: [String] = []
        var listType: String?
        var inCode = false
        var code: [String] = []

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            output.append("<p>\(inline(paragraph.joined(separator: " ")))</p>")
            paragraph.removeAll()
        }
        for raw in lines {
            if raw.hasPrefix("```") {
                flushParagraph()
                if inCode {
                    output.append("<pre><code>\(escape(code.joined(separator: "\n")))</code></pre>")
                    code.removeAll(); inCode = false
                } else {
                    if listType != nil { output.append("</\(listType!)>"); listType = nil }
                    inCode = true
                }
                continue
            }
            if inCode { code.append(raw); continue }

            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                flushParagraph()
                if listType != nil { output.append("</\(listType!)>"); listType = nil }
                continue
            }
            if let heading = heading(line) {
                flushParagraph()
                if listType != nil { output.append("</\(listType!)>"); listType = nil }
                output.append("<h\(heading.level)>\(inline(heading.text))</h\(heading.level)>")
            } else if line == "---" || line == "***" || line == "___" {
                flushParagraph(); output.append("<hr>")
            } else if line.hasPrefix("> ") {
                flushParagraph(); output.append("<blockquote>\(inline(String(line.dropFirst(2))))</blockquote>")
            } else if let item = listItem(line) {
                flushParagraph()
                if listType != item.type {
                    if listType != nil { output.append("</\(listType!)>") }
                    listType = item.type; output.append("<\(item.type)>")
                }
                let content = item.isHTML ? item.text : inline(item.text)
                output.append("<li>\(content)</li>")
            } else {
                if listType != nil { output.append("</\(listType!)>"); listType = nil }
                paragraph.append(line)
            }
        }
        flushParagraph()
        if listType != nil { output.append("</\(listType!)>") }
        if inCode { output.append("<pre><code>\(escape(code.joined(separator: "\n")))</code></pre>") }
        return output.joined(separator: "\n")
    }

    private static func heading(_ line: String) -> (level: Int, text: String)? {
        let count = line.prefix(while: { $0 == "#" }).count
        guard (1...6).contains(count), line.dropFirst(count).first == " " else { return nil }
        return (count, String(line.dropFirst(count + 1)))
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
        if let match = line.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
            return ("ol", String(line[match.upperBound...]), false)
        }
        return nil
    }

    private static func inline(_ raw: String) -> String {
        var text = escape(raw)
        let rules: [(String, String)] = [
            (#"!\[([^\]]*)\]\(([^)]+)\)"#, #"<img src="$2" alt="$1">"#),
            (#"\[([^\]]+)\]\(([^)]+)\)"#, #"<a href="$2">$1</a>"#),
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
