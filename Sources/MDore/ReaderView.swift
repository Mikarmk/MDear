import SwiftUI
import UniformTypeIdentifiers

struct ReaderView: View {
    @EnvironmentObject private var workspace: ReaderWorkspace
    @State private var isTargeted = false
    @State private var chromeVisible = true
    @State private var showThemePicker = false
    @State private var scrollMonitor: Any?
    @FocusState private var searchFocused: Bool

    private var palette: ThemePalette { workspace.palette }

    var body: some View {
        ZStack {
            Color(hex: palette.bg).ignoresSafeArea()
            if let tab = workspace.selectedTab {
                MarkdownWebView(
                    markdown: tab.markdown, documentID: tab.id, baseURL: tab.url.deletingLastPathComponent(),
                    theme: workspace.theme, palette: palette, textScale: workspace.textScale,
                    pageWidth: workspace.pageWidth, backgroundImageURL: workspace.backgroundImageURL,
                    isEditing: workspace.editorMode == .edit, focusMode: workspace.focusMode,
                    typewriterMode: workspace.typewriterMode, showCodeLineNumbers: workspace.showCodeLineNumbers,
                    command: workspace.editorCommand,
                    searchQuery: workspace.searchQuery, findRevision: workspace.findRevision,
                    onChange: { workspace.updateMarkdown($0, for: tab.id) }, onScroll: hideChrome,
                    onOpenLink: workspace.followLink,
                    onDropFiles: { urls in handleDroppedURLs(urls) }
                )
                .id(tab.id)
                .transition(.opacity.combined(with: .scale(scale: 0.997)))
            } else {
                HomeView().environmentObject(workspace)
            }

            if isTargeted {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color(hex: palette.accent), style: StrokeStyle(lineWidth: 2, dash: [8, 7]))
                    .background(Color(hex: palette.accent).opacity(0.055))
                    .padding(14).allowsHitTesting(false)
            }
        }
        .overlay(alignment: .top) { if workspace.selectedTab != nil { chrome } }
        .overlay(alignment: .topTrailing) { searchPanel }
        .overlay(alignment: .trailing) {
            if workspace.selectedTab != nil, workspace.isSidebarPresented {
                DocumentSidebar().environmentObject(workspace)
                    .padding(.top, workspace.editorMode == .edit ? 92 : 50)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottomTrailing) { if let tab = workspace.selectedTab { documentStats(tab) } }
        .onContinuousHover { phase in if case .active = phase { revealChrome() } }
        .onTapGesture { revealChrome() }
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isTargeted, perform: acceptDrop)
        .sheet(isPresented: $workspace.isSettingsPresented) { SettingsView().environmentObject(workspace) }
        .onChange(of: workspace.isSearchPresented) { _, presented in
            if presented { revealChrome(); searchFocused = true }
        }
        .onAppear {
            FileOpenRouter.shared.handler = { urls in urls.forEach(workspace.open) }
            scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                Task { @MainActor in hideChrome() }
                return event
            }
        }
        .onDisappear {
            FileOpenRouter.shared.handler = nil
            if let scrollMonitor { NSEvent.removeMonitor(scrollMonitor) }
            scrollMonitor = nil
        }
        .animation(.easeOut(duration: 0.2), value: workspace.selectedID)
    }

    private var chrome: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button { workspace.showHome() } label: { Image(systemName: "square.grid.2x2") }
                    .help("MDore")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(workspace.tabs) { tab in tabButton(tab) }
                        Button(action: workspace.chooseFiles) { Image(systemName: "plus").frame(width: 28, height: 28) }
                            .help(workspace.t("home.open"))
                    }
                }
                Spacer(minLength: 8)
                saveIndicator
                Picker("", selection: $workspace.editorMode) {
                    Text(workspace.t("editor.edit")).tag(EditorMode.edit)
                    Text(workspace.t("editor.read")).tag(EditorMode.read)
                }
                .pickerStyle(.segmented).frame(width: 150)
                Button { workspace.showSearch() } label: { Image(systemName: "magnifyingglass") }.help("⌘F")
                Button { showThemePicker.toggle() } label: { Image(systemName: "circle.lefthalf.filled") }
                    .help(workspace.t("settings.theme"))
                    .popover(isPresented: $showThemePicker, arrowEdge: .top) { themePicker }
                Button { workspace.isSettingsPresented = true } label: { Image(systemName: "slider.horizontal.3") }
                    .help(workspace.t("common.settings"))
                Button { withAnimation { workspace.isSidebarPresented.toggle() } } label: { Image(systemName: "sidebar.right") }
                    .help(workspace.t("sidebar.outline"))
                Button { NSApp.keyWindow?.toggleFullScreen(nil) } label: { Image(systemName: "arrow.up.left.and.arrow.down.right") }
                    .help("⌘⇧R")
            }
            .buttonStyle(ChromeButtonStyle(color: Color(hex: palette.muted)))
            .padding(.leading, 78).padding(.trailing, 12).frame(height: 50)

            if workspace.editorMode == .edit {
                EditorToolbar().environmentObject(workspace)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color(hex: palette.chrome).opacity(0.97))
        .overlay(alignment: .bottom) { Rectangle().fill(Color(hex: palette.line)).frame(height: 1) }
        .offset(y: chromeVisible ? 0 : -20).opacity(chromeVisible ? 1 : 0)
        .allowsHitTesting(chromeVisible).animation(.easeOut(duration: 0.22), value: chromeVisible)
        .animation(.easeOut(duration: 0.18), value: workspace.editorMode)
    }

    private var saveIndicator: some View {
        Button {
            if workspace.saveState == .conflict { workspace.resolveSelectedConflict() }
            else { workspace.saveSelected() }
        } label: {
            HStack(spacing: 5) {
                Circle().fill(saveColor).frame(width: 6, height: 6)
                Text(saveText).font(.system(size: 11.5)).foregroundStyle(Color(hex: palette.muted))
            }.frame(minWidth: 76, alignment: .trailing)
        }.buttonStyle(.plain)
    }

    private var saveColor: Color {
        switch workspace.saveState {
        case .saved: Color(hex: palette.accent)
        case .saving: .secondary
        case .conflict, .unavailable: .orange
        }
    }

    private var saveText: String {
        switch workspace.saveState {
        case .saved: workspace.t("editor.saved")
        case .saving: workspace.t("editor.saving")
        case .conflict, .unavailable: workspace.t("editor.conflict")
        }
    }

    private func tabButton(_ tab: MarkdownTab) -> some View {
        let selected = workspace.selectedID == tab.id
        return HStack(spacing: 7) {
            Text(tab.title).lineLimit(1)
            if tab.isDirty { Circle().fill(Color(hex: palette.accent)).frame(width: 5, height: 5) }
            if selected {
                Button { workspace.close(tab.id) } label: { Image(systemName: "xmark").font(.system(size: 9, weight: .bold)) }
                    .buttonStyle(.plain)
            }
        }
        .font(.system(size: 12.5, weight: selected ? .semibold : .regular))
        .foregroundStyle(Color(hex: selected ? palette.text : palette.muted))
        .padding(.horizontal, 11).frame(height: 32)
        .background(selected ? Color(hex: palette.bg) : Color.clear, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .contentShape(Rectangle()).onTapGesture { workspace.selectedID = tab.id; revealChrome() }
        .contextMenu {
            Button(workspace.t("common.rename")) { workspace.rename(tab.id) }
            Button(workspace.t("common.close")) { workspace.close(tab.id) }
        }
    }

    @ViewBuilder private var searchPanel: some View {
        if workspace.isSearchPresented {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(Color(hex: palette.muted))
                TextField(workspace.t("search.placeholder"), text: $workspace.searchQuery).textFieldStyle(.plain)
                    .focused($searchFocused).onSubmit { workspace.findNext() }
                Button { workspace.findNext(backwards: true) } label: { Image(systemName: "chevron.up") }
                Button { workspace.findNext() } label: { Image(systemName: "chevron.down") }
                Button { workspace.hideSearch() } label: { Image(systemName: "xmark") }
            }
            .buttonStyle(ChromeButtonStyle(color: Color(hex: palette.muted))).font(.system(size: 13))
            .foregroundStyle(Color(hex: palette.text)).padding(.horizontal, 12).frame(width: 330, height: 42)
            .background(Color(hex: palette.chrome), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: palette.line)))
            .shadow(color: .black.opacity(0.12), radius: 18, y: 8).padding(.top, workspace.editorMode == .edit ? 102 : 58).padding(.trailing, 14)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var themePicker: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(workspace.t("settings.theme")).font(.system(size: 13, weight: .semibold)).padding(.horizontal, 8).padding(.bottom, 4)
            ForEach(ReaderTheme.allCases) { theme in
                Button { workspace.theme = theme; workspace.customAccentHex = ""; workspace.customBackgroundHex = ""; showThemePicker = false } label: {
                    HStack(spacing: 11) {
                        Circle().fill(Color(hex: theme.palette.bg)).overlay(Circle().stroke(Color(hex: theme.palette.line))).frame(width: 24, height: 24)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(workspace.themeTitle(theme)).font(.system(size: 13, weight: .medium))
                            Text(theme.subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if workspace.theme == theme { Image(systemName: "checkmark").foregroundStyle(Color(hex: theme.palette.accent)) }
                    }.contentShape(Rectangle()).padding(.horizontal, 8).frame(height: 43)
                }.buttonStyle(.plain)
            }
        }.padding(10).frame(width: 260)
    }

    private func documentStats(_ tab: MarkdownTab) -> some View {
        let words = tab.markdown.split { $0.isWhitespace || $0.isPunctuation }.count
        return Text("\(words) · \(max(1, Int(ceil(Double(words) / 220)))) min")
            .font(.system(size: 10.5, weight: .medium)).foregroundStyle(Color(hex: palette.muted).opacity(0.72))
            .padding(.horizontal, 10).frame(height: 26)
            .background(Color(hex: palette.chrome).opacity(0.82), in: Capsule())
            .padding(12).allowsHitTesting(false)
    }

    private func hideChrome() {
        guard workspace.editorMode == .read, !workspace.isSearchPresented else { return }
        if chromeVisible { withAnimation { chromeVisible = false } }
    }
    private func revealChrome() { if !chromeVisible { withAnimation { chromeVisible = true } } }

    private func acceptDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                let url = (item as? Data).flatMap { URL(dataRepresentation: $0, relativeTo: nil) } ?? item as? URL
                guard let url else { return }
                Task { @MainActor in
                    if ["md", "markdown", "mdown"].contains(url.pathExtension.lowercased()) { workspace.open(url) }
                    else if workspace.editorMode == .edit { workspace.importImage(url) }
                }
            }
        }
        return !providers.isEmpty
    }

    private func handleDroppedURLs(_ urls: [URL]) {
        for url in urls {
            if ["md", "markdown", "mdown"].contains(url.pathExtension.lowercased()) { workspace.open(url) }
            else if workspace.editorMode == .edit { workspace.importImage(url) }
        }
    }
}

struct DocumentSidebar: View {
    @EnvironmentObject private var workspace: ReaderWorkspace
    @State private var section = 0
    private var palette: ThemePalette { workspace.palette }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $section) {
                Text(workspace.t("sidebar.outline")).tag(0)
                Text(workspace.t("sidebar.files")).tag(1)
            }.pickerStyle(.segmented).padding(12)
            Rectangle().fill(Color(hex: palette.line)).frame(height: 1)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    if section == 0 {
                        ForEach(workspace.outlineItems) { item in
                            Button { workspace.perform(.jumpToHeading(item.title)) } label: {
                                Text(item.title).lineLimit(2).font(.system(size: max(11, 14 - Double(item.level) * 0.45), weight: item.level < 3 ? .semibold : .regular))
                                    .foregroundStyle(Color(hex: item.level < 3 ? palette.text : palette.muted))
                                    .padding(.leading, CGFloat(item.level - 1) * 12).frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 6).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                        }
                    } else {
                        ForEach(workspace.siblingDocuments, id: \.path) { url in
                            Button { workspace.open(url) } label: {
                                Label(url.deletingPathExtension().lastPathComponent, systemImage: "doc.text")
                                    .font(.system(size: 12.5)).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 7).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                        }
                    }
                }.padding(10)
            }
        }
        .frame(width: 255).frame(maxHeight: .infinity)
        .background(Color(hex: palette.chrome).opacity(0.98))
        .overlay(alignment: .leading) { Rectangle().fill(Color(hex: palette.line)).frame(width: 1) }
    }
}

struct EditorToolbar: View {
    @EnvironmentObject private var workspace: ReaderWorkspace
    private var palette: ThemePalette { workspace.palette }

    var body: some View {
        HStack(spacing: 4) {
            Menu {
                Button(workspace.t("editor.paragraph")) { workspace.perform(.paragraph) }
                Divider()
                ForEach(1...6, id: \.self) { level in Button("\(workspace.t("editor.heading")) \(level)") { workspace.perform(.heading(level)) } }
                Divider()
                Button(workspace.t("editor.quote")) { workspace.perform(.quote) }
                Divider()
                Button("Highlight") { workspace.perform(.highlight) }
                Button("Underline") { workspace.perform(.underline) }
                Button("Superscript") { workspace.perform(.superscript) }
                Button("Subscript") { workspace.perform(.subscriptStyle) }
            } label: {
                HStack(spacing: 5) { Text(workspace.t("editor.style")); Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold)) }
                    .frame(width: 88)
            }
            Divider().frame(height: 18).padding(.horizontal, 4)
            tool("bold", "⌘B") { workspace.perform(.bold) }
            tool("italic", "⌘I") { workspace.perform(.italic) }
            tool("strikethrough", "Strike") { workspace.perform(.strike) }
            tool("chevron.left.forwardslash.chevron.right", "Inline code") { workspace.perform(.inlineCode) }
            Divider().frame(height: 18).padding(.horizontal, 4)
            tool("list.bullet", "List") { workspace.perform(.unorderedList) }
            tool("list.number", "Numbered list") { workspace.perform(.orderedList) }
            tool("checklist", workspace.t("editor.task")) { workspace.perform(.taskList) }
            Divider().frame(height: 18).padding(.horizontal, 4)
            tool("link", workspace.t("editor.link")) { workspace.insertLink() }
            Menu {
                Button(workspace.t("editor.image")) { workspace.chooseImage() }
                Divider()
                Button("50%") { workspace.perform(.imageScale(50)) }
                Button("75%") { workspace.perform(.imageScale(75)) }
                Button("100%") { workspace.perform(.imageScale(100)) }
            } label: { Image(systemName: "photo") }.help(workspace.t("editor.image"))
            tableMenu
            Menu {
                Button(workspace.t("editor.codeBlock")) { workspace.perform(.codeFence("")) }
                Button("Swift") { workspace.perform(.codeFence("swift")) }
                Button("JavaScript") { workspace.perform(.codeFence("javascript")) }
                Button("Python") { workspace.perform(.codeFence("python")) }
                Divider()
                Button(workspace.t("editor.math")) { workspace.perform(.math) }
                Button(workspace.t("editor.diagram")) { workspace.perform(.diagram) }
                Button(workspace.t("editor.divider")) { workspace.perform(.divider) }
            } label: { Image(systemName: "plus.circle") }.help(workspace.t("editor.insert"))
            Spacer()
            Button { workspace.focusMode.toggle() } label: { Image(systemName: workspace.focusMode ? "scope" : "scope") }
                .help(workspace.t("settings.focus")).foregroundStyle(workspace.focusMode ? Color(hex: palette.accent) : Color(hex: palette.muted))
            Button { workspace.typewriterMode.toggle() } label: { Image(systemName: "text.line.first.and.arrowtriangle.forward") }
                .help(workspace.t("settings.typewriter")).foregroundStyle(workspace.typewriterMode ? Color(hex: palette.accent) : Color(hex: palette.muted))
        }
        .font(.system(size: 12.5, weight: .medium))
        .buttonStyle(EditorToolButtonStyle(color: Color(hex: palette.muted), hover: Color(hex: palette.bg)))
        .padding(.horizontal, 82).frame(height: 42)
        .overlay(alignment: .top) { Rectangle().fill(Color(hex: palette.line).opacity(0.7)).frame(height: 1) }
    }

    private func tool(_ symbol: String, _ help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol) }.help(help)
    }

    private var tableMenu: some View {
        Menu {
            Button("2 × 2") { workspace.perform(.table(rows: 2, columns: 2)) }
            Button("3 × 3") { workspace.perform(.table(rows: 3, columns: 3)) }
            Button("4 × 4") { workspace.perform(.table(rows: 4, columns: 4)) }
            Button("6 × 4") { workspace.perform(.table(rows: 6, columns: 4)) }
            Divider()
            Button("Add row") { workspace.perform(.tableOperation("addRow")) }
            Button("Add column") { workspace.perform(.tableOperation("addColumn")) }
            Button("Delete row") { workspace.perform(.tableOperation("deleteRow")) }
            Button("Delete column") { workspace.perform(.tableOperation("deleteColumn")) }
        } label: { Image(systemName: "tablecells") }.help(workspace.t("editor.table"))
    }
}

struct HomeView: View {
    @EnvironmentObject private var workspace: ReaderWorkspace
    private var palette: ThemePalette { workspace.palette }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("MDore").font(.system(size: 19, weight: .semibold, design: .serif))
                Spacer()
                Button { workspace.isSettingsPresented = true } label: { Image(systemName: "slider.horizontal.3") }
                    .buttonStyle(ChromeButtonStyle(color: Color(hex: palette.muted))).help(workspace.t("common.settings"))
            }.padding(.leading, 82).padding(.trailing, 18).frame(height: 54)

            HStack(alignment: .top, spacing: 74) {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MDore").font(.system(size: 52, weight: .semibold, design: .serif)).tracking(-1.8)
                        Text(workspace.t("home.subtitle")).font(.system(size: 16)).foregroundStyle(Color(hex: palette.muted))
                    }
                    HStack(spacing: 10) {
                        Button(action: workspace.createDocument) { Label(workspace.t("home.new"), systemImage: "square.and.pencil") }
                            .buttonStyle(.borderedProminent).tint(Color(hex: palette.accent)).controlSize(.large)
                        Button(action: workspace.chooseFiles) { Label(workspace.t("home.open"), systemImage: "folder") }
                            .buttonStyle(.bordered).controlSize(.large)
                    }
                    Spacer()
                    Text(workspace.t("home.drop")).font(.system(size: 12.5)).foregroundStyle(Color(hex: palette.muted).opacity(0.78))
                }.frame(width: 330).frame(minHeight: 380, alignment: .topLeading)

                VStack(alignment: .leading, spacing: 0) {
                    Text(workspace.t("home.recent")).font(.system(size: 12, weight: .semibold)).foregroundStyle(Color(hex: palette.muted)).textCase(.uppercase).tracking(0.8).padding(.bottom, 12)
                    recentRow(title: workspace.t("home.guide"), detail: workspace.t("home.guide.detail"), symbol: "sparkles", action: workspace.openGuide)
                    Rectangle().fill(Color(hex: palette.line)).frame(height: 1)
                    if workspace.recentURLs.isEmpty {
                        Text(workspace.t("home.empty")).font(.system(size: 13)).foregroundStyle(Color(hex: palette.muted)).padding(.vertical, 22)
                    } else {
                        ForEach(workspace.recentURLs.prefix(8), id: \.path) { url in
                            recentRow(title: url.deletingPathExtension().lastPathComponent,
                                      detail: url.deletingLastPathComponent().lastPathComponent,
                                      symbol: "doc.text", action: { workspace.open(url) })
                            Rectangle().fill(Color(hex: palette.line)).frame(height: 1)
                        }
                    }
                }.frame(width: 440)
            }
            .padding(.top, 72).padding(.horizontal, 82).frame(maxWidth: 1050)
            Spacer()
        }
        .foregroundStyle(Color(hex: palette.text))
    }

    private func recentRow(title: String, detail: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: symbol).font(.system(size: 16)).foregroundStyle(Color(hex: palette.accent)).frame(width: 24)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 14, weight: .medium)).lineLimit(1)
                    Text(detail).font(.system(size: 11.5)).foregroundStyle(Color(hex: palette.muted)).lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold)).foregroundStyle(Color(hex: palette.muted).opacity(0.55))
            }.contentShape(Rectangle()).frame(height: 58)
        }.buttonStyle(.plain)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var workspace: ReaderWorkspace
    @Environment(\.dismiss) private var dismiss
    private var palette: ThemePalette { workspace.palette }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Text(workspace.t("settings.title")).font(.system(size: 22, weight: .semibold, design: .serif))
                Spacer()
                Button(workspace.t("common.done")) { dismiss() }.keyboardShortcut(.defaultAction)
            }
            settingRow(workspace.t("settings.language")) {
                Picker("", selection: $workspace.language) { ForEach(AppLanguage.allCases) { Text($0.title).tag($0) } }.frame(width: 150)
            }
            settingRow(workspace.t("settings.theme")) {
                Picker("", selection: $workspace.theme) { ForEach(ReaderTheme.allCases) { Text(workspace.themeTitle($0)).tag($0) } }.frame(width: 150)
            }
            settingRow(workspace.t("settings.accent")) {
                ColorPicker("", selection: accentBinding, supportsOpacity: false).labelsHidden()
            }
            settingRow(workspace.t("settings.background")) {
                ColorPicker("", selection: backgroundBinding, supportsOpacity: false).labelsHidden()
            }
            VStack(alignment: .leading, spacing: 9) {
                HStack { Text(workspace.t("settings.width")); Spacer(); Text("\(Int(workspace.pageWidth)) px").foregroundStyle(.secondary) }
                Slider(value: $workspace.pageWidth, in: 560...980, step: 20).tint(Color(hex: palette.accent))
            }
            settingRow(workspace.t("settings.photo")) {
                HStack {
                    if workspace.backgroundImagePath != nil { Button(workspace.t("settings.photo.remove")) { workspace.clearBackgroundImage() } }
                    Button(workspace.t("settings.photo.choose")) { workspace.chooseBackgroundImage() }
                }
            }
            Toggle(workspace.t("settings.focus"), isOn: $workspace.focusMode)
            Toggle(workspace.t("settings.typewriter"), isOn: $workspace.typewriterMode)
            Toggle(workspace.t("settings.lineNumbers"), isOn: $workspace.showCodeLineNumbers)
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(workspace.t("settings.default"))
                    if let result = workspace.defaultReaderResult { Text(result).font(.system(size: 11)).foregroundStyle(.secondary) }
                }
                Spacer()
                Button(workspace.t("settings.default.action")) { workspace.makeDefaultReader() }
            }
            Spacer()
        }
        .padding(28).frame(width: 520, height: 540)
        .foregroundStyle(Color(hex: palette.text)).background(Color(hex: palette.bg))
    }

    private func settingRow<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack { Text(title); Spacer(); content() }
    }

    private var accentBinding: Binding<Color> {
        Binding(get: { Color(hex: palette.accent) }, set: { workspace.customAccentHex = NSColor($0).hexString })
    }
    private var backgroundBinding: Binding<Color> {
        Binding(get: { Color(hex: palette.bg) }, set: { workspace.customBackgroundHex = NSColor($0).hexString })
    }
}

struct ChromeButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.foregroundStyle(color.opacity(configuration.isPressed ? 0.55 : 1))
            .frame(width: 30, height: 30).contentShape(Rectangle())
    }
}

struct EditorToolButtonStyle: ButtonStyle {
    let color: Color
    let hover: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.foregroundStyle(color.opacity(configuration.isPressed ? 0.6 : 1))
            .frame(minWidth: 30, minHeight: 28).padding(.horizontal, 2)
            .background(configuration.isPressed ? hover : .clear, in: RoundedRectangle(cornerRadius: 7))
            .contentShape(Rectangle())
    }
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex.dropFirst(), radix: 16) ?? 0
        self.init(red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255)
    }
}

extension NSColor {
    var hexString: String {
        guard let rgb = usingColorSpace(.deviceRGB) else { return "#000000" }
        return String(format: "#%02X%02X%02X", Int(rgb.redComponent * 255), Int(rgb.greenComponent * 255), Int(rgb.blueComponent * 255))
    }
}
