import AppKit
import SwiftUI
import XCTest
@testable import OnePlusUI

/// Main-window controls (`.raisedKeys`) keep their label on the control's center: the push and primary buttons,
/// the soft and raised keys, and the segment within 0.5 pt both ways; the select field within 0.5 pt vertically.
@MainActor
final class OnePlusLinearLabelCenteringTests: XCTestCase {
    private enum Axis { case both, vertical }

    func testMainWindowControlLabelsSitOnTheCenter() throws {
        let cases: [(String, AnyView, Axis)] = [
            ("push", AnyView(Button {} label: { Text("HILT") }.buttonStyle(OnePlusLinearButtonStyle(.push))), .both),
            ("primary", AnyView(Button {} label: { Text("HILT") }.buttonStyle(OnePlusLinearButtonStyle(.pushProminent))), .both),
            ("soft key", AnyView(Button {} label: { Text("HILT") }.buttonStyle(OnePlusLinearButtonStyle(.soft))), .both),
            ("raised key", AnyView(Button {} label: { Text("HILT") }.buttonStyle(OnePlusLinearButtonStyle(.raised))), .both),
            ("segment", AnyView(OnePlusLinearSegmented(choices: [(0, "HILT")], selection: .constant(0),
                                                       accessibilityLabel: "Segment", sizing: .fitted)), .both),
            ("select", AnyView(OnePlusLinearSelect(choices: [(0, "HILT")], selection: .constant(0),
                                                   accessibilityLabel: "Select", width: 160)), .vertical),
        ]
        for (name, view, axis) in cases {
            for appearance in [NSAppearance.Name.aqua, .darkAqua] {
                let offset = try labelOffset(view.environment(\.onePlusLinearControlLook, .raisedKeys),
                                             appearance: appearance, trimTrailingGlyph: axis == .vertical)
                let context = "\(name) \(appearance == .aqua ? "Light" : "Dark")"
                // Only Dark's sunken well lifts its text off the shaded groove; Light's flat well has none.
                let lift = axis == .vertical && appearance == .darkAqua ? OnePlusLinearMetrics.keyWellContentLift : 0
                if axis == .both { XCTAssertEqual(offset.x, 0, accuracy: 0.5, "\(context) label is off-center horizontally") }
                XCTAssertEqual(offset.y, -lift, accuracy: 0.5, "\(context) label is off-center vertically")
            }
        }
    }

    /// The painted label's center minus the control's center, in points, measured at 2x like a Retina screen.
    private func labelOffset<V: View>(_ view: V, appearance: NSAppearance.Name, trimTrailingGlyph: Bool) throws -> CGPoint {
        let size = NSHostingView(rootView: view).fittingSize
        let host = NSHostingView(rootView: view)
        let scale: CGFloat = 2
        let bitmap = try LinearRender.bitmap(host, size: size, scale: scale, appearance: appearance)
        // Gamma-encoded lightness, the way the eye judges the edge of the ink.
        let pixels = (0..<bitmap.pixelsHigh).flatMap { y in
            (0..<bitmap.pixelsWide).compactMap { x in
                bitmap.colorAt(x: x, y: y)?.usingColorSpace(.sRGB).flatMap { c in
                    c.alphaComponent > 0.9 ? (x: x, y: y, lum: (c.redComponent + c.greenComponent + c.blueComponent) / 3) : nil
                }
            }
        }
        // Ink is any pixel more than halfway from the face (the most common shade) to the strongest contrast.
        let face = Dictionary(grouping: pixels) { Int($0.lum * 64) }.max { $0.value.count < $1.value.count }
            .map { CGFloat($0.key) / 64 } ?? 0
        let strongest = pixels.map { abs($0.lum - face) }.max() ?? 0
        var ink = pixels.filter { abs($0.lum - face) > strongest / 2 }
        if trimTrailingGlyph {
            let columns = Set(ink.map(\.x)).sorted()
            if let gap = zip(columns, columns.dropFirst()).max(by: { $0.1 - $0.0 < $1.1 - $1.0 }) {
                ink = ink.filter { $0.x <= gap.0 }
            }
        }
        // Each edge sits where the ink's row or column coverage crosses half, so antialiasing gives subpixel edges.
        let xs = ink.map(\.x), ys = ink.map(\.y)
        let minX = try XCTUnwrap(xs.min()), maxX = try XCTUnwrap(xs.max())
        let minY = try XCTUnwrap(ys.min()), maxY = try XCTUnwrap(ys.max())
        var rows = [CGFloat](repeating: 0, count: bitmap.pixelsHigh), columns = [CGFloat](repeating: 0, count: bitmap.pixelsWide)
        for p in pixels where p.x >= minX - 1 && p.x <= maxX + 1 && p.y >= minY - 1 && p.y <= maxY + 1 {
            let coverage = min(1, abs(p.lum - face) / strongest)
            rows[p.y] = max(rows[p.y], coverage); columns[p.x] = max(columns[p.x], coverage)
        }
        func edge(_ profile: [CGFloat], _ inner: Int, _ step: Int) -> CGFloat {
            let outer = inner - step
            guard profile.indices.contains(outer) else { return CGFloat(inner) }
            return CGFloat(inner) - CGFloat(step) * (profile[inner] - 0.5) / max(profile[inner] - profile[outer], 0.001) + 0.5
        }
        let center = CGPoint(x: (edge(columns, minX, 1) + edge(columns, maxX, -1)) / (2 * scale),
                             y: (edge(rows, minY, 1) + edge(rows, maxY, -1)) / (2 * scale))
        return CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2)
    }
}
