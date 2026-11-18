import AppKit

/// Arrow-free status panels use the shell's alpha outline for the native shadow.
@MainActor
public final class OnePlusMenuPresenter: NSObject {
    public static let didShowNotification = Notification.Name("OnePlusMenuPresenter.didShow")
    public var onClose: (() -> Void)?
    let window: NSPanel = MenuWindow(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                                     backing: .buffered, defer: false)
    private weak var anchor: NSView?
    private var monitors: [Any] = []
    private var observers: [NSObjectProtocol] = []
    private var workspaceObserver: NSObjectProtocol?

    public override init() {
        super.init()
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.hidesOnDeactivate = false
        window.level = .popUpMenu
        window.collectionBehavior = [.transient, .fullScreenAuxiliary]
        window.animationBehavior = .none
    }

    isolated deinit { removeMonitors(); window.orderOut(nil) }

    /// Bumped by every show and close, so a finished close fade orders out only the panel it faded.
    private var motionGeneration = 0
    private var closing = false
    /// The final frame while the open move runs, so a size change lands on it instead of a mid-move frame.
    private var openTarget: NSRect?

    public var isShown: Bool { window.isVisible && !closing }
    public var appearance: NSAppearance? {
        get { window.appearance }
        set { window.appearance = newValue }
    }
    public var contentViewController: NSViewController? {
        get { window.contentViewController }
        set { if window.contentViewController !== newValue { window.contentViewController = newValue } }
    }
    public var contentSize: NSSize {
        get { window.frame.size }
        set {
            guard newValue.width.isFinite, newValue.height.isFinite,
                  newValue.width > 0, newValue.height > 0, newValue != contentSize else { return }
            if let target = openTarget {
                let frame = NSRect(x: target.minX, y: target.maxY - newValue.height, width: newValue.width, height: newValue.height)
                openTarget = frame
                // A zero-length animator change replaces the running move, so the panel lands on its final frame now.
                NSAnimationContext.runAnimationGroup { $0.duration = 0; window.animator().setFrame(frame, display: true) }
            } else {
                let top = window.frame.maxY
                window.setContentSize(newValue)
                window.setFrameTopLeftPoint(NSPoint(x: window.frame.minX, y: top))
            }
            window.invalidateShadow()
        }
    }

    public func show(relativeTo rect: NSRect, of view: NSView, preferredEdge: NSRectEdge, takesFocus: Bool = true) {
        guard let owner = view.window, let screen = owner.screen else { return }
        anchor = view
        appearance = NSApp.appearance
        let trigger = owner.convertToScreen(view.convert(rect, to: nil))
        let wasVisible = window.isVisible && !closing
        cancelClose()
        let frame = Self.frame(anchor: trigger, size: contentSize, screen: screen.visibleFrame)
        window.setFrame(frame, display: false)
        window.contentView?.layoutSubtreeIfNeeded()
        window.contentView?.displayIfNeeded()
        window.invalidateShadow()
        removeMonitors()
        installMonitors()
        if !wasVisible { animateOpen(to: frame) }
        window.orderFrontRegardless()
        if takesFocus { window.makeKey() }
        NotificationCenter.default.post(name: Self.didShowNotification, object: self)
    }

    /// Native snap open: the first frame already has the final layout; only alpha and a 4 pt move run.
    /// Reduce Motion fades only.
    private func animateOpen(to frame: NSRect) {
        let reduced = OnePlusMotion.reducesMotion
        window.alphaValue = 0
        if !reduced {
            window.setFrameOrigin(NSPoint(x: frame.minX, y: frame.minY + OnePlusMotion.panelOffset))
            openTarget = frame
        }
        let generation = motionGeneration
        NSAnimationContext.runAnimationGroup { context in
            context.duration = reduced ? OnePlusMotion.panelOpenReduced : OnePlusMotion.panelOpen
            context.timingFunction = OnePlusMotion.easeOutTiming
            window.animator().alphaValue = 1
            if !reduced { window.animator().setFrame(frame, display: true) }
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.motionGeneration == generation else { return }
                self.openTarget = nil
                self.window.invalidateShadow()
            }
        }
    }

    /// Stops a running close fade and shows the panel fully.
    private func cancelClose() {
        motionGeneration += 1
        openTarget = nil
        guard closing else { return }
        closing = false
        NSAnimationContext.runAnimationGroup { $0.duration = 0; window.animator().alphaValue = 1 }
    }

    /// Arms the dismissal monitors for a panel the host orders itself while the app is inactive.
    /// It never orders the panel front, so it never activates the app.
    public func armDismissal(anchoredTo view: NSView) {
        cancelClose()
        anchor = view
        removeMonitors()
        installMonitors()
    }

    public func performClose(_ sender: Any?) { close() }
    public func close() {
        let wasShown = isShown
        removeMonitors()
        anchor = nil
        if wasShown { fadeOut() } else if !closing { window.orderOut(nil) }
        if wasShown { onClose?() }
    }

    /// Native snap close: a 100 ms ease-in fade with no move; instant under Reduce Motion.
    private func fadeOut() {
        motionGeneration += 1
        openTarget = nil
        guard !OnePlusMotion.reducesMotion else { window.orderOut(nil); window.alphaValue = 1; return }
        closing = true
        let generation = motionGeneration
        NSAnimationContext.runAnimationGroup { context in
            context.duration = OnePlusMotion.panelClose
            context.timingFunction = OnePlusMotion.easeInTiming
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.motionGeneration == generation else { return }
                self.closing = false
                self.window.orderOut(nil)
                self.window.alphaValue = 1
            }
        }
    }

    static func frame(anchor: NSRect, size: NSSize, screen: NSRect) -> NSRect {
        NSRect(x: min(max(screen.minX, anchor.midX - size.width / 2), screen.maxX - size.width),
               y: max(screen.minY, min(anchor.minY, screen.maxY) - size.height),
               width: size.width, height: size.height)
    }

    private func owns(_ candidate: NSWindow?) -> Bool {
        var candidate = candidate
        while let current = candidate {
            if current === window { return true }
            candidate = current.sheetParent ?? current.parent
        }
        return false
    }

    private func installMonitors() {
        let mouse: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        if let monitor = NSEvent.addLocalMonitorForEvents(matching: mouse.union(.keyDown), handler: { [weak self] event in
            guard let self else { return event }
            if event.type == .keyDown {
                if event.window === self.window, event.keyCode == 53,
                   event.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty,
                   self.window.attachedSheet == nil, self.window.childWindows?.isEmpty != false {
                    self.close()
                    return nil
                }
            } else if !self.owns(event.window) {
                if let anchor = self.anchor, event.window === anchor.window,
                   anchor.bounds.contains(anchor.convert(event.locationInWindow, from: nil)) { return event }
                self.close()
            }
            return event
        }) { monitors.append(monitor) }
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: mouse, handler: { [weak self] event in
            guard let self else { return }
            // Status-bar events can arrive through the global monitor before the action.
            // Let the anchor's action toggle its panel instead of closing then reopening it.
            let point = event.window?.convertPoint(toScreen: event.locationInWindow) ?? event.locationInWindow
            if let anchor = self.anchor, let owner = anchor.window,
               owner.convertToScreen(anchor.convert(anchor.bounds, to: nil)).contains(point) { return }
            self.close()
        }) { monitors.append(monitor) }
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: NSApplication.didResignActiveNotification,
                                            object: NSApp, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.close() }
        })
        // A Space switch (for example into a full-screen app) dismisses the panel like a native menu.
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.close() }
            }
        if let owner = anchor?.window {
            for name in [NSWindow.didMoveNotification, NSWindow.willCloseNotification] {
                observers.append(center.addObserver(forName: name, object: owner, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.close() }
                })
            }
        }
    }

    private func removeMonitors() {
        monitors.forEach(NSEvent.removeMonitor)
        monitors.removeAll()
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
        if let workspaceObserver { NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver) }
        workspaceObserver = nil
    }
}

private final class MenuWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
