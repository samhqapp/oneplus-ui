import AppKit
import SwiftUI

enum OnePlusPopupCloseReason {
    case selection
    case escape
    case outsideClick
    case windowChange
    case appDeactivation
    case triggerDisappeared
}

@MainActor
final class OnePlusPopupAnchorReference {
    weak var view: OnePlusPopupAnchorView?
}

struct OnePlusPopupAnchor: NSViewRepresentable {
    let reference: OnePlusPopupAnchorReference

    func makeNSView(context: Context) -> OnePlusPopupAnchorView {
        let view = OnePlusPopupAnchorView()
        reference.view = view
        return view
    }

    func updateNSView(_ view: OnePlusPopupAnchorView, context: Context) {
        reference.view = view
    }

    static func dismantleNSView(_ view: OnePlusPopupAnchorView, coordinator: ()) {
        OnePlusPopupPresenter.shared.close(anchor: view, reason: .triggerDisappeared)
    }
}

final class OnePlusPopupAnchorView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if window != nil, newWindow == nil {
            OnePlusPopupPresenter.shared.close(anchor: self, reason: .triggerDisappeared)
        }
        super.viewWillMove(toWindow: newWindow)
    }
}

private final class OnePlusPopupPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class OnePlusPopupPresenter {
    static let shared = OnePlusPopupPresenter()

    private weak var anchor: OnePlusPopupAnchorView?
    private weak var parentWindow: NSWindow?
    private var panel: NSPanel?
    private var session: OnePlusPopupSession?
    private var localKeyMonitor: Any?
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?
    private var observers: [NSObjectProtocol] = []
    private var onClose: ((OnePlusPopupCloseReason) -> Void)?

    private init() {}

    func isOpen(for anchor: OnePlusPopupAnchorView?) -> Bool {
        guard let anchor else { return false }
        return self.anchor === anchor && panel != nil
    }

    func toggle(anchor: OnePlusPopupAnchorView?, entries: [OnePlusPopupMenuEntry],
                density: OnePlusDensity, initialID: UUID?, onClose: @escaping (OnePlusPopupCloseReason) -> Void) {
        guard let anchor, let window = anchor.window, !entries.isEmpty else { return }
        if isOpen(for: anchor) {
            close(reason: .outsideClick)
            return
        }
        close(reason: .triggerDisappeared)
        open(anchor: anchor, window: window, entries: entries, density: density,
             initialID: initialID, onClose: onClose)
    }

    func close(anchor: OnePlusPopupAnchorView, reason: OnePlusPopupCloseReason) {
        guard self.anchor === anchor else { return }
        close(reason: reason)
    }

    private func open(anchor: OnePlusPopupAnchorView, window: NSWindow,
                      entries: [OnePlusPopupMenuEntry], density: OnePlusDensity,
                      initialID: UUID?, onClose: @escaping (OnePlusPopupCloseReason) -> Void) {
        let session = OnePlusPopupSession(entries: entries, density: density, initialID: initialID)
        session.select = { [weak self] id in self?.select(id) }
        session.close = { [weak self] restoreFocus in
            self?.close(reason: restoreFocus ? .escape : .outsideClick)
        }
        let host = NSHostingView(rootView: OnePlusPopupMenuView(session: session).onePlusFocusPolicy())
        let visibleFrame = (window.screen ?? NSScreen.main)?.visibleFrame ?? window.frame
        let triggerFrame = window.convertToScreen(anchor.convert(anchor.bounds, to: nil))
        // Medium weight: the picked row's title is medium, so it never truncates.
        let font = NSFont.systemFont(ofSize: OnePlusTextRole.control.size(for: density), weight: .medium)
        let longestTitle = entries.compactMap(\.item).map(\.title).max { lhs, rhs in
            (lhs as NSString).size(withAttributes: [.font: font]).width
                < (rhs as NSString).size(withAttributes: [.font: font]).width
        } ?? ""
        let titleWidth = ceil((longestTitle as NSString).size(withAttributes: [.font: font]).width)
        let hasSymbols = entries.contains { $0.item?.systemImage != nil }
        let columns = hasSymbols ? OnePlusPopupMetrics.symbolColumn + OnePlusPopupMetrics.columnGap : 0
        let naturalWidth = OnePlusPopupMetrics.padding * 2 + OnePlusPopupMetrics.itemPadding * 2
            + columns + titleWidth
        let width = min(visibleFrame.width, max(triggerFrame.width, OnePlusPopupMetrics.minimumContentWidth, naturalWidth))
        let search = OnePlusPopupMetrics.searchable(entries) ? OnePlusPopupMetrics.searchHeight + OnePlusPopupMetrics.searchGap : 0
        let fullHeight = OnePlusPopupMetrics.contentHeight(entries: entries, density: density) + search
        let height = min(fullHeight, OnePlusPopupMetrics.maximumHeight(density: density) + search, visibleFrame.height)
        host.frame = NSRect(origin: .zero, size: NSSize(width: width, height: height))

        let panel = OnePlusPopupPanel(contentRect: NSRect(origin: .zero, size: host.frame.size),
                                      styleMask: [.borderless, .nonactivatingPanel],
                                      backing: .buffered, defer: false)
        panel.title = "\(window.title) popup"
        panel.contentView = host
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.transient, .ignoresCycle]
        panel.acceptsMouseMovedEvents = true
        panel.appearance = window.effectiveAppearance
        panel.setFrame(OnePlusPopupPlacement.frame(trigger: triggerFrame, popupSize: host.frame.size,
                                                    screen: visibleFrame), display: false)
        window.addChildWindow(panel, ordered: .above)

        self.anchor = anchor
        parentWindow = window
        self.panel = panel
        self.session = session
        self.onClose = onClose
        // Search shrinks the panel to its matches and keeps the edge next to the trigger in place.
        let below = panel.frame.maxY <= triggerFrame.minY
        session.queryChanged = { [weak panel, weak session] in
            guard let panel, let session else { return }
            let rows = max(OnePlusPopupMetrics.contentHeight(entries: session.entries, density: density),
                           OnePlusPopupMetrics.padding * 2 + OnePlusPopupMetrics.itemHeight(for: density))
            var frame = panel.frame
            let fitted = min(rows + search, height)
            if below { frame.origin.y = frame.maxY - fitted }
            frame.size.height = fitted
            panel.setFrame(frame, display: true)
        }
        installMonitors(window: window, panel: panel)
        // Opens like the menu bar panel: a fade with a 4 pt move out of the trigger.
        let final = panel.frame
        let reduced = OnePlusMotion.reducesMotion
        if !reduced {
            panel.setFrame(final.offsetBy(dx: 0, dy: below ? OnePlusMotion.panelOffset : -OnePlusMotion.panelOffset),
                           display: false)
        }
        panel.alphaValue = 0
        panel.orderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = reduced ? OnePlusMotion.panelOpenReduced : OnePlusMotion.panelOpen
            context.timingFunction = OnePlusMotion.easeOutTiming
            panel.animator().alphaValue = 1
            if !reduced { panel.animator().setFrame(final, display: true) }
        }
    }

    private func select(_ id: UUID) {
        guard let item = session?.entries.compactMap(\.item).first(where: { $0.id == id }), item.isEnabled else { return }
        close(reason: .selection)
        item.action()
    }

    private func close(reason: OnePlusPopupCloseReason) {
        guard panel != nil || session != nil else { return }
        removeMonitorsAndObservers()
        if let panel {
            parentWindow?.removeChildWindow(panel)
            // A picked row closes at once so its action shows; other closes fade out in 100 ms.
            if reason == .selection || OnePlusMotion.reducesMotion {
                panel.orderOut(nil)
                panel.contentView = nil
            } else {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = OnePlusMotion.panelClose
                    context.timingFunction = OnePlusMotion.easeInTiming
                    panel.animator().alphaValue = 0
                }, completionHandler: {
                    MainActor.assumeIsolated {
                        panel.orderOut(nil)
                        panel.contentView = nil
                    }
                })
            }
        }
        let completion = onClose
        panel = nil
        session = nil
        anchor = nil
        parentWindow = nil
        onClose = nil
        completion?(reason)
    }

    private func installMonitors(window: NSWindow, panel: NSPanel) {
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, Self.owns(event, parent: self.parentWindow, popup: self.panel),
                  let key = Self.popupKey(for: event), self.session?.handle(key) == true else { return event }
            return nil
        }
        let mouseEvents: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: mouseEvents) { [weak self] event in
            guard let self else { return event }
            if event.windowNumber == panel.windowNumber || self.eventHitsAnchor(event) { return event }
            self.close(reason: .outsideClick)
            return event
        }
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: mouseEvents) { [weak self] _ in
            self?.close(reason: .outsideClick)
        }
        let center = NotificationCenter.default
        for name in [NSWindow.didMoveNotification, NSWindow.didResizeNotification, NSWindow.willCloseNotification, NSWindow.didResignKeyNotification] {
            observers.append(center.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.close(reason: .windowChange) }
            })
        }
        observers.append(center.addObserver(forName: NSApplication.didResignActiveNotification,
                                            object: NSApp, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.close(reason: .appDeactivation) }
        })
    }

    private func removeMonitorsAndObservers() {
        if let localKeyMonitor { NSEvent.removeMonitor(localKeyMonitor) }
        if let localMouseMonitor { NSEvent.removeMonitor(localMouseMonitor) }
        if let globalMouseMonitor { NSEvent.removeMonitor(globalMouseMonitor) }
        localKeyMonitor = nil
        localMouseMonitor = nil
        globalMouseMonitor = nil
        let center = NotificationCenter.default
        observers.forEach(center.removeObserver)
        observers.removeAll()
    }

    private func eventHitsAnchor(_ event: NSEvent) -> Bool {
        guard let anchor, let window = anchor.window, event.windowNumber == window.windowNumber else { return false }
        return anchor.bounds.contains(anchor.convert(event.locationInWindow, from: nil))
    }

    static func owns(_ event: NSEvent, parent: NSWindow?, popup: NSWindow?) -> Bool {
        guard let window = event.window else { return false }
        return window === parent || window === popup
    }

    static func popupKey(for event: NSEvent) -> OnePlusPopupKey? {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard modifiers.intersection([.command, .control, .option]).isEmpty else { return nil }
        switch event.keyCode {
        case 126: return modifiers.contains(.shift) ? nil : .up
        case 125: return modifiers.contains(.shift) ? nil : .down
        case 36, 76: return modifiers.contains(.shift) ? nil : .select
        case 53: return modifiers.contains(.shift) ? nil : .escape
        case 51: return .backspace
        default:
            // Letters, digits, and the punctuation of host names and paths (".", "-", ":", "/") for search.
            let typable = CharacterSet.alphanumerics.union(.punctuationCharacters).union(.symbols)
            guard let characters = event.charactersIgnoringModifiers,
                  characters.count == 1,
                  characters.unicodeScalars.first.map(typable.contains) == true else { return nil }
            return .type(characters)
        }
    }
}
