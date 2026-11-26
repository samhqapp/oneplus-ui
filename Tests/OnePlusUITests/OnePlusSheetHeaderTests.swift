import AppKit
import SwiftUI
import XCTest
@testable import OnePlusUI

@MainActor
final class OnePlusSheetHeaderTests: XCTestCase {
    /// The red close light and the title caps share the 22 pt centerline (once they sat 6.5 pt apart).
    func testCloseLightAndTitleShareCenterline() throws {
        let saved = NSApplication.shared.appearance
        defer { NSApplication.shared.appearance = saved }
        for name in [NSAppearance.Name.aqua, .darkAqua] {
            NSApplication.shared.appearance = NSAppearance(named: name)
            let bitmap = try render(OnePlusSheet("Extracted Text", close: {}) { Color.clear.frame(height: 40) })
            let light = try XCTUnwrap(inkCenter(bitmap, pixels: 26...54))
            let title = try XCTUnwrap(titleStemCenter(bitmap, from: 60))
            let message = "Center the close light and the title caps on OnePlusMetrics.appletCenterline in OnePlusSheet's title row"
            XCTAssertEqual(light, OnePlusMetrics.appletCenterline, accuracy: 0.5, "\(name.rawValue) light: \(message)")
            XCTAssertEqual(title, OnePlusMetrics.appletCenterline, accuracy: 0.5, "\(name.rawValue) title: \(message)")
        }
    }

    private func render(_ view: some View) throws -> NSBitmapImageRep {
        let host = NSHostingView(rootView: view)
        let size = host.fittingSize
        let window = NSWindow(contentRect: CGRect(x: -10000, y: -10000, width: size.width, height: size.height),
                              styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.appearance = NSApplication.shared.appearance
        window.contentView = host
        defer { window.close() }
        host.frame = CGRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
        let bitmap = try XCTUnwrap(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * 2),
            pixelsHigh: Int(size.height * 2), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        bitmap.size = size
        host.cacheDisplay(in: host.bounds, to: bitmap)
        return bitmap
    }

    private func isInk(_ bitmap: NSBitmapImageRep, _ x: Int, _ y: Int) -> Bool {
        guard let bg = bitmap.colorAt(x: 4, y: 4)?.usingColorSpace(.deviceRGB),
              let c = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { return false }
        return max(abs(c.redComponent - bg.redComponent), abs(c.greenComponent - bg.greenComponent),
                   abs(c.blueComponent - bg.blueComponent)) > 0.25
    }

    private func inkCenter(_ bitmap: NSBitmapImageRep, pixels: ClosedRange<Int>) -> CGFloat? {
        let rows = (0..<Int(OnePlusMetrics.sheetTitleRow * 2)).filter { y in
            pixels.contains { isInk(bitmap, $0, y) }
        }
        guard let top = rows.first, let bottom = rows.last else { return nil }
        return CGFloat(top + bottom + 1) / 4
    }

    /// The first capital's left stem runs exactly from cap top to baseline.
    private func titleStemCenter(_ bitmap: NSBitmapImageRep, from x: Int) -> CGFloat? {
        let rows = 0..<Int(OnePlusMetrics.sheetTitleRow * 2)
        guard let stem = (x * 2..<bitmap.pixelsWide).first(where: { c in rows.contains { isInk(bitmap, c, $0) } })
        else { return nil }
        return inkCenter(bitmap, pixels: stem...stem + 1)
    }
}
