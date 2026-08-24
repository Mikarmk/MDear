import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case russian = "ru"
    case spanish = "es"
    case japanese = "ja"
    case chinese = "zh"
    case german = "de"
    case french = "fr"
    case portuguese = "pt"
    case hindi = "hi"
    case arabic = "ar"
    case tatar = "tt"

    var id: String { rawValue }
    var title: String {
        switch self {
        case .english: "English"
        case .russian: "Русский"
        case .spanish: "Español"
        case .japanese: "日本語"
        case .chinese: "中文"
        case .german: "Deutsch"
        case .french: "Français"
        case .portuguese: "Português"
        case .hindi: "हिन्दी"
        case .arabic: "العربية"
        case .tatar: "Татарча"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .english: "en_US"; case .russian: "ru_RU"; case .spanish: "es_ES"
        case .japanese: "ja_JP"; case .chinese: "zh_CN"; case .german: "de_DE"
        case .french: "fr_FR"; case .portuguese: "pt_BR"; case .hindi: "hi_IN"
        case .arabic: "ar"; case .tatar: "tt_RU"
        }
    }

    static var systemDefault: AppLanguage {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return AppLanguage(rawValue: code) ?? .english
    }

    func text(_ key: String) -> String {
        Self.copy[key]?[self] ?? Self.extraCopy[self]?[key] ?? Self.supplementCopy[self]?[key] ?? Self.copy[key]?[.english] ?? key
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
        "home.create": [.english: "Create a document", .russian: "Создать документ", .spanish: "Crear un documento"],
        "home.template.blank": [.english: "New document", .russian: "Новый документ", .spanish: "Nuevo documento"],
        "home.template.meeting": [.english: "Meeting notes", .russian: "Заметки встречи", .spanish: "Notas de reunión"],
        "home.template.project": [.english: "Project plan", .russian: "План проекта", .spanish: "Plan del proyecto"],
        "home.template.brief": [.english: "Document brief", .russian: "Описание документа", .spanish: "Resumen del documento"],
        "home.column.name": [.english: "Name", .russian: "Название", .spanish: "Nombre"],
        "home.column.folder": [.english: "Folder", .russian: "Папка", .spanish: "Carpeta"],
        "home.column.modified": [.english: "Modified", .russian: "Изменён", .spanish: "Modificado"],
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

    private static let extraCopy: [AppLanguage: [String: String]] = [
        .japanese: ["home.new":"新規文書", "home.open":"開く…", "home.recent":"最近の文書", "home.guide":"MDoreへようこそ", "home.empty":"最近の文書がここに表示されます", "home.drop":"Markdownファイルをここにドロップ", "home.create":"文書を作成", "home.template.blank":"新規文書", "home.template.meeting":"会議メモ", "home.template.project":"プロジェクト計画", "home.template.brief":"文書概要", "home.column.name":"名前", "home.column.folder":"フォルダ", "home.column.modified":"更新日", "common.settings":"設定", "common.save":"保存", "common.cancel":"キャンセル", "common.done":"完了", "common.rename":"名前を変更…", "common.close":"閉じる", "editor.edit":"編集", "editor.read":"閲覧", "editor.saved":"保存済み", "editor.saving":"保存中…", "editor.conflict":"別の場所で変更されました", "editor.style":"スタイル", "editor.insert":"挿入", "editor.paragraph":"本文", "editor.heading":"見出し", "editor.quote":"引用", "editor.codeBlock":"コードブロック", "editor.math":"数式 / LaTeX", "editor.diagram":"Mermaid図", "editor.table":"表", "editor.image":"画像", "editor.link":"リンク", "editor.divider":"区切り線", "editor.task":"タスクリスト", "settings.title":"外観", "settings.language":"言語", "settings.theme":"テーマ", "settings.accent":"アクセント", "settings.background":"用紙の色", "settings.photo":"背景画像", "settings.photo.choose":"画像を選択…", "settings.photo.remove":"画像を削除", "settings.width":"本文の幅", "settings.focus":"集中モード", "settings.typewriter":"タイプライターモード", "settings.lineNumbers":"コードの行番号", "settings.default":"Markdownの既定アプリ", "settings.default.action":"MDoreに設定", "sidebar.outline":"アウトライン", "sidebar.files":"ファイル", "search.placeholder":"文書内を検索"],
        .chinese: ["home.new":"新建文档", "home.open":"打开…", "home.recent":"最近文档", "home.guide":"欢迎使用 MDore", "home.empty":"最近的文档会显示在这里", "home.drop":"将 Markdown 文件拖到任意位置", "home.create":"创建文档", "home.template.blank":"新建文档", "home.template.meeting":"会议记录", "home.template.project":"项目计划", "home.template.brief":"文档简述", "home.column.name":"名称", "home.column.folder":"文件夹", "home.column.modified":"修改时间", "common.settings":"设置", "common.save":"保存", "common.cancel":"取消", "common.done":"完成", "common.rename":"重命名…", "common.close":"关闭", "editor.edit":"编辑", "editor.read":"阅读", "editor.saved":"已保存", "editor.saving":"正在保存…", "editor.conflict":"已在其他位置修改", "editor.style":"样式", "editor.insert":"插入", "editor.paragraph":"正文", "editor.heading":"标题", "editor.quote":"引用", "editor.codeBlock":"代码块", "editor.math":"数学 / LaTeX", "editor.diagram":"Mermaid 图表", "editor.table":"表格", "editor.image":"图片", "editor.link":"链接", "editor.divider":"分隔线", "editor.task":"任务列表", "settings.title":"外观", "settings.language":"语言", "settings.theme":"主题", "settings.accent":"强调色", "settings.background":"纸张颜色", "settings.photo":"背景图片", "settings.photo.choose":"选择图片…", "settings.photo.remove":"移除图片", "settings.width":"文本宽度", "settings.focus":"专注模式", "settings.typewriter":"打字机模式", "settings.lineNumbers":"代码行号", "settings.default":"默认 Markdown 应用", "settings.default.action":"设为 MDore", "sidebar.outline":"大纲", "sidebar.files":"文件", "search.placeholder":"在文档中查找"],
        .german: ["home.new":"Neues Dokument", "home.open":"Öffnen…", "home.recent":"Zuletzt verwendet", "home.guide":"Willkommen bei MDore", "home.empty":"Zuletzt verwendete Dokumente erscheinen hier", "home.drop":"Markdown-Datei hier ablegen", "home.create":"Dokument erstellen", "home.template.blank":"Neues Dokument", "home.template.meeting":"Besprechungsnotizen", "home.template.project":"Projektplan", "home.template.brief":"Dokument-Briefing", "home.column.name":"Name", "home.column.folder":"Ordner", "home.column.modified":"Geändert", "common.settings":"Einstellungen", "common.save":"Sichern", "common.cancel":"Abbrechen", "common.done":"Fertig", "common.rename":"Umbenennen…", "common.close":"Schließen", "editor.edit":"Bearbeiten", "editor.read":"Lesen", "editor.saved":"Gesichert", "editor.saving":"Wird gesichert…", "editor.conflict":"Anderswo geändert", "editor.style":"Stil", "editor.insert":"Einfügen", "editor.paragraph":"Absatz", "editor.heading":"Überschrift", "editor.quote":"Zitat", "editor.codeBlock":"Codeblock", "editor.math":"Mathematik / LaTeX", "editor.diagram":"Mermaid-Diagramm", "editor.table":"Tabelle", "editor.image":"Bild", "editor.link":"Link", "editor.divider":"Trennlinie", "editor.task":"Aufgabenliste", "settings.title":"Darstellung", "settings.language":"Sprache", "settings.theme":"Thema", "settings.accent":"Akzent", "settings.background":"Papierfarbe", "settings.photo":"Hintergrundbild", "settings.photo.choose":"Bild auswählen…", "settings.photo.remove":"Bild entfernen", "settings.width":"Textbreite", "settings.focus":"Fokusmodus", "settings.typewriter":"Schreibmaschinenmodus", "settings.lineNumbers":"Code-Zeilennummern", "settings.default":"Standard-App für Markdown", "settings.default.action":"MDore festlegen", "sidebar.outline":"Gliederung", "sidebar.files":"Dateien", "search.placeholder":"Im Dokument suchen"],
        .french: ["home.new":"Nouveau document", "home.open":"Ouvrir…", "home.recent":"Documents récents", "home.guide":"Bienvenue dans MDore", "home.empty":"Vos documents récents apparaîtront ici", "home.drop":"Déposez un fichier Markdown n’importe où", "home.create":"Créer un document", "home.template.blank":"Nouveau document", "home.template.meeting":"Notes de réunion", "home.template.project":"Plan de projet", "home.template.brief":"Brief du document", "home.column.name":"Nom", "home.column.folder":"Dossier", "home.column.modified":"Modifié", "common.settings":"Réglages", "common.save":"Enregistrer", "common.cancel":"Annuler", "common.done":"Terminé", "common.rename":"Renommer…", "common.close":"Fermer", "editor.edit":"Modifier", "editor.read":"Lire", "editor.saved":"Enregistré", "editor.saving":"Enregistrement…", "editor.conflict":"Modifié ailleurs", "editor.style":"Style", "editor.insert":"Insérer", "editor.paragraph":"Paragraphe", "editor.heading":"Titre", "editor.quote":"Citation", "editor.codeBlock":"Bloc de code", "editor.math":"Maths / LaTeX", "editor.diagram":"Diagramme Mermaid", "editor.table":"Tableau", "editor.image":"Image", "editor.link":"Lien", "editor.divider":"Séparateur", "editor.task":"Liste de tâches", "settings.title":"Apparence", "settings.language":"Langue", "settings.theme":"Thème", "settings.accent":"Accent", "settings.background":"Couleur du papier", "settings.photo":"Photo d’arrière-plan", "settings.photo.choose":"Choisir une photo…", "settings.photo.remove":"Supprimer la photo", "settings.width":"Largeur du texte", "settings.focus":"Mode concentration", "settings.typewriter":"Mode machine à écrire", "settings.lineNumbers":"Numéros de ligne du code", "settings.default":"App Markdown par défaut", "settings.default.action":"Choisir MDore", "sidebar.outline":"Plan", "sidebar.files":"Fichiers", "search.placeholder":"Rechercher dans le document"],
        .portuguese: ["home.new":"Novo documento", "home.open":"Abrir…", "home.recent":"Documentos recentes", "home.guide":"Boas-vindas ao MDore", "home.empty":"Seus documentos recentes aparecerão aqui", "home.drop":"Solte um arquivo Markdown em qualquer lugar", "home.create":"Criar documento", "home.template.blank":"Novo documento", "home.template.meeting":"Notas da reunião", "home.template.project":"Plano do projeto", "home.template.brief":"Resumo do documento", "home.column.name":"Nome", "home.column.folder":"Pasta", "home.column.modified":"Modificado", "common.settings":"Ajustes", "common.save":"Salvar", "common.cancel":"Cancelar", "common.done":"Concluído", "common.rename":"Renomear…", "common.close":"Fechar", "editor.edit":"Editar", "editor.read":"Ler", "editor.saved":"Salvo", "editor.saving":"Salvando…", "editor.conflict":"Alterado em outro lugar", "editor.style":"Estilo", "editor.insert":"Inserir", "editor.paragraph":"Parágrafo", "editor.heading":"Título", "editor.quote":"Citação", "editor.codeBlock":"Bloco de código", "editor.math":"Matemática / LaTeX", "editor.diagram":"Diagrama Mermaid", "editor.table":"Tabela", "editor.image":"Imagem", "editor.link":"Link", "editor.divider":"Separador", "editor.task":"Lista de tarefas", "settings.title":"Aparência", "settings.language":"Idioma", "settings.theme":"Tema", "settings.accent":"Destaque", "settings.background":"Cor do papel", "settings.photo":"Foto de fundo", "settings.photo.choose":"Escolher foto…", "settings.photo.remove":"Remover foto", "settings.width":"Largura do texto", "settings.focus":"Modo foco", "settings.typewriter":"Modo máquina de escrever", "settings.lineNumbers":"Números de linha no código", "settings.default":"App Markdown padrão", "settings.default.action":"Definir MDore", "sidebar.outline":"Estrutura", "sidebar.files":"Arquivos", "search.placeholder":"Buscar no documento"],
        .hindi: ["home.new":"नया दस्तावेज़", "home.open":"खोलें…", "home.recent":"हाल के दस्तावेज़", "home.guide":"MDore में आपका स्वागत है", "home.empty":"आपके हाल के दस्तावेज़ यहाँ दिखेंगे", "home.drop":"Markdown फ़ाइल कहीं भी छोड़ें", "home.create":"दस्तावेज़ बनाएँ", "home.template.blank":"नया दस्तावेज़", "home.template.meeting":"बैठक नोट्स", "home.template.project":"परियोजना योजना", "home.template.brief":"दस्तावेज़ सार", "home.column.name":"नाम", "home.column.folder":"फ़ोल्डर", "home.column.modified":"संशोधित", "common.settings":"सेटिंग्स", "common.save":"सहेजें", "common.cancel":"रद्द करें", "common.done":"पूर्ण", "common.rename":"नाम बदलें…", "common.close":"बंद करें", "editor.edit":"संपादित करें", "editor.read":"पढ़ें", "editor.saved":"सहेजा गया", "editor.saving":"सहेजा जा रहा है…", "editor.conflict":"कहीं और बदला गया", "editor.style":"शैली", "editor.insert":"जोड़ें", "editor.paragraph":"अनुच्छेद", "editor.heading":"शीर्षक", "editor.quote":"उद्धरण", "editor.codeBlock":"कोड ब्लॉक", "editor.math":"गणित / LaTeX", "editor.diagram":"Mermaid आरेख", "editor.table":"तालिका", "editor.image":"चित्र", "editor.link":"लिंक", "editor.divider":"विभाजक", "editor.task":"कार्य सूची", "settings.title":"रूप", "settings.language":"भाषा", "settings.theme":"थीम", "settings.accent":"प्रमुख रंग", "settings.background":"कागज़ का रंग", "settings.photo":"पृष्ठभूमि चित्र", "settings.photo.choose":"चित्र चुनें…", "settings.photo.remove":"चित्र हटाएँ", "settings.width":"पाठ की चौड़ाई", "settings.focus":"फ़ोकस मोड", "settings.typewriter":"टाइपराइटर मोड", "settings.lineNumbers":"कोड पंक्ति संख्या", "settings.default":"डिफ़ॉल्ट Markdown ऐप", "settings.default.action":"MDore सेट करें", "sidebar.outline":"रूपरेखा", "sidebar.files":"फ़ाइलें", "search.placeholder":"दस्तावेज़ में खोजें"],
        .arabic: ["home.new":"مستند جديد", "home.open":"فتح…", "home.recent":"المستندات الأخيرة", "home.guide":"مرحبًا بك في MDore", "home.empty":"ستظهر مستنداتك الأخيرة هنا", "home.drop":"أفلت ملف Markdown في أي مكان", "home.create":"إنشاء مستند", "home.template.blank":"مستند جديد", "home.template.meeting":"ملاحظات الاجتماع", "home.template.project":"خطة المشروع", "home.template.brief":"ملخص المستند", "home.column.name":"الاسم", "home.column.folder":"المجلد", "home.column.modified":"عُدّل", "common.settings":"الإعدادات", "common.save":"حفظ", "common.cancel":"إلغاء", "common.done":"تم", "common.rename":"إعادة تسمية…", "common.close":"إغلاق", "editor.edit":"تحرير", "editor.read":"قراءة", "editor.saved":"تم الحفظ", "editor.saving":"جارٍ الحفظ…", "editor.conflict":"عُدّل في مكان آخر", "editor.style":"النمط", "editor.insert":"إدراج", "editor.paragraph":"فقرة", "editor.heading":"عنوان", "editor.quote":"اقتباس", "editor.codeBlock":"كتلة تعليمات برمجية", "editor.math":"رياضيات / LaTeX", "editor.diagram":"مخطط Mermaid", "editor.table":"جدول", "editor.image":"صورة", "editor.link":"رابط", "editor.divider":"فاصل", "editor.task":"قائمة مهام", "settings.title":"المظهر", "settings.language":"اللغة", "settings.theme":"السمة", "settings.accent":"اللون المميز", "settings.background":"لون الورق", "settings.photo":"صورة الخلفية", "settings.photo.choose":"اختيار صورة…", "settings.photo.remove":"إزالة الصورة", "settings.width":"عرض النص", "settings.focus":"وضع التركيز", "settings.typewriter":"وضع الآلة الكاتبة", "settings.lineNumbers":"أرقام أسطر الكود", "settings.default":"تطبيق Markdown الافتراضي", "settings.default.action":"تعيين MDore", "sidebar.outline":"المخطط", "sidebar.files":"الملفات", "search.placeholder":"بحث في المستند"],
        .tatar: ["home.new":"Яңа документ", "home.open":"Ачу…", "home.recent":"Соңгы документлар", "home.guide":"MDore-га рәхим итегез", "home.empty":"Соңгы документлар монда күренәчәк", "home.drop":"Markdown файлын теләсә кайда ташлагыз", "home.create":"Документ төзү", "home.template.blank":"Яңа документ", "home.template.meeting":"Очрашу язмалары", "home.template.project":"Проект планы", "home.template.brief":"Документ тасвирламасы", "home.column.name":"Исем", "home.column.folder":"Папка", "home.column.modified":"Үзгәртелде", "common.settings":"Көйләүләр", "common.save":"Саклау", "common.cancel":"Баш тарту", "common.done":"Әзер", "common.rename":"Исемен үзгәртү…", "common.close":"Ябу", "editor.edit":"Үзгәртү", "editor.read":"Уку", "editor.saved":"Сакланды", "editor.saving":"Саклана…", "editor.conflict":"Башка урында үзгәртелде", "editor.style":"Стиль", "editor.insert":"Кую", "editor.paragraph":"Абзац", "editor.heading":"Башлык", "editor.quote":"Өземтә", "editor.codeBlock":"Код блогы", "editor.math":"Математика / LaTeX", "editor.diagram":"Mermaid диаграммасы", "editor.table":"Таблица", "editor.image":"Рәсем", "editor.link":"Сылтама", "editor.divider":"Аергыч", "editor.task":"Биремнәр исемлеге", "settings.title":"Бизәлеш", "settings.language":"Тел", "settings.theme":"Тема", "settings.accent":"Акцент", "settings.background":"Кәгазь төсе", "settings.photo":"Фон рәсеме", "settings.photo.choose":"Рәсем сайлау…", "settings.photo.remove":"Рәсемне бетерү", "settings.width":"Текст киңлеге", "settings.focus":"Фокус режимы", "settings.typewriter":"Басу машинасы режимы", "settings.lineNumbers":"Код юллары саннары", "settings.default":"Markdown өчен төп кушымта", "settings.default.action":"MDore итеп билгеләү", "sidebar.outline":"Эчтәлек", "sidebar.files":"Файллар", "search.placeholder":"Документта эзләү"]
    ]

    private static let supplementCopy: [AppLanguage: [String: String]] = [
        .japanese: ["home.subtitle":"Markdownを普通の文書のように書く", "home.guide.detail":"短い操作ガイド", "image.copy.title":"文書を持ち運べるようにしますか？", "image.copy.message":"MDoreライブラリにコピーし、画像を隣のassetsフォルダに保存します。", "image.copy.action":"管理コピーを作成"],
        .chinese: ["home.subtitle":"像普通文档一样编写 Markdown", "home.guide.detail":"简短使用指南", "image.copy.title":"保持文档便于移动？", "image.copy.message":"MDore 会在资料库中创建副本，并把图片保存在旁边的 assets 文件夹。", "image.copy.action":"创建托管副本"],
        .german: ["home.subtitle":"Markdown wie ein Dokument schreiben", "home.guide.detail":"Eine kurze Einführung", "image.copy.title":"Dokument portabel halten?", "image.copy.message":"MDore erstellt eine Kopie in der Mediathek und speichert Bilder daneben im assets-Ordner.", "image.copy.action":"Verwaltete Kopie erstellen"],
        .french: ["home.subtitle":"Écrire en Markdown comme dans un document", "home.guide.detail":"Un guide de prise en main", "image.copy.title":"Garder le document portable ?", "image.copy.message":"MDore crée une copie dans sa bibliothèque et conserve les images dans le dossier assets.", "image.copy.action":"Créer une copie gérée"],
        .portuguese: ["home.subtitle":"Escreva Markdown como um documento", "home.guide.detail":"Um guia rápido", "image.copy.title":"Manter o documento portátil?", "image.copy.message":"O MDore criará uma cópia na biblioteca e manterá as imagens na pasta assets.", "image.copy.action":"Criar cópia gerenciada"],
        .hindi: ["home.subtitle":"Markdown को सामान्य दस्तावेज़ की तरह लिखें", "home.guide.detail":"एक छोटा परिचय", "image.copy.title":"दस्तावेज़ को पोर्टेबल रखें?", "image.copy.message":"MDore लाइब्रेरी में एक प्रति बनाएगा और चित्रों को assets फ़ोल्डर में रखेगा।", "image.copy.action":"प्रबंधित प्रति बनाएँ"],
        .arabic: ["home.subtitle":"اكتب Markdown كمستند عادي", "home.guide.detail":"دليل سريع", "image.copy.title":"هل تريد إبقاء المستند قابلًا للنقل؟", "image.copy.message":"سينشئ MDore نسخة في مكتبته ويحفظ الصور في مجلد assets.", "image.copy.action":"إنشاء نسخة مُدارة"],
        .tatar: ["home.subtitle":"Markdown-ны гадәти документ кебек языгыз", "home.guide.detail":"Кыскача кулланма", "image.copy.title":"Документны күчереп йөртү уңайлы булсынмы?", "image.copy.message":"MDore үз китапханәсендә күчермә ясаячак һәм рәсемнәрне assets папкасында саклаячак.", "image.copy.action":"Идарә ителә торган күчермә ясау"]
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
