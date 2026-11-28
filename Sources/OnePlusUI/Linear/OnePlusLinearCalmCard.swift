import AppKit
import CoreText
import SwiftUI

public enum OnePlusLinearCalmCardMetrics {
    public static let radius: CGFloat = 14
    public static let padding: CGFloat = 20
    public static let gap: CGFloat = 18
    public static let headerGap: CGFloat = 16
    public static let title: CGFloat = 19
    public static let icon: CGFloat = 52
    public static let toolTile: CGFloat = 32
    public static let toolGap: CGFloat = 20
}

public extension OnePlusLinearColor {
    /// The "Pro" word: 4.7:1 on the white card (Light), 6.7:1 on the dark card.
    static let proCoral = Color(nsColor: dynamic("proCoral", light: 0xC9473A, dark: 0xFF7F6B))
    static let proCoralGradient = LinearGradient(colors: [Color(nsColor: dynamic("proCoralTop", light: 0xF4806C, dark: 0xF07A66)),
                                                          Color(nsColor: dynamic("proCoralBottom", light: 0xD44A3A, dark: 0xC8443A))],
                                                 startPoint: .top, endPoint: .bottom)
    static let calmCardTop = Color(nsColor: dynamic("calmCardTop", light: 0xFFFFFF, dark: 0x222222))
    static let calmCardBottom = Color(nsColor: dynamic("calmCardBottom", light: 0xFBFBFB, dark: 0x1D1D1D))
    static let calmCardRim = Color(nsColor: dynamic("calmCardRim", light: 0xFFFFFF, lightAlpha: 0.9, dark: 0xFFFFFF, darkAlpha: 0.07))
    static let calmCardShadow = Color(nsColor: dynamic("calmCardShadow", light: 0x000000, lightAlpha: 0.06, dark: 0x000000, darkAlpha: 0.30))
}

/// A calm feature card (Marketplace Pro): a soft top-lit fill, a hairline, a fine top rim and a low shadow.
public struct OnePlusLinearCalmCard<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: OnePlusLinearCalmCardMetrics.radius, style: .continuous)
        content
            .padding(OnePlusLinearCalmCardMetrics.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(shape.fill(LinearGradient(colors: [OnePlusLinearColor.calmCardTop, OnePlusLinearColor.calmCardBottom],
                                                  startPoint: .top, endPoint: .bottom)))
            .overlay(shape.strokeBorder(OnePlusLinearColor.line, lineWidth: 1))
            .overlay(shape.inset(by: 1).stroke(LinearGradient(colors: [OnePlusLinearColor.calmCardRim, .clear], startPoint: .top, endPoint: .center),
                                               lineWidth: 1))
            .shadow(color: OnePlusLinearColor.calmCardShadow, radius: 10, y: 3)
    }
}

/// macOS icon-tile lighting: light from the top, a fine top rim, a tight contact shadow and a soft drop.
struct OnePlusShadedTile: ViewModifier {
    let size: CGFloat
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
        content
            .overlay(LinearGradient(colors: [.white.opacity(0.16), .clear, .black.opacity(0.10)], startPoint: .top, endPoint: .bottom).clipShape(shape))
            .overlay(shape.strokeBorder(LinearGradient(colors: [.white.opacity(0.35), .white.opacity(0.04)], startPoint: .top, endPoint: .center),
                                        lineWidth: max(0.5, size / 64)))
            .shadow(color: .black.opacity(0.20), radius: size / 40, y: size / 64)
            .shadow(color: .black.opacity(0.12), radius: size / 10, y: size / 22)
    }
}

public extension View {
    /// Lights an icon tile of `size` points like a macOS app icon.
    func onePlusShadedTile(_ size: CGFloat) -> some View { modifier(OnePlusShadedTile(size: size)) }

    /// A small coral "Pro" capsule on the bottom-right corner of an icon of `size` points.
    func onePlusProTag(_ size: CGFloat) -> some View {
        let tag = OnePlusProTag(icon: size)
        return overlay(alignment: .bottomTrailing) {
            ZStack(alignment: .topLeading) {
                Capsule().fill(OnePlusLinearColor.proCoralGradient)
                Capsule().strokeBorder(.white.opacity(0.9), lineWidth: 1)
                Path(tag.letters).fill(.white)
            }
            .frame(width: tag.pill.width, height: tag.pill.height)
            .offset(x: tag.offset, y: tag.offset)
            .accessibilityHidden(true)
        }
    }
}

/// The "Pro" tag drawn from glyph outlines, so its padding is measured on the ink, not the text box: the same space
/// left and right, the same above and below. The pill and its offset are whole points, so its edge never falls
/// between pixels.
public struct OnePlusProTag {
    public let pill: CGSize
    /// The letters in pill coordinates (y down).
    public let letters: CGPath
    public let offset: CGFloat

    public init(icon: CGFloat) {
        let font = NSFont.systemFont(ofSize: max(8, (icon * 0.17).rounded()), weight: .bold)
        let rounded = font.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: font.pointSize) } ?? font
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: "Pro", attributes: [.font: rounded]))
        let glyphs = CGMutablePath()
        for run in CTLineGetGlyphRuns(line) as! [CTRun] {
            let count = CTRunGetGlyphCount(run)
            var ids = [CGGlyph](repeating: 0, count: count), points = [CGPoint](repeating: .zero, count: count)
            CTRunGetGlyphs(run, CFRange(), &ids)
            CTRunGetPositions(run, CFRange(), &points)
            let runFont = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName] as! CTFont
            for (id, point) in zip(ids, points) {
                guard let outline = CTFontCreatePathForGlyph(runFont, id, nil) else { continue }
                glyphs.addPath(outline, transform: CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: point.x, ty: -point.y))
            }
        }
        let ink = glyphs.boundingBoxOfPath
        let side = (icon * 0.08).rounded(), top = max(2, (icon * 0.04).rounded())
        pill = CGSize(width: (ink.width + side * 2).rounded(.up), height: (ink.height + top * 2).rounded(.up))
        var place = CGAffineTransform(translationX: (pill.width - ink.width) / 2 - ink.minX, y: (pill.height - ink.height) / 2 - ink.minY)
        letters = glyphs.copy(using: &place) ?? glyphs
        offset = (icon * 0.06).rounded()
    }
}

/// A dashed tile with a plus: "more to come" beside real icon tiles.
public struct OnePlusLinearAddTile: View {
    private let size: CGFloat
    public init(size: CGFloat = OnePlusLinearCalmCardMetrics.toolTile) { self.size = size }
    public var body: some View {
        RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
            .strokeBorder(OnePlusLinearColor.muted.opacity(0.7), style: StrokeStyle(lineWidth: 1.2, dash: [2.6, 2.6]))
            .overlay(Image(systemName: "plus").font(.system(size: size * 0.4, weight: .medium)).foregroundStyle(OnePlusLinearColor.muted))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// A tile, a medium name and a 12 pt secondary line: one item inside a calm card.
public struct OnePlusLinearCalmCardItem<Tile: View>: View {
    private let name: String
    private let line: String
    private let tile: Tile
    public init(_ name: String, line: String, @ViewBuilder tile: () -> Tile) { self.name = name; self.line = line; self.tile = tile() }
    public var body: some View {
        HStack(spacing: OnePlusLinearMetrics.appletRowPadding) {
            tile.frame(width: OnePlusLinearCalmCardMetrics.toolTile, height: OnePlusLinearCalmCardMetrics.toolTile)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).linearText(weight: .medium)
                Text(line).linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
