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
                Button("Открыть…") { workspace.chooseFiles() }.keyboardShortcut("o")
                Button("Закрыть вкладку") { workspace.closeSelected() }.keyboardShortcut("w")
            }
            CommandGroup(after: .toolbar) {
                Button("Обновить документ") { workspace.refreshSelected() }.keyboardShortcut("r")
                Divider()
                Button("Найти") { workspace.showSearch() }.keyboardShortcut("f")
                Button("Найти далее") { workspace.findNext() }.keyboardShortcut("g")
                Divider()
                Button("Режим чтения") { NSApp.keyWindow?.toggleFullScreen(nil) }.keyboardShortcut("r", modifiers: [.command, .shift])
                Divider()
                Button("Увеличить текст") { workspace.adjustTextSize(by: 1) }.keyboardShortcut("+")
                Button("Уменьшить текст") { workspace.adjustTextSize(by: -1) }.keyboardShortcut("-")
                Button("Обычный размер") { workspace.resetTextSize() }.keyboardShortcut("0")
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
