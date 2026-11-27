import AppKit
import SwiftUI
import XCTest
@testable import OnePlusUI

/// A pointer click anywhere on a tool row's text must open the tool. AXPress alone does not prove it: the
/// row's open button kept its accessibility action while its clear label took no clicks (2026-11-28).
@MainActor
final class OnePlusToolRowClickTests: XCTestCase {
    private final class Counter { var opens = 0 }

    func testEditorialRowOpensOnAClickOverItsText() throws {
        let counter = Counter()
        try click(OnePlusLinearEditorialToolRow("Awake", summary: "Keep the Mac awake", icon: Image(systemName: "cup.and.saucer"),
                                                isOn: true, shortcut: "⌘2", isFavorite: .constant(false)) { counter.opens += 1 },
                  at: CGPoint(x: 200, y: 24))
        XCTAssertEqual(counter.opens, 1, "A click on the row's summary must open the tool.")
    }

    func testToolRowOpensOnAClickOverItsText() throws {
        let counter = Counter()
        try click(OnePlusLinearToolRow("Awake", summary: "Keep the Mac awake", icon: Image(systemName: "cup.and.saucer"),
                                       isEnabled: .constant(true), isFavorite: .constant(false)) { counter.opens += 1 },
                  at: CGPoint(x: 260, y: 18))
        XCTAssertEqual(counter.opens, 1, "A click on the row's summary must open the tool.")
    }

    /// Failing and passing case for the rule: a plain button with only a `Color.clear` label takes no pointer
    /// clicks; give the label `.contentShape(Rectangle())` so the whole area is the hit target.
    func testClearLabelNeedsAContentShape() throws {
        let counter = Counter()
        try click(Button { counter.opens += 1 } label: { Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity) }
            .buttonStyle(.plain), at: CGPoint(x: 200, y: 24))
        XCTAssertEqual(counter.opens, 0)
        try click(Button { counter.opens += 1 } label: {
            Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity).contentShape(Rectangle())
        }.buttonStyle(.plain), at: CGPoint(x: 200, y: 24))
        XCTAssertEqual(counter.opens, 1)
    }

    /// Sends a mouse down and up to the hosting view at `point` (top-left origin) in an offscreen window.
    private func click<V: View>(_ view: V, at point: CGPoint) throws {
        let size = CGSize(width: 600, height: 48)
        let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
        let window = LinearRender.attach(host, size: size)
        defer { window.close() }
        window.orderBack(nil)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        let location = host.convert(CGPoint(x: point.x, y: size.height - point.y), to: nil)
        for (index, type) in [NSEvent.EventType.leftMouseDown, .leftMouseUp].enumerated() {
            let event = try XCTUnwrap(NSEvent.mouseEvent(with: type, location: location, modifierFlags: [],
                                                         timestamp: Double(index) * 0.05, windowNumber: window.windowNumber,
                                                         context: nil, eventNumber: index, clickCount: 1,
                                                         pressure: type == .leftMouseDown ? 1 : 0))
            window.sendEvent(event)
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
    }
}
