import SwiftUI
import UniformTypeIdentifiers

struct ReaderView: View {
    @EnvironmentObject private var workspace: ReaderWorkspace
    @AppStorage("didCompleteWelcome") private var didCompleteWelcome = false
    @State private var isTargeted = false
    @State private var chromeVisible = true
    @State private var showThemePicker = false
    @State private var scrollMonitor: Any?
    @FocusState private var searchFocused: Bool

    private var palette: ThemePalette { workspace.theme.palette }

    var body: some View {
        ZStack {
            Color(hex: palette.bg).ignoresSafeArea()
            if let tab = workspace.selectedTab {
                MarkdownWebView(markdown: tab.markdown, baseURL: tab.url.deletingLastPathComponent(), theme: workspace.theme,
                                textScale: workspace.textScale, searchQuery: workspace.searchQuery,
                                findRevision: workspace.findRevision, onScroll: hideChrome, onOpenLink: workspace.followLink)
                    .id(tab.id)
                    .transition(.opacity.combined(with: .scale(scale: 0.995)))
            } else { welcome }

            if isTargeted {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color(hex: palette.accent), style: StrokeStyle(lineWidth: 2, dash: [8, 7]))
                    .background(Color(hex: palette.accent).opacity(0.06)).padding(14).allowsHitTesting(false)
            }
        }
        .overlay(alignment: .top) { chrome }
        .overlay(alignment: .topTrailing) { searchPanel }
        .onContinuousHover { phase in if case .active = phase { revealChrome() } }
        .onTapGesture { revealChrome() }
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isTargeted, perform: acceptDrop)
        .sheet(isPresented: Binding(get: { !didCompleteWelcome }, set: { if !$0 { didCompleteWelcome = true } })) {
            OnboardingView(isPresented: Binding(get: { !didCompleteWelcome }, set: { if !$0 { didCompleteWelcome = true } }))
                .environmentObject(workspace)
        }
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
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(workspace.tabs) { tab in tabButton(tab) }
                    Button(action: workspace.chooseFiles) { Image(systemName: "plus").frame(width: 28, height: 28) }
                        .help("Открыть Markdown")
                }.padding(.leading, 78)
            }
            Spacer(minLength: 8)
            Button { workspace.refreshSelected() } label: {
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: workspace.selectedTab?.isAvailable == false ? "exclamationmark.triangle" : "arrow.clockwise")
                    Circle()
                        .fill(workspace.selectedTab?.isAvailable == false ? Color.orange : Color(hex: palette.accent))
                        .frame(width: 5, height: 5)
                        .overlay(Circle().stroke(Color(hex: palette.chrome), lineWidth: 1))
                }
            }
            .disabled(workspace.selectedTab == nil)
            .help(workspace.syncStatusText)
            Button { workspace.showSearch() } label: { Image(systemName: "magnifyingglass") }.help("Поиск — ⌘F")
            Button { showThemePicker.toggle() } label: { Image(systemName: "circle.lefthalf.filled") }
                .help("Тема").popover(isPresented: $showThemePicker, arrowEdge: .top) { themePicker }
            Button { NSApp.keyWindow?.toggleFullScreen(nil) } label: { Image(systemName: "arrow.up.left.and.arrow.down.right") }
                .help("Режим чтения — ⌘⇧R")
        }
        .buttonStyle(ChromeButtonStyle(color: Color(hex: palette.muted)))
        .padding(.horizontal, 12).frame(height: 52)
        .background(Color(hex: palette.chrome).opacity(0.96))
        .overlay(alignment: .bottom) { Rectangle().fill(Color(hex: palette.line)).frame(height: 1) }
        .offset(y: chromeVisible ? 0 : -16).opacity(chromeVisible ? 1 : 0)
        .allowsHitTesting(chromeVisible).animation(.easeOut(duration: 0.22), value: chromeVisible)
    }

    private func tabButton(_ tab: MarkdownTab) -> some View {
        let selected = workspace.selectedID == tab.id
        return HStack(spacing: 7) {
            Text(tab.title).lineLimit(1)
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
    }

    @ViewBuilder private var searchPanel: some View {
        if workspace.isSearchPresented {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(Color(hex: palette.muted))
                TextField("Найти в документе", text: $workspace.searchQuery).textFieldStyle(.plain)
                    .focused($searchFocused).onSubmit { workspace.findNext() }
                Button { workspace.findNext(backwards: true) } label: { Image(systemName: "chevron.up") }
                Button { workspace.findNext() } label: { Image(systemName: "chevron.down") }
                Button { workspace.hideSearch() } label: { Image(systemName: "xmark") }
            }
            .buttonStyle(ChromeButtonStyle(color: Color(hex: palette.muted))).font(.system(size: 13))
            .foregroundStyle(Color(hex: palette.text)).padding(.horizontal, 12).frame(width: 330, height: 42)
            .background(Color(hex: palette.chrome), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: palette.line)))
            .shadow(color: .black.opacity(0.12), radius: 18, y: 8).padding(.top, 60).padding(.trailing, 14)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var welcome: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text").font(.system(size: 42, weight: .light))
            VStack(spacing: 6) {
                Text("MDore").font(.system(size: 28, weight: .semibold, design: .serif))
                Text("Перетащите Markdown или откройте через ⌘O").font(.system(size: 14)).foregroundStyle(Color(hex: palette.muted))
            }
            Button("Открыть файл") { workspace.chooseFiles() }.buttonStyle(.borderedProminent).tint(Color(hex: palette.accent))
        }.foregroundStyle(Color(hex: palette.text))
    }

    private var themePicker: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Атмосфера чтения").font(.system(size: 13, weight: .semibold)).padding(.horizontal, 8).padding(.bottom, 4)
            ForEach(ReaderTheme.allCases) { theme in
                Button { workspace.theme = theme; showThemePicker = false } label: {
                    HStack(spacing: 11) {
                        Circle().fill(Color(hex: theme.palette.bg)).overlay(Circle().stroke(Color(hex: theme.palette.line))).frame(width: 24, height: 24)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(theme.title).font(.system(size: 13, weight: .medium))
                            Text(theme.subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if workspace.theme == theme { Image(systemName: "checkmark").foregroundStyle(Color(hex: theme.palette.accent)) }
                    }.contentShape(Rectangle()).padding(.horizontal, 8).frame(height: 43)
                }.buttonStyle(.plain)
            }
        }.padding(10).frame(width: 260)
    }

    private func hideChrome() {
        guard !workspace.isSearchPresented else { return }
        if chromeVisible { withAnimation { chromeVisible = false } }
    }
    private func revealChrome() { if !chromeVisible { withAnimation { chromeVisible = true } } }

    private func acceptDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                let url = (item as? Data).flatMap { URL(dataRepresentation: $0, relativeTo: nil) } ?? item as? URL
                if let url { Task { @MainActor in workspace.open(url) } }
            }
        }
        return !providers.isEmpty
    }
}

struct OnboardingView: View {
    @EnvironmentObject private var workspace: ReaderWorkspace
    @Binding var isPresented: Bool
    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 9) {
                Text("MDore").font(.system(size: 38, weight: .semibold, design: .serif))
                Text("Ваше тихое место для Markdown").font(.system(size: 15)).foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                ForEach(ReaderTheme.allCases) { theme in
                    Button { workspace.theme = theme } label: {
                        VStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 12).fill(Color(hex: theme.palette.bg))
                                .overlay(alignment: .leading) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Capsule().fill(Color(hex: theme.palette.text)).frame(width: 48, height: 6)
                                        Capsule().fill(Color(hex: theme.palette.muted)).frame(width: 34, height: 4)
                                        Capsule().fill(Color(hex: theme.palette.accent)).frame(width: 25, height: 4)
                                    }.padding(12)
                                }
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(workspace.theme == theme ? Color(hex: theme.palette.accent) : Color(hex: theme.palette.line), lineWidth: workspace.theme == theme ? 2 : 1))
                                .frame(width: 112, height: 82)
                            Text(theme.title).font(.system(size: 12, weight: .medium))
                        }
                    }.buttonStyle(.plain)
                }
            }
            VStack(spacing: 10) {
                Button("Сделать MDore основным ридером .md") { workspace.makeDefaultReader() }.buttonStyle(.borderedProminent).controlSize(.large)
                if let result = workspace.defaultReaderResult { Text(result).font(.system(size: 11)).foregroundStyle(.secondary) }
                Button("Продолжить") { isPresented = false }.buttonStyle(.plain).foregroundStyle(.secondary)
            }
        }.padding(36).frame(width: 560, height: 390)
    }
}

struct ChromeButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.foregroundStyle(color.opacity(configuration.isPressed ? 0.55 : 1))
            .frame(width: 30, height: 30).contentShape(Rectangle())
    }
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex.dropFirst(), radix: 16) ?? 0
        self.init(red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255)
    }
}
