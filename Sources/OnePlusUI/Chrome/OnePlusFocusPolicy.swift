import AppKit
import ObjectiveC
import Observation
import SwiftUI

@MainActor @Observable
public final class OnePlusFocusPolicy {
    public static let shared = OnePlusFocusPolicy()
    public private(set) var showsFocus = false
    @ObservationIgnored private var installed = false
    @ObservationIgnored private var voiceOver: NSKeyValueObservation?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var keyboardObserver: NSObjectProtocol?
    @ObservationIgnored private var eventMonitor: Any?
    @ObservationIgnored private let windows = NSHashTable<NSWindow>.weakObjects()

    public var eventMonitorOwnerCount: Int { eventMonitor == nil ? 0 : 1 }
    public var observerOwnerCount: Int { observers.count + (voiceOver == nil ? 0 : 1) + (keyboardObserver == nil ? 0 : 1) }

    public static func visualsEnabled(fullKeyboardAccess: Bool, voiceOver: Bool) -> Bool {
        fullKeyboardAccess || voiceOver
    }

    public static func acceptsFocus(isVisible: Bool, pointer: Bool, textInput: Bool,
                                    selectionInput: Bool = false) -> Bool {
        isVisible && (!pointer || textInput || selectionInput)
    }

    public func install() {
        guard !installed else { return }
        installed = true
        Self.installResponderHook()
        refresh()
        voiceOver = NSWorkspace.shared.observe(\.isVoiceOverEnabled) { [weak self] _, _ in
            Task { @MainActor in self?.refresh() }
        }
        let center = NotificationCenter.default
        for name in [NSApplication.didBecomeActiveNotification, UserDefaults.didChangeNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            })
        }
        keyboardObserver = DistributedNotificationCenter.default().addObserver(
            forName: .init("com.apple.KeyboardUIModeChanged"), object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            }
        // Only windows that host OnePlusFocusReader (or call configure) are managed; per-event didUpdate work is avoided.
        observers.append(center.addObserver(forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main) { [weak self] note in
            let window = note.object as? NSWindow
            MainActor.assumeIsolated {
                if let window, self?.manages(window) == true { Self.clearInvalidFocus(in: window) }
            }
        })
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
            guard let self else { return event }
            self.refresh()
            guard let window = event.window, self.manages(window) else { return event }
            if Self.isPointerEvent(event.type) {
                Self.dismissPointerFocus(in: window, at: event.locationInWindow)
            } else if event.type == .keyDown {
                Self.clearInvalidFocus(in: window)
            }
            return event
        }
    }

    public func refresh() {
        update(fullKeyboardAccess: NSApp.isFullKeyboardAccessEnabled, voiceOver: NSWorkspace.shared.isVoiceOverEnabled)
    }

    public func stop() {
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
        eventMonitor = nil
        voiceOver = nil
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
        if let keyboardObserver { DistributedNotificationCenter.default().removeObserver(keyboardObserver) }
        keyboardObserver = nil
        windows.removeAllObjects()
        installed = false
    }

    func update(fullKeyboardAccess: Bool, voiceOver: Bool) {
        let value = Self.visualsEnabled(fullKeyboardAccess: fullKeyboardAccess, voiceOver: voiceOver)
        guard showsFocus != value else { return }
        showsFocus = value
        for window in windows.allObjects {
            configureRings(window.contentView)
            window.contentView?.needsDisplay = true
        }
    }

    func manages(_ window: NSWindow) -> Bool { windows.member(window) != nil }

    public func configure(_ window: NSWindow) {
        install()
        guard !manages(window) else {
            Self.clearInvalidFocus(in: window)
            return
        }
        windows.add(window)
        window.initialFirstResponder = nil
        if !showsFocus, !Self.isTextInput(window.firstResponder), !Self.isSelectionInput(window.firstResponder) {
            window.makeFirstResponder(window)
        }
        Self.clearInvalidFocus(in: window)
        configureRings(window.contentView)
    }

    private static func clearInvalidFocus(in window: NSWindow) {
        guard let view = window.firstResponder as? NSView else { return }
        if view.window !== window || view.isHiddenOrHasHiddenAncestor || view.visibleRect.intersection(view.bounds).isEmpty ||
            !view.acceptsFirstResponder || (view as? NSControl)?.isEnabled == false {
            window.makeFirstResponder(window)
        }
    }

    private func configureRings(_ view: NSView?) {
        guard let view else { return }
        view.focusRingType = Self.ringType(for: view)
        view.needsDisplay = true
        view.subviews.forEach { configureRings($0) }
    }

    public static func dismissPointerFocus(in window: NSWindow, at point: NSPoint) {
        var hit = window.contentView?.hitTest(point)
        while let view = hit {
            if isTextInput(view) || isSelectionInput(view) { return }
            hit = view.superview
        }
        window.makeFirstResponder(window)
    }

    /// No AppKit focus ring, ever; keyboard focus shows only a control style's own fill.
    static func ringType(for view: NSView) -> NSFocusRingType { .none }

    private static func isTextInput(_ responder: NSResponder?) -> Bool {
        if let field = responder as? NSTextField { return field.isEditable || field.isSelectable }
        if let editor = responder as? NSTextView { return editor.isEditable || editor.isSelectable }
        return false
    }

    private static func isSelectionInput(_ responder: NSResponder?) -> Bool {
        responder is NSTableView || responder is NSCollectionView || responder is NSBrowser
    }

    static func isPointerEvent(_ type: NSEvent.EventType?) -> Bool {
        switch type {
        case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .otherMouseDown, .otherMouseUp: true
        default: false
        }
    }

    static func allows(_ responder: NSResponder?, in window: NSWindow, pointer: Bool) -> Bool {
        if !shared.installed { return true }
        if responder == nil || responder === window { return true }
        if !shared.manages(window) { return true }
        return acceptsFocus(isVisible: window.isVisible, pointer: pointer && !shared.showsFocus,
                            textInput: isTextInput(responder), selectionInput: isSelectionInput(responder))
    }

    private static var hookInstalled = false
    private static func installResponderHook() {
        guard !hookInstalled,
              let original = class_getInstanceMethod(NSWindow.self, #selector(NSWindow.makeFirstResponder(_:))),
              let replacement = class_getInstanceMethod(NSWindow.self, #selector(NSWindow.onePlusMakeFirstResponder(_:))) else { return }
        method_exchangeImplementations(original, replacement)
        hookInstalled = true
    }
}

extension NSWindow {
    @objc fileprivate func onePlusMakeFirstResponder(_ responder: NSResponder?) -> Bool {
        guard OnePlusFocusPolicy.shared.manages(self) else { return onePlusMakeFirstResponder(responder) }
        let pointer = OnePlusFocusPolicy.isPointerEvent(NSApp.currentEvent?.type)
        guard OnePlusFocusPolicy.allows(responder, in: self, pointer: pointer) else { return false }
        if let view = responder as? NSView {
            view.focusRingType = OnePlusFocusPolicy.ringType(for: view)
        }
        return onePlusMakeFirstResponder(responder)
    }
}

public extension View {
    /// The root modifier for every scene, panel, popover, and sheet: no system focus ring, ever. Keyboard focus shows
    /// only a control style's own fill.
    func onePlusFocusPolicy() -> some View {
        focusEffectDisabled()
            .background(OnePlusFocusReader())
    }
}

private struct OnePlusFocusReader: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { FocusView() }
    func updateNSView(_ view: NSView, context: Context) {}
    private final class FocusView: NSView {
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window { OnePlusFocusPolicy.shared.configure(window) }
        }
    }
}
