import AppKit
import SwiftUI

public extension View {
    /// Put on the content of a SwiftUI `.popover`: the popover, arrow included, gets the popup menus' fully
    /// opaque fill instead of the see-through system material, in Light and Dark.
    func onePlusOpaquePopover() -> some View {
        background(OnePlusPopoverFill())
    }
}

/// NSPopover draws its translucent material in the frame view above its content window. A dynamic fill view
/// put first in that frame view covers the material; the frame view's own mask shapes it, arrow included.
private struct OnePlusPopoverFill: NSViewRepresentable {
    func makeNSView(context: Context) -> Probe { Probe() }
    func updateNSView(_ view: Probe, context: Context) {}

    final class Probe: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let content = window?.contentView, let frame = content.superview,
                  !frame.subviews.contains(where: { $0 is Fill }) else { return }
            let fill = Fill(frame: frame.bounds)
            fill.autoresizingMask = [.width, .height]
            // Right under the content: above the material, below the popover's own views.
            frame.addSubview(fill, positioned: .below, relativeTo: content)
        }
    }

    /// Draws in `draw(_:)`, so a Light or Dark switch repaints it with the matching color.
    final class Fill: NSView {
        override func draw(_ dirtyRect: NSRect) {
            NSColor(OnePlusPopupColor.background).setFill()
            dirtyRect.fill()
        }
    }
}
