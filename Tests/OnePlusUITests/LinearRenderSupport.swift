import AppKit
import SwiftUI
import XCTest

/// Offscreen hosting and APCA helpers shared by the v15 render tests.
@MainActor
enum LinearRender {
    static func attach<V: View>(_ host: NSHostingView<V>, size: CGSize, appearance: NSAppearance.Name = .darkAqua) -> NSWindow {
        let window = NSWindow(contentRect: CGRect(origin: CGPoint(x: -10000, y: -10000), size: size),
                              styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: appearance)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        return window
    }

    static func bitmap<V: View>(_ host: NSHostingView<V>, size: CGSize, scale: CGFloat, appearance: NSAppearance.Name) throws -> NSBitmapImageRep {
        let window = attach(host, size: size, appearance: appearance)
        defer { window.close() }
        return try capture(host, size: size, scale: scale)
    }

    static func capture(_ host: NSView, size: CGSize, scale: CGFloat) throws -> NSBitmapImageRep {
        host.frame = CGRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
        let bitmap = try XCTUnwrap(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
                                                    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                                    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        bitmap.size = size
        host.cacheDisplay(in: host.bounds, to: bitmap)
        return bitmap
    }

    static func close(_ color: NSColor?, _ target: NSColor, tolerance: CGFloat = 0.06) -> Bool {
        guard let color = color?.usingColorSpace(.sRGB), let target = target.usingColorSpace(.sRGB) else { return false }
        return abs(color.redComponent - target.redComponent) < tolerance && abs(color.greenComponent - target.greenComponent) < tolerance
            && abs(color.blueComponent - target.blueComponent) < tolerance
    }

    /// A token resolved in one appearance, composited over `ground` when it is translucent.
    static func resolve(_ color: Color, over ground: Color? = nil, in name: NSAppearance.Name) -> NSColor {
        var result = NSColor.black
        NSAppearance(named: name)!.performAsCurrentDrawingAppearance {
            let top = NSColor(color).usingColorSpace(.sRGB)!
            guard let ground, top.alphaComponent < 1 else { result = top; return }
            let base = NSColor(ground).usingColorSpace(.sRGB)!
            let a = top.alphaComponent
            result = NSColor(srgbRed: top.redComponent * a + base.redComponent * (1 - a), green: top.greenComponent * a + base.greenComponent * (1 - a),
                             blue: top.blueComponent * a + base.blueComponent * (1 - a), alpha: 1)
        }
        return result
    }

    // APCA 0.0.98G lightness contrast, as in OnePlusButtonAlignmentTests.
    static func apcaLc(_ text: NSColor, _ background: NSColor) -> Double {
        func luminance(_ rgb: NSColor) -> Double {
            let y = 0.2126729 * pow(rgb.redComponent, 2.4) + 0.7151522 * pow(rgb.greenComponent, 2.4) + 0.0721750 * pow(rgb.blueComponent, 2.4)
            return y < 0.022 ? y + pow(0.022 - y, 1.414) : y
        }
        let ink = luminance(text), ground = luminance(background)
        if ground > ink {
            let s = (pow(ground, 0.56) - pow(ink, 0.57)) * 1.14
            return s < 0.1 ? 0 : (s - 0.027) * 100
        }
        let s = (pow(ground, 0.65) - pow(ink, 0.62)) * 1.14
        return s > -0.1 ? 0 : (s + 0.027) * 100
    }
}
