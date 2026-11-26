import AppKit
import SwiftUI
import XCTest
@testable import OnePlusUI

@MainActor
final class OnePlusPopoverSizeTests: XCTestCase {
    func testPopoverWindowHugsItsContent() throws {
        let window = NSWindow(contentRect: CGRect(x: -20000, y: -20000, width: 200, height: 200), styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let anchor = NSView(frame: CGRect(x: 90, y: 90, width: 20, height: 20))
        window.contentView = NSView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        window.contentView?.addSubview(anchor)
        let coordinator = OnePlusPopoverAnchor.Coordinator()
        let content = AnyView(VStack(alignment: .leading) { Text("Hop 9"); Text("IP 172.25.187.26") }
            .padding(12).frame(width: 220).onePlusOpaquePopover())
        coordinator.show(content, from: anchor, edge: .bottom)
        let popover = try XCTUnwrap(coordinator.popover)
        let host = try XCTUnwrap(coordinator.host)
        let fitting = host.view.fittingSize
        XCTAssertEqual(popover.contentSize.height, fitting.height, accuracy: 1)
        if let popoverWindow = host.view.window {
            let arrowAndShadow: CGFloat = 40
            XCTAssertLessThanOrEqual(popoverWindow.frame.height, fitting.height + arrowAndShadow,
                                     "Popover window is taller than its content: size it from fittingSize before show.")
        }
        popover.close()
    }
}
