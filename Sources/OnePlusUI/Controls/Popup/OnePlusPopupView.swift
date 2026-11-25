import AppKit
import SwiftUI

@MainActor
final class OnePlusPopupSession: ObservableObject {
    let allEntries: [OnePlusPopupMenuEntry]
    let density: OnePlusDensity
    let showsSymbolColumn: Bool
    /// More than `searchThreshold` items: typed keys filter the list instead of type-select.
    let searchable: Bool
    @Published private(set) var query = ""
    @Published private(set) var highlightedID: UUID?
    /// The row that keeps the soft fill. A pick glides it to the new row before the menu closes.
    @Published private(set) var pickedID: UUID?
    /// Bumped only by keyboard moves, so the list scrolls for keys and never for pointer hover.
    @Published private(set) var keyboardScroll = 0
    private var navigation = OnePlusPopupNavigationState()
    private var picking = false
    var select: (UUID) -> Void = { _ in }
    var close: (Bool) -> Void = { _ in }
    var queryChanged: () -> Void = {}
    weak var accessibilityHost: OnePlusPopupAccessibilityHost?
    var rowAnchors: [UUID: OnePlusPopupRowAnchor] = [:]

    var entries: [OnePlusPopupMenuEntry] { onePlusPopupFilter(allEntries, query: query) }

    init(entries: [OnePlusPopupMenuEntry], density: OnePlusDensity, initialID: UUID?) {
        allEntries = entries
        self.density = density
        showsSymbolColumn = entries.contains { $0.item?.systemImage != nil }
        searchable = OnePlusPopupMetrics.searchable(entries)
        pickedID = entries.first { $0.item?.isSelected == true }?.id
        navigation.open(entries: entries, initialID: initialID)
        highlightedID = navigation.highlightedID
    }

    func hover(_ id: UUID?) {
        navigation.highlight(id, entries: entries)
        highlightedID = navigation.highlightedID
    }

    func handle(_ key: OnePlusPopupKey) -> Bool {
        if searchable, let edited = edit(query, with: key) {
            query = edited
            navigation.open(entries: entries, initialID: nil)
            highlightedID = navigation.highlightedID
            keyboardScroll += 1
            queryChanged()
            return true
        }
        let result = navigation.handle(key, entries: entries)
        if navigation.highlightedID != highlightedID { keyboardScroll += 1 }
        highlightedID = navigation.highlightedID
        switch result {
        case .none:
            return false
        case .highlight:
            return true
        case let .select(id):
            pick(id)
            return true
        case .closeAndRestoreFocus:
            close(true)
            return true
        }
    }

    private func edit(_ text: String, with key: OnePlusPopupKey) -> String? {
        switch key {
        case let .type(characters): text + characters
        case .backspace: text.isEmpty ? nil : String(text.dropLast())
        default: nil
        }
    }

    /// Instant pick, for VoiceOver presses.
    func choose(_ id: UUID) { select(id) }

    /// A click or Return. In a menu with a picked row, the fill first glides to the new row, then the menu
    /// closes; action menus and Reduce Motion close at once.
    func pick(_ id: UUID) {
        guard !picking else { return }
        guard let pickedID, pickedID != id, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            select(id)
            return
        }
        picking = true
        withAnimation(OnePlusPopupMetrics.glide) { self.pickedID = id }
        DispatchQueue.main.asyncAfter(deadline: .now() + OnePlusPopupMetrics.pickDelay) { [weak self] in
            self?.select(id)
        }
    }
}

/// The popup's own colors (dark options page, "Picked row stays filled").
enum OnePlusPopupColor {
    private static func color(dark: NSColor, light: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }
    private static func white(_ alpha: CGFloat) -> NSColor { NSColor(white: 1, alpha: alpha) }
    private static func black(_ alpha: CGFloat) -> NSColor { NSColor(white: 0, alpha: alpha) }

    static let background = color(dark: NSColor(srgbRed: 22 / 255, green: 22 / 255, blue: 25 / 255, alpha: 0.96),
                                  light: white(0.97))
    static let ring = color(dark: white(0.10), light: black(0.12))
    static let ink = color(dark: white(0.93), light: NSColor(srgbRed: 0x1D / 255, green: 0x1D / 255, blue: 0x1F / 255, alpha: 1))
    static let pickedInk = color(dark: .white, light: NSColor(srgbRed: 0x1D / 255, green: 0x1D / 255, blue: 0x1F / 255, alpha: 1))
    static let detail = color(dark: white(0.42), light: black(0.45))
    static let hover = color(dark: white(0.05), light: black(0.035))
    static let picked = color(dark: white(0.11), light: black(0.07))
    static let hair = color(dark: white(0.08), light: black(0.08))
    static let searchFill = color(dark: white(0.06), light: black(0.05))
    static let caret = color(dark: NSColor(srgbRed: 0x6E / 255, green: 0x9B / 255, blue: 0xF0 / 255, alpha: 1),
                             light: NSColor(srgbRed: 0x3A / 255, green: 0x6F / 255, blue: 0xD8 / 255, alpha: 1))
}

struct OnePlusPopupMenuView: View {
    @ObservedObject var session: OnePlusPopupSession
    @Namespace private var fills

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: OnePlusPopupMetrics.radius, style: .continuous)
        VStack(spacing: OnePlusPopupMetrics.searchGap) {
            if session.searchable { OnePlusPopupSearchField(query: session.query) }
            list.frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(OnePlusPopupMetrics.padding)
        .background(OnePlusPopupColor.background, in: shape)
        .overlay { shape.strokeBorder(OnePlusPopupColor.ring, lineWidth: 0.5) }
        .clipShape(shape)
        .overlay {
            OnePlusPopupAccessibilityView(session: session)
                .allowsHitTesting(false)
        }
        .onePlusDensity(session.density)
        .onePlusAppAppearance()
    }

    @ViewBuilder private var list: some View {
        if session.entries.compactMap(\.item).isEmpty {
            Text("No matches").onePlusText(.control, color: OnePlusPopupColor.detail)
                .frame(maxWidth: .infinity).frame(height: OnePlusPopupMetrics.itemHeight(for: session.density))
        } else if session.allEntries.filter({ $0.item != nil }).count > OnePlusPopupMetrics.maxVisibleItems {
            ScrollViewReader { proxy in
                ScrollView { entries }
                    .onePlusScrollIndicators(axes: .vertical)
                    .onAppear { if let id = session.highlightedID { proxy.scrollTo(id, anchor: .center) } }
                    .onChange(of: session.keyboardScroll) {
                        if let id = session.highlightedID { proxy.scrollTo(id) }
                    }
            }
        } else {
            entries
        }
    }

    private var entries: some View {
        LazyVStack(spacing: 0) {
            ForEach(session.entries) { entry in
                switch entry {
                case let .item(item):
                    OnePlusPopupItemView(item: item, session: session, fills: fills).id(item.id)
                case let .section(_, title):
                    Text(title)
                        .onePlusText(.captionUpper, color: OnePlusPopupColor.detail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, OnePlusPopupMetrics.itemPadding + leadingColumns)
                        .frame(height: OnePlusPopupMetrics.sectionHeight)
                        .accessibilityHidden(true)
                case .separatorItem:
                    Rectangle().fill(OnePlusPopupColor.hair).frame(height: 0.5)
                        .padding(.horizontal, 8)
                        .frame(height: OnePlusPopupMetrics.separatorHeight)
                        .accessibilityHidden(true)
                }
            }
        }
        .animation(OnePlusPopupMetrics.glide, value: session.highlightedID)
    }

    private var leadingColumns: CGFloat {
        session.showsSymbolColumn ? OnePlusPopupMetrics.symbolColumn + OnePlusPopupMetrics.columnGap : 0
    }
}

/// The search variant's field. The popup never takes key focus, so typed keys arrive through the presenter's
/// key monitor and this field only draws the query and a caret.
struct OnePlusPopupSearchField: View {
    let query: String
    @State private var caretOn = true

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass").font(.system(size: 11, weight: .medium))
                .foregroundStyle(OnePlusPopupColor.detail)
            HStack(spacing: 1) {
                if !query.isEmpty { Text(query).lineLimit(1).truncationMode(.head) }
                Rectangle().fill(OnePlusPopupColor.caret).frame(width: 1.5, height: 14).opacity(caretOn ? 1 : 0)
                if query.isEmpty { Text("Search").foregroundStyle(OnePlusPopupColor.detail) }
            }
            .onePlusText(.control, color: OnePlusPopupColor.ink)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, OnePlusPopupMetrics.itemPadding)
        .frame(height: OnePlusPopupMetrics.searchHeight)
        .background(OnePlusPopupColor.searchFill, in: RoundedRectangle(cornerRadius: OnePlusPopupMetrics.itemRadius, style: .continuous))
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(530))
                caretOn.toggle()
            }
        }
        .accessibilityElement().accessibilityLabel("Search").accessibilityValue(query)
    }
}

struct OnePlusPopupItemView: View {
    let item: OnePlusPopupMenuItem
    @ObservedObject var session: OnePlusPopupSession
    var fills: Namespace.ID?

    var body: some View {
        let picked = session.pickedID == item.id
        let ink = item.role == .destructive ? OnePlusColor.danger : picked ? OnePlusPopupColor.pickedInk : OnePlusPopupColor.ink
        Button { session.pick(item.id) } label: {
            HStack(spacing: OnePlusPopupMetrics.columnGap) {
                if session.showsSymbolColumn {
                    OnePlusControlContentLayout(pointSize: OnePlusTextRole.control.size(for: session.density)) {
                        if let symbol = item.systemImage { Image(systemName: symbol) }
                        else { Color.clear }
                    }
                    .frame(width: OnePlusPopupMetrics.symbolColumn)
                }
                OnePlusControlContentLayout(pointSize: OnePlusTextRole.control.size(for: session.density), iconIndex: nil) {
                    Text(item.title).lineLimit(1).truncationMode(.middle).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .onePlusText(.control, color: ink)
            .fontWeight(picked ? .medium : nil)
            .padding(.horizontal, OnePlusPopupMetrics.itemPadding)
            .frame(maxWidth: .infinity)
            .frame(height: OnePlusPopupMetrics.itemHeight(for: session.density))
            .background { fill(picked: picked) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background { OnePlusPopupRowGeometry(id: item.id, session: session) }
        .disabled(!item.isEnabled)
        .opacity(item.isEnabled ? 1 : OnePlusMetrics.disabledOpacity)
        .help(item.title)
        .onHover { hovering in
            guard item.isEnabled else { return }
            session.hover(hovering ? item.id : nil)
        }
        .accessibilityHidden(true)
    }

    /// The picked fill and the fainter hover fill. Each is one shape that glides between rows.
    @ViewBuilder private func fill(picked: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: OnePlusPopupMetrics.itemRadius, style: .continuous)
        ZStack {
            if picked { glide(shape.fill(OnePlusPopupColor.picked), id: "picked") }
            if session.highlightedID == item.id { glide(shape.fill(OnePlusPopupColor.hover), id: "hover") }
        }
    }

    @ViewBuilder private func glide(_ view: some View, id: String) -> some View {
        if let fills { view.matchedGeometryEffect(id: id, in: fills) } else { view }
    }
}

private struct OnePlusPopupAccessibilityView: NSViewRepresentable {
    @ObservedObject var session: OnePlusPopupSession

    func makeNSView(context: Context) -> OnePlusPopupAccessibilityHost {
        OnePlusPopupAccessibilityHost()
    }

    func updateNSView(_ view: OnePlusPopupAccessibilityHost, context: Context) {
        session.accessibilityHost = view
        view.update(session: session)
    }
}

final class OnePlusPopupAccessibilityHost: NSView {
    private weak var session: OnePlusPopupSession?
    private var highlightedID: UUID?
    private var itemsByID: [UUID: OnePlusPopupAccessibilityItem] = [:]
    private weak var clipView: NSClipView?
    private var boundsObserver: NSObjectProtocol?
    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setAccessibilityElement(true)
        setAccessibilityRole(.menu)
        setAccessibilityLabel("Menu")
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    isolated deinit { if let boundsObserver { NotificationCenter.default.removeObserver(boundsObserver) } }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func update(session: OnePlusPopupSession) {
        self.session = session
        let oldHighlight = highlightedID
        highlightedID = session.highlightedID
        let items = session.entries.compactMap(\.item)
        let ids = Set(items.map(\.id))
        itemsByID = itemsByID.filter { ids.contains($0.key) }
        let children = items.map { item in
            let element = itemsByID[item.id] ?? OnePlusPopupAccessibilityItem(id: item.id) { [weak session] id in
                session?.choose(id)
            }
            itemsByID[item.id] = element
            element.setAccessibilityRole(.menuItem)
            element.setAccessibilityLabel(item.title)
            element.setAccessibilityEnabled(item.isEnabled)
            element.setAccessibilitySelected(item.isSelected)
            element.setAccessibilityFocused(item.id == highlightedID)
            element.setAccessibilityParent(self)
            return element
        }
        setAccessibilityChildren(children)
        updateFrames()
        if oldHighlight != highlightedID, let id = highlightedID, let element = itemsByID[id] {
            NSAccessibility.post(element: element, notification: .focusedUIElementChanged)
        }
    }

    override func layout() { super.layout(); updateFrames() }
    func updateFrames() {
        guard let session else { return }
        for (id, element) in itemsByID {
            guard let row = session.rowAnchors[id]?.view, let window = row.window else {
                element.setAccessibilityFrame(.zero)
                continue
            }
            let visible = row.visibleRect.intersection(row.bounds)
            element.setAccessibilityFrame(visible.isEmpty ? .zero : window.convertToScreen(row.convert(visible, to: nil)))
            observe(row.enclosingScrollView?.contentView)
        }
    }

    private func observe(_ clip: NSClipView?) {
        guard let clip, clip !== clipView else { return }
        if let boundsObserver { NotificationCenter.default.removeObserver(boundsObserver) }
        clipView = clip
        clip.postsBoundsChangedNotifications = true
        boundsObserver = NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification,
                                                               object: clip, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateFrames() }
        }
    }
}

final class OnePlusPopupAccessibilityItem: NSAccessibilityElement {
    let id: UUID
    private let choose: (UUID) -> Void
    init(id: UUID, choose: @escaping (UUID) -> Void) {
        self.id = id; self.choose = choose
        super.init()
    }
    override func accessibilityPerformPress() -> Bool {
        guard isAccessibilityEnabled() else { return false }
        choose(id)
        return true
    }
}

final class OnePlusPopupRowAnchor {
    weak var view: NSView?
}

private struct OnePlusPopupRowGeometry: NSViewRepresentable {
    let id: UUID
    let session: OnePlusPopupSession
    func makeNSView(context: Context) -> OnePlusPopupRowGeometryView { OnePlusPopupRowGeometryView() }
    func updateNSView(_ view: OnePlusPopupRowGeometryView, context: Context) {
        let anchor = session.rowAnchors[id] ?? OnePlusPopupRowAnchor()
        anchor.view = view
        session.rowAnchors[id] = anchor
        view.changed = { [weak session] in session?.accessibilityHost?.updateFrames() }
    }
}
private final class OnePlusPopupRowGeometryView: NSView {
    var changed: () -> Void = {}
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    override func layout() { super.layout(); changed() }
    override func viewDidMoveToWindow() { super.viewDidMoveToWindow(); changed() }
}
