import Foundation
import AppKit
import UniformTypeIdentifiers

struct MarkdownTab: Identifiable, Equatable {
    let id: UUID
    var url: URL
    var markdown: String
    var fingerprint: FileFingerprint
    var isAvailable: Bool
    var lastSyncedAt: Date
    var isDirty: Bool
    var hasExternalConflict: Bool
    var isManaged: Bool

    init(id: UUID = UUID(), url: URL, markdown: String, fingerprint: FileFingerprint,
         isAvailable: Bool = true, lastSyncedAt: Date = .now, isDirty: Bool = false,
         hasExternalConflict: Bool = false, isManaged: Bool = false) {
        self.id = id
        self.url = url
        self.markdown = markdown
        self.fingerprint = fingerprint
        self.isAvailable = isAvailable
        self.lastSyncedAt = lastSyncedAt
        self.isDirty = isDirty
        self.hasExternalConflict = hasExternalConflict
        self.isManaged = isManaged
    }

    var title: String { url.deletingPathExtension().lastPathComponent }
}

struct FileFingerprint: Equatable {
    let modificationDate: Date?
    let size: UInt64
    let fileNumber: UInt64
}

struct OutlineItem: Identifiable {
    let id = UUID()
    let level: Int
    let title: String
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

enum EditorMode: String { case edit, read }

enum DocumentTemplate: String, CaseIterable, Identifiable {
    case blank, meeting, project
    var id: String { rawValue }
}

enum SaveState: Equatable {
    case saved
    case saving
    case conflict
    case unavailable
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
    @Published var editorMode: EditorMode = .edit
    @Published var editorCommand: EditorCommand?
    @Published var isSettingsPresented = false
    @Published var isSidebarPresented = false
    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "appLanguage") }
    }
    @Published var customAccentHex: String {
        didSet { UserDefaults.standard.set(customAccentHex, forKey: "customAccent") }
    }
    @Published var customBackgroundHex: String {
        didSet { UserDefaults.standard.set(customBackgroundHex, forKey: "customBackground") }
    }
    @Published var backgroundImagePath: String? {
        didSet { UserDefaults.standard.set(backgroundImagePath, forKey: "backgroundImagePath") }
    }
    @Published var pageWidth: Double {
        didSet { UserDefaults.standard.set(pageWidth, forKey: "pageWidth") }
    }
    @Published var focusMode: Bool {
        didSet { UserDefaults.standard.set(focusMode, forKey: "focusMode") }
    }
    @Published var typewriterMode: Bool {
        didSet { UserDefaults.standard.set(typewriterMode, forKey: "typewriterMode") }
    }
    @Published var showCodeLineNumbers: Bool {
        didSet { UserDefaults.standard.set(showCodeLineNumbers, forKey: "showCodeLineNumbers") }
    }

    private var monitorTask: Task<Void, Never>?
    private var reloadTasks: [UUID: Task<Void, Never>] = [:]
    private var saveTasks: [UUID: Task<Void, Never>] = [:]

    private static let recentKey = "recentDocumentPaths"

    var palette: ThemePalette {
        let base = theme.palette
        let accent = customAccentHex.isEmpty ? base.accent : customAccentHex
        guard !customBackgroundHex.isEmpty else {
            return ThemePalette(bg: base.bg, text: base.text, muted: base.muted, line: base.line,
                                code: base.code, accent: accent, chrome: base.chrome)
        }
        let dark = customBackgroundHex.isDarkHex
        return ThemePalette(bg: customBackgroundHex,
                            text: dark ? "#F0F1ED" : "#242521",
                            muted: dark ? "#A0A39B" : "#70736C",
                            line: dark ? "#3A3D38" : "#DEDFDA",
                            code: dark ? "#282B27" : "#EFF0EC",
                            accent: accent,
                            chrome: dark ? "#222420" : "#F5F5F1")
    }

    var backgroundImageURL: URL? { backgroundImagePath.map(URL.init(fileURLWithPath:)) }

    var recentURLs: [URL] {
        (UserDefaults.standard.stringArray(forKey: Self.recentKey) ?? [])
            .map(URL.init(fileURLWithPath:))
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    var saveState: SaveState {
        guard let tab = selectedTab else { return .saved }
        if tab.hasExternalConflict { return .conflict }
        if !tab.isAvailable { return .unavailable }
        return tab.isDirty ? .saving : .saved
    }

    init(startMonitoring: Bool = true) {
        theme = ReaderTheme(rawValue: UserDefaults.standard.string(forKey: "readerTheme") ?? "") ?? .paper
        language = AppLanguage(rawValue: UserDefaults.standard.string(forKey: "appLanguage") ?? "") ?? .systemDefault
        customAccentHex = UserDefaults.standard.string(forKey: "customAccent") ?? ""
        customBackgroundHex = UserDefaults.standard.string(forKey: "customBackground") ?? ""
        backgroundImagePath = UserDefaults.standard.string(forKey: "backgroundImagePath")
        pageWidth = UserDefaults.standard.object(forKey: "pageWidth") as? Double ?? 720
        focusMode = UserDefaults.standard.bool(forKey: "focusMode")
        typewriterMode = UserDefaults.standard.bool(forKey: "typewriterMode")
        showCodeLineNumbers = UserDefaults.standard.bool(forKey: "showCodeLineNumbers")
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
        saveTasks.values.forEach { $0.cancel() }
    }

    var selectedTab: MarkdownTab? { tabs.first(where: { $0.id == selectedID }) }

    var outlineItems: [OutlineItem] {
        guard let markdown = selectedTab?.markdown else { return [] }
        return markdown.components(separatedBy: .newlines).compactMap { line in
            let level = line.prefix(while: { $0 == "#" }).count
            guard (1...6).contains(level), line.dropFirst(level).first == " " else { return nil }
            return OutlineItem(level: level, title: String(line.dropFirst(level + 1)))
        }
    }

    var siblingDocuments: [URL] {
        guard let directory = selectedTab?.url.deletingLastPathComponent() else { return [] }
        return ((try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? [])
            .filter { ["md", "markdown", "mdown"].contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    func t(_ key: String) -> String { language.text(key) }

    func themeTitle(_ theme: ReaderTheme) -> String {
        switch (language, theme) {
        case (.english, .paper): "Paper"; case (.english, .porcelain): "Porcelain"; case (.english, .graphite): "Graphite"; case (.english, .midnight): "Midnight"
        case (.spanish, .paper): "Papel"; case (.spanish, .porcelain): "Porcelana"; case (.spanish, .graphite): "Grafito"; case (.spanish, .midnight): "Medianoche"
        case (.russian, .paper): "Бумага"; case (.russian, .porcelain): "Фарфор"; case (.russian, .graphite): "Графит"; case (.russian, .midnight): "Полночь"
        }
    }

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
            let tab = MarkdownTab(url: fileURL, markdown: document.markdown, fingerprint: document.fingerprint,
                                  isManaged: isInsideLibrary(fileURL))
            tabs.append(tab); selectedID = tab.id
            NSDocumentController.shared.noteNewRecentDocumentURL(fileURL)
            remember(fileURL)
        } catch { NSSound.beep() }
    }

    func createDocument() {
        createDocument(from: .blank)
    }

    func createDocument(from template: DocumentTemplate) {
        do {
            let name = localizedTemplateName(template)
            let folder = try uniqueDocumentFolder(named: name)
            let file = folder.appendingPathComponent("\(name).md")
            try templateDocument(template).write(to: file, atomically: true, encoding: .utf8)
            open(file)
            editorMode = .edit
        } catch { NSSound.beep() }
    }

    func openGuide() {
        do {
            let folder = try libraryURL().appendingPathComponent("Guide", isDirectory: true).ensuringDirectory()
            let file = folder.appendingPathComponent("MDore Guide \(language.rawValue.uppercased()).md")
            if !FileManager.default.fileExists(atPath: file.path) {
                try guideDocument().write(to: file, atomically: true, encoding: .utf8)
            }
            open(file)
            editorMode = .read
        } catch { NSSound.beep() }
    }

    func close(_ id: UUID) {
        guard var index = tabs.firstIndex(where: { $0.id == id }) else { return }
        if tabs[index].isDirty {
            save(id: id)
            selectedID = id
            if tabs[index].hasExternalConflict { resolveSelectedConflict() }
            guard let refreshedIndex = tabs.firstIndex(where: { $0.id == id }), !tabs[refreshedIndex].isDirty else { return }
            index = refreshedIndex
        }
        reloadTasks.removeValue(forKey: id)?.cancel()
        saveTasks.removeValue(forKey: id)?.cancel()
        tabs.remove(at: index)
        if selectedID == id { selectedID = tabs.indices.contains(index) ? tabs[index].id : tabs.last?.id }
    }
    func closeSelected() { if let selectedID { close(selectedID) } }

    func showHome() { selectedID = nil }

    func updateMarkdown(_ markdown: String, for id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }), tabs[index].markdown != markdown else { return }
        var tab = tabs[index]
        tab.markdown = markdown
        tab.isDirty = true
        tab.hasExternalConflict = false
        tabs[index] = tab
        scheduleSave(for: id)
    }

    func saveSelected() {
        guard let selectedID else { return }
        saveTasks.removeValue(forKey: selectedID)?.cancel()
        save(id: selectedID)
    }

    func resolveSelectedConflict() {
        guard let selectedID, let index = tabs.firstIndex(where: { $0.id == selectedID }), tabs[index].hasExternalConflict else { return }
        let alert = NSAlert()
        alert.messageText = t("editor.conflict")
        alert.informativeText = language == .russian
            ? "Файл изменился после открытия. Оставить вашу версию или загрузить версию с диска?"
            : language == .spanish
                ? "El archivo cambió después de abrirlo. ¿Conservar tu versión o cargar la del disco?"
                : "The file changed after opening. Keep your version or load the version from disk?"
        alert.addButton(withTitle: language == .russian ? "Оставить мою" : language == .spanish ? "Conservar la mía" : "Keep mine")
        alert.addButton(withTitle: language == .russian ? "Загрузить с диска" : language == .spanish ? "Cargar del disco" : "Load from disk")
        if alert.runModal() == .alertFirstButtonReturn {
            do {
                try tabs[index].markdown.write(to: tabs[index].url, atomically: true, encoding: .utf8)
                var tab = tabs[index]
                tab.fingerprint = try fingerprint(for: tab.url)
                tab.isDirty = false
                tab.hasExternalConflict = false
                tabs[index] = tab
            } catch { NSSound.beep() }
        } else {
            var tab = tabs[index]
            tab.isDirty = false
            tab.hasExternalConflict = false
            tabs[index] = tab
            refresh(id: selectedID, forceFeedback: true)
        }
    }

    func perform(_ action: EditorAction) { editorCommand = EditorCommand(action: action) }

    func rename(_ id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        let alert = NSAlert()
        alert.messageText = t("common.rename")
        alert.addButton(withTitle: t("common.done"))
        alert.addButton(withTitle: t("common.cancel"))
        let field = NSTextField(string: tabs[index].title)
        field.frame = NSRect(x: 0, y: 0, width: 320, height: 24)
        alert.accessoryView = field
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let clean = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
        guard !clean.isEmpty else { return }
        do {
            let oldURL = tabs[index].url
            let newURL = oldURL.deletingLastPathComponent().appendingPathComponent(clean).appendingPathExtension("md")
            try FileManager.default.moveItem(at: oldURL, to: newURL)
            var tab = tabs[index]
            tab.url = newURL
            tab.fingerprint = try fingerprint(for: newURL)
            tabs[index] = tab
            remember(newURL)
        } catch { NSSound.beep() }
    }

    func refreshSelected() {
        guard let selectedID else { return }
        reloadTasks.removeValue(forKey: selectedID)?.cancel()
        refresh(id: selectedID, forceFeedback: true)
    }

    func followLink(_ url: URL) {
        if url.isFileURL, ["md", "markdown", "mdown"].contains(url.pathExtension.lowercased()) { open(url) }
        else if ["http", "https", "mailto"].contains(url.scheme?.lowercased() ?? "") { NSWorkspace.shared.open(url) }
    }

    func showSearch() { isSearchPresented = true }
    func hideSearch() { isSearchPresented = false; searchQuery = "" }
    func findNext(backwards: Bool = false) { findRevision += backwards ? -1 : 1 }
    func adjustTextSize(by step: Double) { textScale = min(1.45, max(0.75, textScale + step * 0.1)) }
    func resetTextSize() { textScale = 1 }

    func insertLink() {
        let alert = NSAlert()
        alert.messageText = t("editor.link")
        alert.informativeText = "URL"
        alert.addButton(withTitle: t("common.done"))
        alert.addButton(withTitle: t("common.cancel"))
        let field = NSTextField(string: NSPasteboard.general.string(forType: .string) ?? "https://")
        field.frame = NSRect(x: 0, y: 0, width: 340, height: 24)
        alert.accessoryView = field
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        perform(.link(field.stringValue))
    }

    func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .gif, .webP, .svg]
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        importImage(url)
    }

    func importImage(_ imageURL: URL) {
        guard let selectedID, let index = tabs.firstIndex(where: { $0.id == selectedID }) else { return }
        if !tabs[index].isManaged, !makeManagedCopy(for: selectedID) { return }
        guard let refreshedIndex = tabs.firstIndex(where: { $0.id == selectedID }) else { return }
        let tab = tabs[refreshedIndex]
        do {
            let assets = try tab.url.deletingLastPathComponent().appendingPathComponent("assets", isDirectory: true).ensuringDirectory()
            let destination = uniqueAssetURL(for: imageURL, in: assets)
            try FileManager.default.copyItem(at: imageURL, to: destination)
            perform(.image(path: "assets/\(destination.lastPathComponent)", alt: destination.deletingPathExtension().lastPathComponent))
        } catch { NSSound.beep() }
    }

    func chooseBackgroundImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .webP]
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        backgroundImagePath = url.path
    }

    func clearBackgroundImage() { backgroundImagePath = nil }

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

    private func scheduleSave(for id: UUID) {
        saveTasks[id]?.cancel()
        saveTasks[id] = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(520))
            guard !Task.isCancelled else { return }
            self?.save(id: id)
            self?.saveTasks[id] = nil
        }
    }

    private func save(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }), tabs[index].isDirty else { return }
        let original = tabs[index]
        do {
            if let diskFingerprint = try? fingerprint(for: original.url), diskFingerprint != original.fingerprint {
                var conflict = original
                conflict.hasExternalConflict = true
                tabs[index] = conflict
                syncRevision += 1
                return
            }
            try original.markdown.write(to: original.url, atomically: true, encoding: .utf8)
            var saved = original
            saved.fingerprint = try fingerprint(for: original.url)
            saved.isDirty = false
            saved.isAvailable = true
            saved.hasExternalConflict = false
            saved.lastSyncedAt = .now
            tabs[index] = saved
            syncRevision += 1
        } catch {
            setAvailability(false, for: id)
        }
    }

    private func refresh(id: UUID, forceFeedback: Bool) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        do {
            let document = try readDocument(at: tabs[index].url)
            var tab = tabs[index]
            if tab.isDirty {
                tab.hasExternalConflict = true
                tabs[index] = tab
                syncRevision += 1
                return
            }
            let contentChanged = tab.markdown != document.markdown
            tab.markdown = document.markdown
            tab.fingerprint = document.fingerprint
            tab.isAvailable = true
            tab.lastSyncedAt = .now
            tab.hasExternalConflict = false
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

    private func libraryURL() throws -> URL {
        let root = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                               appropriateFor: nil, create: true)
            .appendingPathComponent("MDore", isDirectory: true)
            .appendingPathComponent("Documents", isDirectory: true)
        return try root.ensuringDirectory()
    }

    private func isInsideLibrary(_ url: URL) -> Bool {
        guard let root = try? libraryURL().standardizedFileURL.path else { return false }
        return url.standardizedFileURL.path.hasPrefix(root + "/")
    }

    private func uniqueDocumentFolder(named name: String) throws -> URL {
        let root = try libraryURL()
        var candidate = root.appendingPathComponent(name, isDirectory: true)
        var suffix = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = root.appendingPathComponent("\(name) \(suffix)", isDirectory: true)
            suffix += 1
        }
        return try candidate.ensuringDirectory()
    }

    private func makeManagedCopy(for id: UUID) -> Bool {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return false }
        let alert = NSAlert()
        alert.messageText = t("image.copy.title")
        alert.informativeText = t("image.copy.message")
        alert.addButton(withTitle: t("image.copy.action"))
        alert.addButton(withTitle: t("common.cancel"))
        guard alert.runModal() == .alertFirstButtonReturn else { return false }
        do {
            let source = tabs[index]
            let folder = try uniqueDocumentFolder(named: source.title)
            let destination = folder.appendingPathComponent(source.url.lastPathComponent)
            try source.markdown.write(to: destination, atomically: true, encoding: .utf8)
            var copy = source
            copy.url = destination
            copy.fingerprint = try fingerprint(for: destination)
            copy.isManaged = true
            copy.isDirty = false
            copy.hasExternalConflict = false
            tabs[index] = copy
            remember(destination)
            return true
        } catch {
            NSSound.beep()
            return false
        }
    }

    private func uniqueAssetURL(for source: URL, in directory: URL) -> URL {
        let base = source.deletingPathExtension().lastPathComponent
        let ext = source.pathExtension
        var candidate = directory.appendingPathComponent(source.lastPathComponent)
        var suffix = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(base)-\(suffix).\(ext)")
            suffix += 1
        }
        return candidate
    }

    private func remember(_ url: URL) {
        var paths = recentURLs.map(\.path).filter { $0 != url.path }
        paths.insert(url.path, at: 0)
        UserDefaults.standard.set(Array(paths.prefix(12)), forKey: Self.recentKey)
        objectWillChange.send()
    }

    private func localizedUntitledName() -> String {
        switch language { case .english: "Untitled"; case .russian: "Без названия"; case .spanish: "Sin título" }
    }

    private func localizedTemplateName(_ template: DocumentTemplate) -> String {
        switch (language, template) {
        case (.english, .blank): "Untitled"
        case (.russian, .blank): "Без названия"
        case (.spanish, .blank): "Sin título"
        case (.english, .meeting): "Meeting notes"
        case (.russian, .meeting): "Заметки встречи"
        case (.spanish, .meeting): "Notas de reunión"
        case (.english, .project): "Project plan"
        case (.russian, .project): "План проекта"
        case (.spanish, .project): "Plan del proyecto"
        }
    }

    private func templateDocument(_ template: DocumentTemplate) -> String {
        switch (language, template) {
        case (.english, .blank):
            "# Untitled\n\nStart writing…\n"
        case (.russian, .blank):
            "# Без названия\n\nНачните писать…\n"
        case (.spanish, .blank):
            "# Sin título\n\nEmpieza a escribir…\n"
        case (.english, .meeting):
            "# Meeting notes\n\n**Date:** \n**Participants:** \n\n## Agenda\n\n- \n\n## Notes\n\n\n## Decisions\n\n- [ ] \n\n## Next steps\n\n- [ ] Owner — action\n"
        case (.russian, .meeting):
            "# Заметки встречи\n\n**Дата:** \n**Участники:** \n\n## Повестка\n\n- \n\n## Заметки\n\n\n## Решения\n\n- [ ] \n\n## Следующие шаги\n\n- [ ] Ответственный — действие\n"
        case (.spanish, .meeting):
            "# Notas de reunión\n\n**Fecha:** \n**Participantes:** \n\n## Agenda\n\n- \n\n## Notas\n\n\n## Decisiones\n\n- [ ] \n\n## Próximos pasos\n\n- [ ] Responsable — acción\n"
        case (.english, .project):
            "# Project plan\n\n> One sentence describing the outcome.\n\n## Goal\n\n\n## Scope\n\n### Included\n\n- \n\n### Not included\n\n- \n\n## Milestones\n\n| Milestone | Owner | Date | Status |\n| --- | --- | --- | --- |\n| First milestone |  |  | Planned |\n\n## Risks\n\n- \n\n## Next actions\n\n- [ ] \n"
        case (.russian, .project):
            "# План проекта\n\n> Одним предложением опишите результат.\n\n## Цель\n\n\n## Объём\n\n### Входит\n\n- \n\n### Не входит\n\n- \n\n## Этапы\n\n| Этап | Ответственный | Срок | Статус |\n| --- | --- | --- | --- |\n| Первый этап |  |  | Запланирован |\n\n## Риски\n\n- \n\n## Следующие действия\n\n- [ ] \n"
        case (.spanish, .project):
            "# Plan del proyecto\n\n> Describe el resultado en una frase.\n\n## Objetivo\n\n\n## Alcance\n\n### Incluido\n\n- \n\n### No incluido\n\n- \n\n## Hitos\n\n| Hito | Responsable | Fecha | Estado |\n| --- | --- | --- | --- |\n| Primer hito |  |  | Planificado |\n\n## Riesgos\n\n- \n\n## Próximas acciones\n\n- [ ] \n"
        }
    }

    private func guideDocument() -> String {
        switch language {
        case .english:
            """
            # Welcome to MDore

            MDore lets Markdown feel like a normal document. Switch between **Edit** and **Read** without losing your place.

            ## The essentials

            Select text and use the quiet toolbar for headings, **bold**, *italic*, links, lists, tables, images, code, mathematics, and diagrams.

            - Changes save automatically
            - `⌘S` saves immediately
            - `⌘F` searches the document
            - Drag another `.md` file into the window to open a new tab

            ## Mathematics

            Use Insert → Math and write LaTeX such as: $E = mc^2$.

            ## Diagrams

            Use Insert → Mermaid diagram, then describe a flow in text.

            > Your files remain plain Markdown and belong to you.
            """
        case .russian:
            """
            # Знакомство с MDore

            MDore позволяет работать с Markdown как с обычным документом. Переключайтесь между **Редактированием** и **Чтением** — позиция останется на месте.

            ## Главное

            Выделите текст и используйте спокойную верхнюю панель: заголовки, **жирный**, *курсив*, ссылки, списки, таблицы, изображения, код, формулы и диаграммы.

            - Изменения сохраняются автоматически
            - `⌘S` сохраняет сразу
            - `⌘F` ищет по документу
            - Перетащите другой `.md` в окно — он откроется новой вкладкой

            ## Формулы

            Выберите «Вставить → Формула» и пишите LaTeX, например: $E = mc^2$.

            ## Диаграммы

            Выберите «Вставить → Диаграмма Mermaid», затем опишите схему текстом.

            > Файлы остаются обычным Markdown и принадлежат вам.
            """
        case .spanish:
            """
            # Bienvenido a MDore

            MDore hace que Markdown se sienta como un documento normal. Cambia entre **Editar** y **Leer** sin perder tu posición.

            ## Lo esencial

            Selecciona texto y usa la barra discreta para títulos, **negrita**, *cursiva*, enlaces, listas, tablas, imágenes, código, matemáticas y diagramas.

            - Los cambios se guardan automáticamente
            - `⌘S` guarda inmediatamente
            - `⌘F` busca en el documento
            - Arrastra otro archivo `.md` para abrir una pestaña nueva

            ## Matemáticas

            Usa Insertar → Fórmula y escribe LaTeX como: $E = mc^2$.

            ## Diagramas

            Usa Insertar → Diagrama Mermaid y describe el flujo con texto.

            > Tus archivos siguen siendo Markdown normal y te pertenecen.
            """
        }
    }

    func makeDefaultReader() {
        let markdown = UTType(importedAs: "net.daringfireball.markdown", conformingTo: .plainText)
        NSWorkspace.shared.setDefaultApplication(at: Bundle.main.bundleURL, toOpen: markdown) { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                if error == nil {
                    self.defaultReaderResult = self.language == .russian ? "MDore теперь открывает Markdown по умолчанию"
                        : self.language == .spanish ? "MDore ahora abre Markdown de forma predeterminada"
                        : "MDore now opens Markdown by default"
                } else {
                    self.defaultReaderResult = self.language == .russian ? "Выберите MDore через «Свойства файла»"
                        : self.language == .spanish ? "Selecciona MDore desde Obtener información"
                        : "Choose MDore from Get Info"
                }
            }
        }
    }
}

private extension URL {
    func ensuringDirectory() throws -> URL {
        try FileManager.default.createDirectory(at: self, withIntermediateDirectories: true)
        return self
    }
}

private extension String {
    var isDarkHex: Bool {
        let value = UInt64(dropFirst(), radix: 16) ?? 0
        let red = Double((value >> 16) & 255)
        let green = Double((value >> 8) & 255)
        let blue = Double(value & 255)
        return (red * 0.299 + green * 0.587 + blue * 0.114) < 138
    }
}
