import SwiftUI
import AppKit

@main
struct MDoreApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var workspace = ReaderWorkspace()

    var body: some Scene {
        Window("MDore", id: "reader") {
            ReaderView().environmentObject(workspace).frame(minWidth: 640, minHeight: 460)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(workspace.t("home.new")) { workspace.createDocument() }.keyboardShortcut("n")
                Button(workspace.t("home.open")) { workspace.chooseFiles() }.keyboardShortcut("o")
                Button(workspace.t("common.save")) { workspace.saveSelected() }.keyboardShortcut("s")
                Menu("Export") {
                    Button("PDF…") { workspace.perform(.exportPDF) }
                    Button("HTML…") { workspace.perform(.exportHTML) }
                }
                Divider()
                Button("Home") { workspace.showHome() }.keyboardShortcut("h", modifiers: [.command, .shift])
                Button("Close Tab") { workspace.closeSelected() }.keyboardShortcut("w")
            }
            CommandGroup(after: .toolbar) {
                Button("Refresh Document") { workspace.refreshSelected() }.keyboardShortcut("r")
                Divider()
                Button(workspace.t("editor.edit")) { workspace.editorMode = .edit }.keyboardShortcut("e", modifiers: [.command, .shift])
                Button(workspace.t("editor.read")) { workspace.editorMode = .read }.keyboardShortcut("p", modifiers: [.command, .shift])
                Divider()
                Button(workspace.t("search.placeholder")) { workspace.showSearch() }.keyboardShortcut("f")
                Button("Find Next") { workspace.findNext() }.keyboardShortcut("g")
                Divider()
                Button("Full Screen") { NSApp.keyWindow?.toggleFullScreen(nil) }.keyboardShortcut("r", modifiers: [.command, .shift])
                Divider()
                Button("Bigger Text") { workspace.adjustTextSize(by: 1) }.keyboardShortcut("+")
                Button("Smaller Text") { workspace.adjustTextSize(by: -1) }.keyboardShortcut("-")
                Button("Actual Size") { workspace.resetTextSize() }.keyboardShortcut("0")
            }
            CommandMenu("Format") {
                Button("Bold") { workspace.perform(.bold) }.keyboardShortcut("b")
                Button("Italic") { workspace.perform(.italic) }.keyboardShortcut("i")
                Button("Link") { workspace.insertLink() }.keyboardShortcut("k")
                Divider()
                Button("Heading 1") { workspace.perform(.heading(1)) }.keyboardShortcut("1", modifiers: [.command, .option])
                Button("Heading 2") { workspace.perform(.heading(2)) }.keyboardShortcut("2", modifiers: [.command, .option])
                Button("Heading 3") { workspace.perform(.heading(3)) }.keyboardShortcut("3", modifiers: [.command, .option])
                Divider()
                Button("Bullet List") { workspace.perform(.unorderedList) }.keyboardShortcut("u", modifiers: [.command, .option])
                Button("Numbered List") { workspace.perform(.orderedList) }.keyboardShortcut("o", modifiers: [.command, .option])
                Button("Code Block") { workspace.perform(.codeFence("")) }.keyboardShortcut("c", modifiers: [.command, .option])
            }
            CommandGroup(replacing: .help) {
                Button(workspace.t("home.guide")) { workspace.openGuide() }
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    func application(_ application: NSApplication, open urls: [URL]) {
        Task { @MainActor in FileOpenRouter.shared.receive(urls) }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@MainActor
final class FileOpenRouter {
    static let shared = FileOpenRouter()
    private var pending: [URL] = []
    var handler: (([URL]) -> Void)? {
        didSet {
            guard let handler, !pending.isEmpty else { return }
            handler(pending); pending.removeAll()
        }
    }
    func receive(_ urls: [URL]) {
        if let handler { handler(urls) } else { pending.append(contentsOf: urls) }
    }
}
