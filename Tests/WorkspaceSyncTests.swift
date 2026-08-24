import Foundation

@main
struct WorkspaceSyncTests {
    @MainActor
    static func main() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("mdore-sync-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let file = directory.appendingPathComponent("live.md")
        try "# Первая версия\n\nТекст".write(to: file, atomically: true, encoding: .utf8)

        let workspace = ReaderWorkspace()
        workspace.open(file)
        guard let original = workspace.selectedTab else { fatalError("Документ не открылся") }

        try "# Вторая версия\n\nОбновлённый текст".write(to: file, atomically: true, encoding: .utf8)
        workspace.refreshSelected()

        guard let refreshed = workspace.selectedTab else { fatalError("Вкладка исчезла") }
        precondition(refreshed.id == original.id, "Синхронизация не должна заменять вкладку")
        precondition(refreshed.markdown.contains("Вторая версия"), "Новая версия файла не загружена")
        precondition(refreshed.isAvailable, "Доступный файл ошибочно отмечен недоступным")
        precondition(workspace.syncRevision == 1, "Ручное обновление должно подтверждаться интерфейсу")

        try "# Третья версия\n\nАвтоматически синхронизировано".write(to: file, atomically: true, encoding: .utf8)
        try await Task.sleep(for: .milliseconds(1_100))
        precondition(workspace.selectedTab?.markdown.contains("Третья версия") == true,
                     "Автоматическая синхронизация не заметила изменение файла")
        precondition(workspace.syncRevision == 2, "Автоматическое обновление должно подтверждаться интерфейсу")

        print("Workspace sync tests passed")
    }
}
