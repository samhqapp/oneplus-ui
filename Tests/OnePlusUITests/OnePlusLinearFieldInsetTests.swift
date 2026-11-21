import AppKit
import SwiftUI
import XCTest
@testable import OnePlusUI

/// Raised-keys text fields and selects: the text sits on the field's vertical center (0.5 pt or less), and the
/// text's left inset equals the chevron's right inset, both `fieldInset` from the painted edge.
@MainActor
final class OnePlusLinearFieldInsetTests: XCTestCase {
    private let size = CGSize(width: 160, height: OnePlusLinearControlLook.raisedKeys.height)

    func testRaisedKeysFieldAndSelectCenterTextWithEqualInsets() throws {
        for appearance in [NSAppearance.Name.aqua, .darkAqua] {
            let field = try measure(OnePlusLinearTextField("HILT", text: .constant("HILT")), appearance, "field")
            let select = try measure(OnePlusLinearSelect(choices: [(0, "HILT")], selection: .constant(0),
                                                         accessibilityLabel: "Select"), appearance, "select")
            let inset = try XCTUnwrap(OnePlusLinearControlLook.raisedKeys.fieldInset)
            for (name, ink) in [("field", field), ("select", select)] {
                XCTAssertEqual(ink.textCenter, size.height / 2, accuracy: 0.5, "\(name) \(appearance) text center")
                // The H stem sits about 1 pt inside its advance box.
                XCTAssertEqual(ink.left, inset + 1, accuracy: 0.75, "\(name) \(appearance) left inset")
            }
            let right = try XCTUnwrap(select.right)
            XCTAssertEqual(right, select.left, accuracy: 0.75, "select \(appearance) chevron inset matches the text inset")
            XCTAssertEqual(try XCTUnwrap(select.glyphCenter), size.height / 2, accuracy: 0.5, "select \(appearance) chevron center")
        }
    }

    private struct Ink { var textCenter: CGFloat; var left: CGFloat; var right: CGFloat?; var glyphCenter: CGFloat? }

    private func measure<V: View>(_ view: V, _ appearance: NSAppearance.Name, _ name: String) throws -> Ink {
        let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height)
            .background(OnePlusLinearColor.fillGroup)
            .environment(\.onePlusLinearControlLook, .raisedKeys))
        let scale: CGFloat = 2
        let bitmap = try LinearRender.bitmap(host, size: size, scale: scale, appearance: appearance)
        if let dir = ProcessInfo.processInfo.environment["ONEPLUS_SHOT_DIR"] {
            try bitmap.representation(using: .png, properties: [:])?
                .write(to: URL(fileURLWithPath: dir).appendingPathComponent("field-inset-\(name)-\(appearance.rawValue).png"))
        }
        var columns: [Int: [Int]] = [:]
        // Skip the outer 2 px so the well's edge gradient never counts as ink.
        for y in 2..<(bitmap.pixelsHigh - 2) {
            for x in 2..<(bitmap.pixelsWide - 2) {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { continue }
                let level = (color.redComponent + color.greenComponent + color.blueComponent) / 3
                if appearance == .darkAqua ? level > 0.3 : level < 0.72 { columns[x, default: []].append(y) }
            }
        }
        let xs = columns.keys.sorted()
        let split = zip(xs, xs.dropFirst()).max { $0.1 - $0.0 < $1.1 - $1.0 }.map { ($0.0 + $0.1) / 2 } ?? Int.max
        func center(_ range: (Int) -> Bool) -> CGFloat? {
            let ys = columns.filter { range($0.key) }.flatMap(\.value)
            guard let top = ys.min(), let bottom = ys.max() else { return nil }
            return CGFloat(top + bottom + 1) / (2 * scale)
        }
        let hasGlyph = name == "select"
        let textCenter = try XCTUnwrap(center { !hasGlyph || $0 < split }, "\(name) has no ink")
        let left = CGFloat(try XCTUnwrap(xs.first)) / scale
        let right = hasGlyph ? CGFloat(bitmap.pixelsWide - 1 - (xs.last ?? 0)) / scale : nil
        let ink = Ink(textCenter: textCenter, left: left, right: right, glyphCenter: hasGlyph ? center { $0 > split } : nil)
        print("FieldInset \(name) \(appearance.rawValue): center \(ink.textCenter) left \(ink.left) right \(String(describing: ink.right)) glyph \(String(describing: ink.glyphCenter))")
        return ink
    }
}
