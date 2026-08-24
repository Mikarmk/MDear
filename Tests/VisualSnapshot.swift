import AppKit
import WebKit

final class SnapshotDelegate: NSObject, WKNavigationDelegate {
    let outputURL: URL
    init(outputURL: URL) { self.outputURL = outputURL }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            webView.takeSnapshot(with: nil) { image, error in
                guard error == nil, let image, let tiff = image.tiffRepresentation,
                      let bitmap = NSBitmapImageRep(data: tiff),
                      let png = bitmap.representation(using: .png, properties: [:]) else {
                    exit(1)
                }
                try? png.write(to: self.outputURL)
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

@main
struct VisualSnapshot {
    static var delegate: SnapshotDelegate?
    static var window: NSWindow?

    static func main() throws {
        guard CommandLine.arguments.count == 3 else {
            FileHandle.standardError.write(Data("Usage: VisualSnapshot input.md output.png\n".utf8))
            exit(2)
        }
        let markdown = try String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8)
        let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 1120, height: 900))
        window = NSWindow(contentRect: webView.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window?.contentView = webView
        window?.orderFront(nil)
        delegate = SnapshotDelegate(outputURL: outputURL)
        webView.navigationDelegate = delegate
        webView.loadHTMLString(MarkdownRenderer.render(markdown, theme: .paper, textScale: 1), baseURL: nil)
        NSApplication.shared.run()
    }
}
