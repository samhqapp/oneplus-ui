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
        overlay(alignment: .bottomTrailing) {
            Text("Pro").font(.system(size: max(7, size * 0.2), weight: .bold, design: .rounded)).foregroundStyle(.white)
                .padding(.horizontal, size * 0.07).padding(.vertical, size * 0.025)
                .background(Capsule().fill(OnePlusLinearColor.proCoralGradient))
                .overlay(Capsule().strokeBorder(.white.opacity(0.9), lineWidth: max(0.75, size / 40)))
                .offset(x: size * 0.06, y: size * 0.04)
                .accessibilityHidden(true)
        }
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
