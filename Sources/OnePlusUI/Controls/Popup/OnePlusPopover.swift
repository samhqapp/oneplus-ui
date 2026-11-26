import AppKit
import SwiftUI

public extension View {
    /// A popover that opens like the popup menus: a 140 ms fade with a 4 pt move away from its anchor, and a
    /// 100 ms fade out. SwiftUI's `.popover` uses the slower system zoom. The fill is opaque, the arrow stays.
    func onePlusPopover<Content: View>(isPresented: Binding<Bool>, arrowEdge: Edge = .bottom,
                                       @ViewBuilder content: @escaping () -> Content) -> some View {
        background(OnePlusPopoverAnchor(isPresented: isPresented, arrowEdge: arrowEdge,
                                        content: { AnyView(content().onePlusOpaquePopover()) }))
    }
}

private struct OnePlusPopoverAnchor: NSViewRepresentable {
    @Binding var isPresented: Bool
    let arrowEdge: Edge
    let content: () -> AnyView

    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ view: NSView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onClose = { isPresented = false }
        if isPresented {
            coordinator.show(content(), from: view, edge: arrowEdge)
        } else {
            coordinator.dismiss()
        }
    }

    static func dismantleNSView(_ view: NSView, coordinator: Coordinator) { coordinator.dismiss() }

    @MainActor
    final class Coordinator: NSObject, NSPopoverDelegate {
        private var popover: NSPopover?
        private var host: NSHostingController<AnyView>?
        var onClose: () -> Void = {}

        func show(_ content: AnyView, from view: NSView, edge: Edge) {
            if let host, popover?.isShown == true { host.rootView = content; return }
            guard view.window != nil else { return }
            let host = NSHostingController(rootView: content)
            host.sizingOptions = .preferredContentSize
            let popover = NSPopover()
            popover.contentViewController = host
            popover.behavior = .transient
            popover.animates = false
            popover.delegate = self
            self.host = host
            self.popover = popover
            popover.show(relativeTo: view.bounds, of: view, preferredEdge: Self.rectEdge(edge))
            guard let window = host.view.window else { return }
            let final = window.frame
            let reduced = OnePlusMotion.reducesMotion
            var start = final
            // Move away from the anchor: a popover below its anchor starts 4 pt higher.
            switch edge {
            case .bottom: start.origin.y += OnePlusMotion.panelOffset
            case .top: start.origin.y -= OnePlusMotion.panelOffset
            case .leading: start.origin.x += OnePlusMotion.panelOffset
            case .trailing: start.origin.x -= OnePlusMotion.panelOffset
            }
            window.alphaValue = 0
            if !reduced { window.setFrame(start, display: false) }
            NSAnimationContext.runAnimationGroup { context in
                context.duration = reduced ? OnePlusMotion.panelOpenReduced : OnePlusMotion.panelOpen
                context.timingFunction = OnePlusMotion.easeOutTiming
                window.animator().alphaValue = 1
                if !reduced { window.animator().setFrame(final, display: true) }
            }
        }

        func dismiss() {
            guard let popover, popover.isShown, let window = host?.view.window else { cleanUp(); return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = OnePlusMotion.panelClose
                context.timingFunction = OnePlusMotion.easeInTiming
                window.animator().alphaValue = 0
            }, completionHandler: { MainActor.assumeIsolated { popover.close() } })
        }

        nonisolated func popoverDidClose(_ notification: Notification) {
            MainActor.assumeIsolated {
                cleanUp()
                onClose()
            }
        }

        private func cleanUp() {
            popover = nil
            host = nil
        }

        private static func rectEdge(_ edge: Edge) -> NSRectEdge {
            switch edge {
            case .top: .maxY
            case .bottom: .minY
            case .leading: .minX
            case .trailing: .maxX
            }
        }
    }
}
