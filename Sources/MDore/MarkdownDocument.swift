import Foundation
import AppKit
import UniformTypeIdentifiers

struct MarkdownTab: Identifiable, Equatable {
    let id: UUID
    let url: URL
    var markdown: String
    var fingerprint: FileFingerprint
    var isAvailable: Bool
    var lastSyncedAt: Date

    init(id: UUID = UUID(), url: URL, markdown: String, fingerprint: FileFingerprint,
         isAvailable: Bool = true, lastSyncedAt: Date = .now) {
        self.id = id
        self.url = url
        self.markdown = markdown
        self.fingerprint = fingerprint
        self.isAvailable = isAvailable
        self.lastSyncedAt = lastSyncedAt
    }

    var title: String { url.deletingPathExtension().lastPathComponent }
}

struct FileFingerprint: Equatable {
    let modificationDate: Date?
    let size: UInt64
    let fileNumber: UInt64
}

enum ReaderTheme: String, CaseIterable, Identifiable {
    case paper, porcelain, graphite, midnight
    var id: String { rawValue }
    var title: String {
        switch self { case .paper: "Бумага"; case .porcelain: "Фарфор"; case .graphite: "Графит"; case .midnight: "Полночь" }
    }
    var subtitle: String {
        switch self { case .paper: "Тёплая и редакционная"; case .porcelain: "Чистая и воздушная"; case .graphite: "Спокойная и строгая"; case .midnight: "Глубокая и контрастная" }
    }
    var palette: ThemePalette {
        switch self {
        case .paper: ThemePalette(bg: "#F7F2E8", text: "#292721", muted: "#777066", line: "#DED6C8", code: "#EEE7DA", accent: "#9A6239", chrome: "#F2ECE1")
        case .porcelain: ThemePalette(bg: "#FAFAF8", text: "#20211F", muted: "#737570", line: "#E4E5E1", code: "#F0F1EE", accent: "#356F73", chrome: "#F6F6F3")
        case .graphite: ThemePalette(bg: "#20211F", text: "#E9E8E3", muted: "#A2A29C", line: "#393A36", code: "#292A27", accent: "#D0A36B", chrome: "#252623")
        case .midnight: ThemePalette(bg: "#101419", text: "#E8EDF1", muted: "#89949E", line: "#29313A", code: "#181E24", accent: "#82B7C5", chrome: "#141A20")
        }
    }
}

struct ThemePalette {
    let bg: String; let text: String; let muted: String; let line: String
    let code: String; let accent: String; let chrome: String
}

@MainActor
final class ReaderWorkspace: ObservableObject {
    @Published private(set) var tabs: [MarkdownTab] = []
    @Published var selectedID: UUID?
    @Published var textScale = 1.0
    @Published var searchQuery = ""
    @Published var isSearchPresented = false
    @Published var findRevision = 0
    @Published var theme: ReaderTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "readerTheme") }
    }
    @Published var defaultReaderResult: String?
    @Published private(set) var syncRevision = 0

    private var monitorTask: Task<Void, Never>?
    private var reloadTasks: [UUID: Task<Void, Never>] = [:]

    init(startMonitoring: Bool = true) {
        theme = ReaderTheme(rawValue: UserDefaults.standard.string(forKey: "readerTheme") ?? "") ?? .paper
        if startMonitoring {
            monitorTask = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(650))
                    guard !Task.isCancelled else { return }
                    self?.refreshChangedFiles()
                }
            }
        }
    }

    deinit {
        monitorTask?.cancel()
        reloadTasks.values.forEach { $0.cancel() }
    }

    var selectedTab: MarkdownTab? { tabs.first(where: { $0.id == selectedID }) }

    var syncStatusText: String {
        guard let tab = selectedTab else { return "Нет открытого документа" }
        return tab.isAvailable
            ? "Синхронизация включена · Обновить сейчас — ⌘R"
            : "Файл временно недоступен · Повторить — ⌘R"
    }

    func chooseFiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "md")!, UTType(filenameExtension: "markdown")!]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.begin { [weak self] result in
            guard result == .OK else { return }
            Task { @MainActor in panel.urls.forEach { self?.open($0) } }
        }
    }

    func open(_ fileURL: URL) {
        guard fileURL.isFileURL else { return }
        if let existing = tabs.first(where: { $0.url.standardizedFileURL == fileURL.standardizedFileURL }) {
            selectedID = existing.id; return
        }
        do {
            let document = try readDocument(at: fileURL)
            let tab = MarkdownTab(url: fileURL, markdown: document.markdown, fingerprint: document.fingerprint)
            tabs.append(tab); selectedID = tab.id
            NSDocumentController.shared.noteNewRecentDocumentURL(fileURL)
        } catch { NSSound.beep() }
    }

    func close(_ id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        reloadTasks.removeValue(forKey: id)?.cancel()
        tabs.remove(at: index)
        if selectedID == id { selectedID = tabs.indices.contains(index) ? tabs[index].id : tabs.last?.id }
    }
    func closeSelected() { if let selectedID { close(selectedID) } }

    func refreshSelected() {
        guard let selectedID else { return }
        reloadTasks.removeValue(forKey: selectedID)?.cancel()
        refresh(id: selectedID, forceFeedback: true)
    }

    func followLink(_ url: URL) {
        if url.isFileURL, ["md", "markdown", "mdown"].contains(url.pathExtension.lowercased()) { open(url) }
        else { NSWorkspace.shared.open(url) }
    }

    func showSearch() { isSearchPresented = true }
    func hideSearch() { isSearchPresented = false; searchQuery = "" }
    func findNext(backwards: Bool = false) { findRevision += backwards ? -1 : 1 }
    func adjustTextSize(by step: Double) { textScale = min(1.45, max(0.75, textScale + step * 0.1)) }
    func resetTextSize() { textScale = 1 }

    private func refreshChangedFiles() {
        for tab in tabs {
            guard let current = try? fingerprint(for: tab.url) else {
                setAvailability(false, for: tab.id)
                continue
            }
            if current != tab.fingerprint {
                scheduleReload(for: tab.id)
            } else if !tab.isAvailable {
                setAvailability(true, for: tab.id)
            }
        }
    }

    private func scheduleReload(for id: UUID) {
        reloadTasks[id]?.cancel()
        reloadTasks[id] = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
            self?.refresh(id: id, forceFeedback: false)
            self?.reloadTasks[id] = nil
        }
    }

    private func refresh(id: UUID, forceFeedback: Bool) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        do {
            let document = try readDocument(at: tabs[index].url)
            var tab = tabs[index]
            let contentChanged = tab.markdown != document.markdown
            tab.markdown = document.markdown
            tab.fingerprint = document.fingerprint
            tab.isAvailable = true
            tab.lastSyncedAt = .now
            tabs[index] = tab
            if contentChanged || forceFeedback { syncRevision += 1 }
        } catch {
            setAvailability(false, for: id)
            if forceFeedback { NSSound.beep() }
        }
    }

    private func setAvailability(_ isAvailable: Bool, for id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }), tabs[index].isAvailable != isAvailable else { return }
        var tab = tabs[index]
        tab.isAvailable = isAvailable
        tabs[index] = tab
        syncRevision += 1
    }

    private func readDocument(at url: URL) throws -> (markdown: String, fingerprint: FileFingerprint) {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        let decoded = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .windowsCP1251)
            ?? String(decoding: data, as: UTF8.self)
        return (decoded, try fingerprint(for: url))
    }

    private func fingerprint(for url: URL) throws -> FileFingerprint {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return FileFingerprint(
            modificationDate: attributes[.modificationDate] as? Date,
            size: (attributes[.size] as? NSNumber)?.uint64Value ?? 0,
            fileNumber: (attributes[.systemFileNumber] as? NSNumber)?.uint64Value ?? 0
        )
    }

    func makeDefaultReader() {
        let markdown = UTType(importedAs: "net.daringfireball.markdown", conformingTo: .plainText)
        NSWorkspace.shared.setDefaultApplication(at: Bundle.main.bundleURL, toOpen: markdown) { [weak self] error in
            Task { @MainActor in
                self?.defaultReaderResult = error == nil
                    ? "MDore теперь открывает Markdown по умолчанию"
                    : "Выберите MDore через «Свойства файла»"
            }
        }
    }
}
