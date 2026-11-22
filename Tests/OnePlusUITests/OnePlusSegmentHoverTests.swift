import AppKit
import XCTest
@testable import OnePlusUI

@MainActor
final class OnePlusSegmentHoverTests: XCTestCase {
    /// The hovered segment must stand clearly off the well (the old 3% wash measured about 1.08:1).
    func testSegmentHoverStandsOffTheWell() {
        func luminance(_ c: NSColor) -> Double {
            func channel(_ v: CGFloat) -> Double { let v = Double(v); return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
            return 0.2126 * channel(c.redComponent) + 0.7152 * channel(c.greenComponent) + 0.0722 * channel(c.blueComponent)
        }
        for name in [NSAppearance.Name.aqua, .darkAqua] {
            let well = luminance(LinearRender.resolve(OnePlusLinearColor.fillTrack, in: name))
            let hover = luminance(LinearRender.resolve(OnePlusLinearColor.fillSegmentHover, in: name))
            XCTAssertGreaterThanOrEqual((max(well, hover) + 0.05) / (min(well, hover) + 0.05), 1.18, "\(name)")
        }
    }
}
