import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let markdown: String
    let baseURL: URL?
    let theme: ReaderTheme
    let textScale: Double
    let searchQuery: String
    let findRevision: Int
    let onScroll: () -> Void
    let onOpenLink: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        let view = ScrollAwareWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.setValue(false, forKey: "drawsBackground")
        view.onScroll = { [weak coordinator = context.coordinator] in coordinator?.onScroll?() }
        return view
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onScroll = onScroll
        coordinator.onOpenLink = onOpenLink
        coordinator.searchQuery = searchQuery
        coordinator.findRevision = findRevision

        let signature = "\(markdown.hashValue):\(theme.rawValue):\(textScale)"
        if coordinator.signature != signature {
            coordinator.signature = signature
            webView.loadHTMLString(MarkdownRenderer.render(markdown, theme: theme, textScale: textScale), baseURL: baseURL)
        } else if coordinator.lastSearchQuery != searchQuery || coordinator.lastFindRevision != findRevision {
            coordinator.performSearch(in: webView)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var signature = ""
        var onScroll: (() -> Void)?
        var onOpenLink: ((URL) -> Void)?
        var searchQuery = ""
        var findRevision = 0
        var lastSearchQuery = ""
        var lastFindRevision = 0

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { performSearch(in: webView) }

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

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if action.navigationType == .linkActivated, let url = action.request.url {
                onOpenLink?(url); decisionHandler(.cancel)
            } else { decisionHandler(.allow) }
        }
    }
}

final class ScrollAwareWebView: WKWebView {
    var onScroll: (() -> Void)?
    override func scrollWheel(with event: NSEvent) {
        if abs(event.scrollingDeltaY) > 0.5 { onScroll?() }
        super.scrollWheel(with: event)
    }
}
