import Foundation

@main
struct RendererTests {
    static func main() {
        let markdown = """
        ---
        owner: docs-team
        ---

        Table rendering
        ===============

        | Feature | Status | Score | Note |
        | :--- | :---: | ---: | --- |
        | Tables | **Ready** | 100 | A \\| B |
        | Search | Works | 98 | `⌘F` |

        > A calm quote
        > over two lines.

        ```swift
        let release = "1.1.0"
        ```
        """

        let html = MarkdownRenderer.render(markdown, theme: .paper, textScale: 1)
        expect(html.contains("<div class=\"table-wrap\"><table>"), "table wrapper")
        expect(html.contains("<th style=\"text-align:center\">Status</th>"), "center alignment")
        expect(html.contains("<td style=\"text-align:right\">100</td>"), "right alignment")
        expect(html.contains("A | B"), "escaped pipe")
        expect(html.contains("<h1>Table rendering</h1>"), "setext heading")
        expect(html.contains("<blockquote>"), "multiline quote")
        expect(html.contains("class=\"code-label\">swift"), "fenced code language")
        expect(html.contains("Document metadata"), "front matter")
        expect(!html.contains("| :--- |"), "separator is not visible")
        print("Renderer tests passed")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ name: String) {
        guard condition() else {
            FileHandle.standardError.write(Data("Renderer test failed: \(name)\n".utf8))
            exit(1)
        }
    }
}

