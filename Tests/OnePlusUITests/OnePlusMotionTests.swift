import Foundation
import SwiftUI
import XCTest
@testable import OnePlusUI

final class OnePlusMotionTests: XCTestCase {
    func testNativeSnapTokens() {
        XCTAssertEqual(OnePlusMotion.panelOpen, 0.14)
        XCTAssertEqual(OnePlusMotion.panelOpenReduced, 0.10)
        XCTAssertEqual(OnePlusMotion.panelClose, 0.10)
        XCTAssertEqual(OnePlusMotion.panelOffset, 4)
        XCTAssertEqual(OnePlusMotion.hoverIn, 0.06)
        XCTAssertEqual(OnePlusMotion.hoverOut, 0.15)
        XCTAssertEqual(OnePlusMotion.selection, 0.12)
        XCTAssertEqual(OnePlusMotion.tabSlide, 0.18)
        XCTAssertEqual(OnePlusMotion.segment, 0.2)
        XCTAssertEqual(OnePlusMotion.knob, 0.14)
        XCTAssertNil(OnePlusMotion.resolved(0.14, style: .instant, reduceMotion: false))
        XCTAssertNil(OnePlusMotion.resolved(0.14, style: .quiet, reduceMotion: true))
        XCTAssertNotNil(OnePlusMotion.resolved(0.14, style: .quiet, reduceMotion: false))
        XCTAssertEqual(EnvironmentValues().onePlusLinearMotion, .quiet)
    }

    /// Hover may fade a fill, but never moves or scales anything.
    func testSharedHoverSourcesHaveNoGeometryMotion() throws {
        let forbidden = try NSRegularExpression(pattern: #"(scaleEffect|offset)\s*\([^)]*\b(hover|hovering|isHovered)\b"#)
        let sources = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources/OnePlusUI")
        let files = try XCTUnwrap(FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil))
        for case let file as URL in files where file.pathExtension == "swift" {
            let source = try String(contentsOf: file, encoding: .utf8)
            XCTAssertNil(forbidden.firstMatch(in: source, range: NSRange(source.startIndex..., in: source)), file.path)
        }
        for regression in [".scaleEffect(hover ? 1.01 : 1)", ".offset(x: hover ? 2 : 0)"] {
            XCTAssertNotNil(forbidden.firstMatch(in: regression, range: NSRange(regression.startIndex..., in: regression)))
        }
    }
}
