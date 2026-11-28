import AppKit
import SwiftUI
import XCTest
@testable import OnePlusUI

/// Owner bugs 2026-11-28: the "Pro" text touched the tag's left side, and a full-width band poked out of the
/// rounded corners of an inset group (the Notes settings preview).
@MainActor
final class OnePlusProTagAndClipTests: XCTestCase {
    func testProTagLettersSitInTheMiddleOfAWholePointPill() {
        for icon: CGFloat in [32, 52, 84] {
            let tag = OnePlusProTag(icon: icon), ink = tag.letters.boundingBoxOfPath
            XCTAssertEqual(tag.pill.width, tag.pill.width.rounded(), "\(icon) pill width is whole points")
            XCTAssertEqual(tag.pill.height, tag.pill.height.rounded(), "\(icon) pill height is whole points")
            XCTAssertEqual(ink.minX, tag.pill.width - ink.maxX, accuracy: 0.01, "\(icon) left space equals right space")
            XCTAssertEqual(ink.minY, tag.pill.height - ink.maxY, accuracy: 0.01, "\(icon) top space equals bottom space")
            XCTAssertGreaterThanOrEqual(ink.minX, 3, "\(icon) letters keep clear of the 1 pt border")
        }
    }

    /// Set ONEPLUS_PROTAG_RENDER to a folder to save a 2x render of the tag on a 52 pt tile, to check its edges by eye.
    func testProTagRender() throws {
        guard let folder = ProcessInfo.processInfo.environment["ONEPLUS_PROTAG_RENDER"] else { return }
        for name in [NSAppearance.Name.aqua, .darkAqua] {
            let view = RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.gray).frame(width: 52, height: 52)
                .onePlusProTag(52).frame(width: 80, height: 80).background(OnePlusLinearColor.window)
            let render = try LinearRender.bitmap(NSHostingView(rootView: view), size: CGSize(width: 80, height: 80), scale: 2, appearance: name)
            try render.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: folder).appendingPathComponent("protag-\(name.rawValue).png"))
        }
    }

    func testInsetGroupClipsItsContentToTheRoundedCorners() throws {
        let size = CGSize(width: 200, height: 80), red = NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        let view = OnePlusLinearAppletGroup { Color(nsColor: red).frame(height: 80) }
            .environment(\.onePlusLinearEditorial, true)
            .frame(width: size.width, height: size.height)
            .background(Color.blue)
        let render = try LinearRender.bitmap(NSHostingView(rootView: view), size: size, scale: 2, appearance: .darkAqua)
        for (x, y) in [(1, 1), (398, 1), (1, 158), (398, 158)] {
            XCTAssertFalse(LinearRender.close(render.colorAt(x: x, y: y), red, tolerance: 0.2), "corner \(x),\(y) shows the content")
        }
        XCTAssertTrue(LinearRender.close(render.colorAt(x: 200, y: 80), red, tolerance: 0.05),
                      "the middle shows the content: \(String(describing: render.colorAt(x: 200, y: 80)))")
    }
}
