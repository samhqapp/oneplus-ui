import AppKit
import SwiftUI

/// "Pickers on top" (owner, 2026-11-28): a right-click menu with optional pickers above its rows. It opens at the click
/// point in a non-activating panel that takes the arrow keys and Esc without activating the app, so it never steals
/// focus. It closes on Esc, a click outside, or a pick.
public enum OnePlusContextMenuMetrics {
    public static let minWidth: CGFloat = 236
    public static let padding: CGFloat = 5
    public static let radius: CGFloat = 12
    public static let rowHeight: CGFloat = 24
    public static let rowRadius: CGFloat = 6
    public static let rowPadding: CGFloat = 8
    public static let iconSize: CGFloat = 14
    public static let screenInset: CGFloat = 4
    public static let tileHeight: CGFloat = 44
    public static let tileGap: CGFloat = 4
    public static let swatchSize: CGFloat = 13
    public static let swatchGap: CGFloat = 6
    static let separatorHeight: CGFloat = 11
    static let shadowRoom: CGFloat = 32
    static let open: TimeInterval = 0.13
    static let close: TimeInterval = 0.09
    static let openScale: CGFloat = 0.96
}

/// Where the menu opens (y up): its top-left corner on the click point, kept 4 pt inside the screen.
public func onePlusContextMenuFrame(click: CGPoint, size: CGSize, screen: CGRect) -> CGRect {
    let inset = OnePlusContextMenuMetrics.screenInset
    let x = min(max(click.x, screen.minX + inset), screen.maxX - size.width - inset)
    let y = min(max(click.y - size.height, screen.minY + inset), screen.maxY - size.height - inset)
    return CGRect(x: x, y: y, width: size.width, height: size.height)
}

/// Rows and the keyboard: nothing is highlighted until a hover or an arrow key; up and down wrap over enabled rows.
@MainActor
final class OnePlusContextMenuSession: ObservableObject {
    let entries: [OnePlusPopupMenuEntry]
    @Published private(set) var highlightedID: UUID?
    var select: (UUID) -> Void = { _ in }
    var close: () -> Void = {}

    init(entries: [OnePlusPopupMenuEntry]) { self.entries = entries }

    private var enabled: [UUID] { entries.compactMap(\.item).filter(\.isEnabled).map(\.id) }

    func hover(_ id: UUID) { if enabled.contains(id) { highlightedID = id } }

    func handle(_ key: OnePlusPopupKey) -> Bool {
        let ids = enabled
        switch key {
        case .up, .down:
            guard !ids.isEmpty else { return true }
            let step = key == .down ? 1 : -1
            let current = highlightedID.flatMap { ids.firstIndex(of: $0) } ?? (step > 0 ? -1 : 0)
            highlightedID = ids[(current + step + ids.count) % ids.count]
        case .select: if let highlightedID { select(highlightedID) }
        case .escape: close()
        default: return false
        }
        return true
    }
}

enum OnePlusContextMenuColor {
    static let tile = OnePlusPopupColor.picked
    static let tileInk = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(white: 1, alpha: 0.7) : NSColor(white: 0, alpha: 0.62)
    })
    static let shadow = Color.black.opacity(0.24)
}

private final class OnePlusContextMenuPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
public final class OnePlusContextMenu {
    public static let shared = OnePlusContextMenu()

    private var panel: NSPanel?
    private var session: OnePlusContextMenuSession?
    private var monitors: [Any] = []
    private var observers: [NSObjectProtocol] = []

    private init() {}

    public var isOpen: Bool { panel != nil }

    /// Opens the menu at `point` (screen coordinates) with `header` above the rows.
    public func show<Header: View>(at point: CGPoint, header: Header, entries: [OnePlusPopupMenuEntry]) {
        close(animated: false)
        let session = OnePlusContextMenuSession(entries: entries)
        session.select = { [weak self] id in self?.select(id) }
        session.close = { [weak self] in self?.close() }
        let screen = NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main
        let bounds = screen?.frame ?? CGRect(origin: .zero, size: CGSize(width: 1440, height: 900))
        let measure = NSHostingView(rootView: OnePlusContextMenuView(session: session, header: header, anchor: .topLeading,
                                                                      shown: true))
        let size = measure.fittingSize
        let face = onePlusContextMenuFrame(click: point, size: size, screen: bounds)
        let anchor = UnitPoint(x: min(max((point.x - face.minX) / face.width, 0), 1),
                               y: min(max((face.maxY - point.y) / face.height, 0), 1))
        let room = OnePlusContextMenuMetrics.shadowRoom
        let host = NSHostingView(rootView: OnePlusContextMenuView(session: session, header: header, anchor: anchor)
            .padding(room).onePlusFocusPolicy())
        let panel = OnePlusContextMenuPanel(contentRect: face.insetBy(dx: -room, dy: -room),
                                            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.contentView = host
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .popUpMenu
        panel.becomesKeyOnlyIfNeeded = false
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .none
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.acceptsMouseMovedEvents = true
        panel.setAccessibilityLabel("Menu")
        panel.setFrame(face.insetBy(dx: -room, dy: -room), display: false)
        self.panel = panel
        self.session = session
        panel.orderFrontRegardless()
        panel.makeKey()
        install(panel: panel, face: face)
    }

    /// Closes with the 90 ms fade; a header pick calls it before it acts.
    public func close() { close(animated: !OnePlusMotion.reducesMotion) }

    private func close(animated: Bool) {
        guard let panel else { return }
        monitors.forEach(NSEvent.removeMonitor)
        monitors = []
        observers.forEach(NotificationCenter.default.removeObserver)
        observers = []
        self.panel = nil
        session = nil
        guard animated else { panel.orderOut(nil); panel.contentView = nil; return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = OnePlusContextMenuMetrics.close
            panel.animator().alphaValue = 0
        }, completionHandler: {
            MainActor.assumeIsolated { panel.orderOut(nil); panel.contentView = nil }
        })
    }

    private func select(_ id: UUID) {
        guard let item = session?.entries.compactMap(\.item).first(where: { $0.id == id }), item.isEnabled else { return }
        close()
        item.action()
    }

    private func install(panel: NSPanel, face: CGRect) {
        if let keys = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { [weak self] event in
            guard let self, event.window === self.panel, let key = OnePlusPopupPresenter.popupKey(for: event),
                  self.session?.handle(key) == true else { return event }
            return nil
        }) { monitors.append(keys) }
        let clicks: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        if let local = NSEvent.addLocalMonitorForEvents(matching: clicks, handler: { [weak self] event in
            if !(event.window === panel && face.contains(NSEvent.mouseLocation)) { self?.close() }
            return event
        }) { monitors.append(local) }
        if let global = NSEvent.addGlobalMonitorForEvents(matching: clicks, handler: { [weak self] _ in
            MainActor.assumeIsolated { self?.close() }
        }) { monitors.append(global) }
        observers.append(NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: panel,
                                                                queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.close() }
        })
    }
}

struct OnePlusContextMenuView<Header: View>: View {
    @ObservedObject var session: OnePlusContextMenuSession
    let header: Header
    let anchor: UnitPoint
    @State var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: OnePlusContextMenuMetrics.radius, style: .continuous)
        VStack(alignment: .leading, spacing: 0) {
            header
            ForEach(session.entries) { entry in
                switch entry {
                case let .item(item): OnePlusContextMenuRow(item: item, session: session)
                case let .section(_, title):
                    Text(title).onePlusText(.captionUpper, color: OnePlusPopupColor.detail)
                        .padding(.horizontal, OnePlusContextMenuMetrics.rowPadding).frame(height: OnePlusPopupMetrics.sectionHeight)
                case .separatorItem: OnePlusContextMenuSeparator()
                }
            }
        }
        .padding(OnePlusContextMenuMetrics.padding)
        .frame(minWidth: OnePlusContextMenuMetrics.minWidth)
        .fixedSize()
        .background(OnePlusPopupColor.background, in: shape)
        .overlay { shape.strokeBorder(OnePlusPopupColor.ring, lineWidth: 0.5) }
        .clipShape(shape)
        .shadow(color: OnePlusContextMenuColor.shadow, radius: 15, y: 10)
        .scaleEffect(shown || reduceMotion ? 1 : OnePlusContextMenuMetrics.openScale, anchor: anchor)
        .opacity(shown ? 1 : 0)
        .onAppear {
            withAnimation(.timingCurve(0.25, 1, 0.5, 1, duration: OnePlusContextMenuMetrics.open)) { shown = true }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .onePlusAppAppearance()
    }
}

/// The 1 pt line between row groups, 8 pt in from each side.
public struct OnePlusContextMenuSeparator: View {
    public init() {}
    public var body: some View {
        Rectangle().fill(OnePlusPopupColor.hair).frame(height: 1)
            .padding(.horizontal, OnePlusContextMenuMetrics.rowPadding)
            .frame(height: OnePlusContextMenuMetrics.separatorHeight)
            .accessibilityHidden(true)
    }
}

struct OnePlusContextMenuRow: View {
    let item: OnePlusPopupMenuItem
    @ObservedObject var session: OnePlusContextMenuSession

    var body: some View {
        let ink = item.role == .destructive ? OnePlusColor.danger : OnePlusPopupColor.ink
        Button { session.select(item.id) } label: {
            HStack(spacing: 8) {
                Group {
                    if let symbol = item.systemImage { Image(systemName: symbol).font(.system(size: 12)).opacity(0.75) }
                    else { Color.clear }
                }
                .frame(width: OnePlusContextMenuMetrics.iconSize)
                Text(item.title).lineLimit(1)
                Spacer(minLength: 12)
                if item.isSelected {
                    Image(systemName: "checkmark").font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(OnePlusPopupColor.detail)
                }
            }
            .font(.system(size: 13))
            .foregroundStyle(ink)
            .padding(.horizontal, OnePlusContextMenuMetrics.rowPadding)
            .frame(height: OnePlusContextMenuMetrics.rowHeight)
            .background {
                if session.highlightedID == item.id {
                    RoundedRectangle(cornerRadius: OnePlusContextMenuMetrics.rowRadius, style: .continuous)
                        .fill(OnePlusPopupColor.picked)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!item.isEnabled)
        .onHover { if $0, item.isEnabled { session.hover(item.id) } }
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(item.isSelected ? .isSelected : [])
    }
}

/// A picker tile in a menu header: a small picture over a 9.5 pt name; the picked tile is filled blue.
public struct OnePlusContextMenuTile<Picture: View>: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    let picture: Picture

    public init(_ title: String, isSelected: Bool, action: @escaping () -> Void, @ViewBuilder picture: () -> Picture) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
        self.picture = picture()
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                picture.frame(width: 24, height: 16)
                Text(title).font(.system(size: 9.5))
            }
            .foregroundStyle(isSelected ? Color.white : OnePlusContextMenuColor.tileInk)
            .frame(maxWidth: .infinity)
            .frame(height: OnePlusContextMenuMetrics.tileHeight)
            .background(isSelected ? OnePlusLinearColor.pushProminent : OnePlusContextMenuColor.tile,
                        in: RoundedRectangle(cornerRadius: OnePlusContextMenuMetrics.rowRadius, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A 13 pt color dot in a menu header; the picked one wears a ring in its own color.
public struct OnePlusContextMenuSwatch: View {
    let color: Color
    let title: String
    let isSelected: Bool
    let action: () -> Void

    public init(_ title: String, color: Color, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.color = color
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        let size = OnePlusContextMenuMetrics.swatchSize
        Button(action: action) {
            Circle().fill(color)
                .overlay { Circle().strokeBorder(Color.black.opacity(0.18), lineWidth: 0.5) }
                .frame(width: size, height: size)
                .background { if isSelected { Circle().stroke(color, lineWidth: 1.5).frame(width: size + 5.5, height: size + 5.5) } }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(title)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
