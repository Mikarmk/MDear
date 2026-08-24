import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case russian = "ru"
    case spanish = "es"

    var id: String { rawValue }
    var title: String {
        switch self {
        case .english: "English"
        case .russian: "Русский"
        case .spanish: "Español"
        }
    }

    static var systemDefault: AppLanguage {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return AppLanguage(rawValue: code) ?? .english
    }

    func text(_ key: String) -> String {
        Self.copy[key]?[self] ?? Self.copy[key]?[.english] ?? key
    }

    private static let copy: [String: [AppLanguage: String]] = [
        "home.subtitle": [.english: "Write Markdown like a document", .russian: "Пишите Markdown как обычный документ", .spanish: "Escribe Markdown como un documento"],
        "home.new": [.english: "New document", .russian: "Новый документ", .spanish: "Nuevo documento"],
        "home.open": [.english: "Open…", .russian: "Открыть…", .spanish: "Abrir…"],
        "home.recent": [.english: "Recent documents", .russian: "Недавние документы", .spanish: "Documentos recientes"],
        "home.guide": [.english: "Welcome to MDore", .russian: "Знакомство с MDore", .spanish: "Bienvenido a MDore"],
        "home.guide.detail": [.english: "A short interactive guide", .russian: "Короткая интерактивная инструкция", .spanish: "Una guía interactiva breve"],
        "home.empty": [.english: "Your recent documents will appear here", .russian: "Здесь появятся недавние документы", .spanish: "Tus documentos recientes aparecerán aquí"],
        "home.drop": [.english: "Drop a Markdown file anywhere", .russian: "Перетащите Markdown в любое место", .spanish: "Suelta un archivo Markdown en cualquier lugar"],
        "common.settings": [.english: "Settings", .russian: "Настройки", .spanish: "Ajustes"],
        "common.save": [.english: "Save", .russian: "Сохранить", .spanish: "Guardar"],
        "common.cancel": [.english: "Cancel", .russian: "Отмена", .spanish: "Cancelar"],
        "common.done": [.english: "Done", .russian: "Готово", .spanish: "Listo"],
        "common.rename": [.english: "Rename…", .russian: "Переименовать…", .spanish: "Renombrar…"],
        "common.close": [.english: "Close", .russian: "Закрыть", .spanish: "Cerrar"],
        "editor.edit": [.english: "Edit", .russian: "Редактировать", .spanish: "Editar"],
        "editor.read": [.english: "Read", .russian: "Читать", .spanish: "Leer"],
        "editor.saved": [.english: "Saved", .russian: "Сохранено", .spanish: "Guardado"],
        "editor.saving": [.english: "Saving…", .russian: "Сохранение…", .spanish: "Guardando…"],
        "editor.conflict": [.english: "Changed elsewhere", .russian: "Изменён в другом месте", .spanish: "Modificado en otro lugar"],
        "editor.style": [.english: "Style", .russian: "Стиль", .spanish: "Estilo"],
        "editor.insert": [.english: "Insert", .russian: "Вставить", .spanish: "Insertar"],
        "editor.paragraph": [.english: "Paragraph", .russian: "Обычный текст", .spanish: "Párrafo"],
        "editor.heading": [.english: "Heading", .russian: "Заголовок", .spanish: "Título"],
        "editor.quote": [.english: "Quote", .russian: "Цитата", .spanish: "Cita"],
        "editor.codeBlock": [.english: "Code block", .russian: "Блок кода", .spanish: "Bloque de código"],
        "editor.math": [.english: "Math / LaTeX", .russian: "Формула / LaTeX", .spanish: "Fórmula / LaTeX"],
        "editor.diagram": [.english: "Mermaid diagram", .russian: "Диаграмма Mermaid", .spanish: "Diagrama Mermaid"],
        "editor.table": [.english: "Table", .russian: "Таблица", .spanish: "Tabla"],
        "editor.image": [.english: "Image", .russian: "Изображение", .spanish: "Imagen"],
        "editor.link": [.english: "Link", .russian: "Ссылка", .spanish: "Enlace"],
        "editor.divider": [.english: "Divider", .russian: "Разделитель", .spanish: "Separador"],
        "editor.task": [.english: "Task list", .russian: "Список задач", .spanish: "Lista de tareas"],
        "settings.title": [.english: "Appearance", .russian: "Оформление", .spanish: "Apariencia"],
        "settings.language": [.english: "Language", .russian: "Язык", .spanish: "Idioma"],
        "settings.theme": [.english: "Theme", .russian: "Тема", .spanish: "Tema"],
        "settings.accent": [.english: "Accent", .russian: "Акцент", .spanish: "Acento"],
        "settings.background": [.english: "Paper color", .russian: "Цвет листа", .spanish: "Color del papel"],
        "settings.photo": [.english: "Background photo", .russian: "Фото на фоне", .spanish: "Foto de fondo"],
        "settings.photo.choose": [.english: "Choose photo…", .russian: "Выбрать фото…", .spanish: "Elegir foto…"],
        "settings.photo.remove": [.english: "Remove photo", .russian: "Убрать фото", .spanish: "Quitar foto"],
        "settings.width": [.english: "Text width", .russian: "Ширина текста", .spanish: "Ancho del texto"],
        "settings.focus": [.english: "Focus mode", .russian: "Режим фокуса", .spanish: "Modo de enfoque"],
        "settings.typewriter": [.english: "Typewriter mode", .russian: "Режим печатной машинки", .spanish: "Modo máquina de escribir"],
        "settings.lineNumbers": [.english: "Code line numbers", .russian: "Номера строк в коде", .spanish: "Números de línea en código"],
        "settings.default": [.english: "Default Markdown app", .russian: "Основное приложение для Markdown", .spanish: "Aplicación Markdown predeterminada"],
        "settings.default.action": [.english: "Set MDore", .russian: "Назначить MDore", .spanish: "Usar MDore"],
        "sidebar.outline": [.english: "Outline", .russian: "Структура", .spanish: "Esquema"],
        "sidebar.files": [.english: "Files", .russian: "Файлы", .spanish: "Archivos"],
        "image.copy.title": [.english: "Keep the document portable?", .russian: "Сохранить документ переносимым?", .spanish: "¿Mantener el documento portátil?"],
        "image.copy.message": [.english: "MDore will create a copy in its library and keep images beside it in an assets folder.", .russian: "MDore создаст копию в своей библиотеке и будет хранить изображения рядом, в папке assets.", .spanish: "MDore creará una copia en su biblioteca y guardará las imágenes en una carpeta assets."],
        "image.copy.action": [.english: "Create managed copy", .russian: "Создать копию", .spanish: "Crear copia administrada"],
        "search.placeholder": [.english: "Find in document", .russian: "Найти в документе", .spanish: "Buscar en el documento"]
    ]
}

enum EditorAction: Equatable {
    case paragraph
    case heading(Int)
    case bold
    case italic
    case strike
    case inlineCode
    case highlight
    case underline
    case superscript
    case subscriptStyle
    case unorderedList
    case orderedList
    case taskList
    case quote
    case codeFence(String)
    case table(rows: Int, columns: Int)
    case tableOperation(String)
    case math
    case diagram
    case divider
    case link(String)
    case image(path: String, alt: String)
    case imageScale(Int)
    case jumpToHeading(String)
    case exportPDF
    case exportHTML
    case undo
    case redo
}

struct EditorCommand: Equatable {
    let id = UUID()
    let action: EditorAction
}
