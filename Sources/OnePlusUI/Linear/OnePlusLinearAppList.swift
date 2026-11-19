import SwiftUI

/// The "Apps by Sam" parts (owner picks, rounds 3-5, 2026-11-19): the featured banner with the Paid key, two cover
/// cards side by side with the cover edge to edge across the top, then open 64 pt rows. Every app has the App Store
/// style GET or OPEN capsule.
public enum OnePlusLinearAppListMetrics {
    public static let tileRadius: CGFloat = 12
    public static let tilePadding: CGFloat = 14
    public static let stackGap: CGFloat = 12
    public static let captionTop: CGFloat = 6
    public static let cardGap: CGFloat = 10
    public static let listTop: CGFloat = 4
    public static let featuredIcon: CGFloat = 96
    public static let featuredTitle: CGFloat = 20
    public static let featuredSummary: CGFloat = 13
    public static let featuredSummaryLines = 3
    public static let coverHeight: CGFloat = 118
    public static let cardPadding: CGFloat = 12
    public static let cardIcon: CGFloat = 40
    public static let rowIcon: CGFloat = 64
    public static let rowPadding: CGFloat = 12
    public static let iconGap: CGFloat = 12
    public static let nameSize: CGFloat = 15
    public static let summarySize: CGFloat = 12.5
    public static let summaryLines = 2
    public static let textGap: CGFloat = 3
    public static let capsuleText: CGFloat = 11
    public static let capsuleMinWidth: CGFloat = 52
    public static let capsuleHeight: CGFloat = 22
    public static let keyText: CGFloat = 10.5
    public static let keyHeight: CGFloat = 18
    public static let keyPadding: CGFloat = 7
    public static let keyRadius: CGFloat = 5
}

private typealias M = OnePlusLinearAppListMetrics

/// The GET or OPEN capsule: the uppercase verb on the track fill. A nil `action` draws it disabled at 0.38 opacity.
public struct OnePlusLinearAppAction: View {
    private let title: String
    private let help: String?
    private let action: (() -> Void)?
    public init(_ title: String, help: String? = nil, action: (() -> Void)?) {
        self.title = title; self.help = help; self.action = action
    }
    public var body: some View {
        Button { action?() } label: { Text(title.uppercased()) }
            .buttonStyle(OnePlusLinearAppCapsuleStyle())
            .disabled(action == nil)
            .help(help ?? "")
            .accessibilityLabel(title)
    }
}

private struct OnePlusLinearAppCapsuleStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .linearText(M.capsuleText, weight: .bold)
            .frame(minWidth: M.capsuleMinWidth).frame(height: M.capsuleHeight).padding(.horizontal, 2)
            .background(Capsule().fill(configuration.isPressed ? OnePlusLinearColor.fillButtonPressed : OnePlusLinearColor.fillTrack))
            .contentShape(Capsule())
            .opacity(enabled ? 1 : 0.38)
    }
}

private struct OnePlusLinearAppIcon: View {
    let icon: Image
    let size: CGFloat
    var body: some View {
        icon.resizable().scaledToFit().frame(width: size, height: size).accessibilityHidden(true)
    }
}

private struct OnePlusLinearAppSummary: View {
    let text: String
    var size = M.summarySize
    var lines = M.summaryLines
    var body: some View {
        Text(text).linearText(size, color: OnePlusLinearColor.secondary)
            .lineLimit(lines).fixedSize(horizontal: false, vertical: true)
    }
}

/// The floating group surface with the tile contact and drop shadows.
private struct OnePlusLinearAppTileSurface: View {
    var body: some View {
        RoundedRectangle(cornerRadius: M.tileRadius, style: .continuous).fill(OnePlusLinearColor.fillGroup)
            .shadow(color: OnePlusLinearColor.fillTileContact, radius: 0.75, y: 0.5)
            .shadow(color: OnePlusLinearColor.fillTileShadow, radius: 8, y: 3)
    }
}

/// The page layout: the featured banner, the "More apps" caption, the cover cards in one equal-width row, then the
/// open list of the other apps.
public struct OnePlusLinearAppShelf<Featured: View, Covers: View, Rows: View>: View {
    private let title: String
    private let featured: Featured
    private let covers: Covers
    private let rows: Rows
    public init(_ title: String = "More apps", @ViewBuilder featured: () -> Featured, @ViewBuilder covers: () -> Covers,
                @ViewBuilder rows: () -> Rows) {
        self.title = title; self.featured = featured(); self.covers = covers(); self.rows = rows()
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: M.stackGap) {
            featured
            Text(title).linearText(OnePlusLinearMetrics.body, weight: .semibold)
                .padding(.top, M.captionTop).accessibilityAddTraits(.isHeader)
            VStack(spacing: M.cardGap) {
                HStack(spacing: M.cardGap) { covers }.fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 0) { rows }.padding(.top, M.listTop)
            }
        }
    }
}

/// The featured banner: a 96 pt icon, the 20 pt name with the raised Paid key, a three-line summary, and the capsule
/// centered on the icon, on a floating group tile.
public struct OnePlusLinearFeaturedApp: View {
    private let name: String
    private let detail: String
    private let icon: Image
    private let price: String?
    private let actionView: OnePlusLinearAppAction
    public init(_ name: String, detail: String, icon: Image, price: String?, action: OnePlusLinearAppAction) {
        self.name = name; self.detail = detail; self.icon = icon; self.price = price; self.actionView = action
    }
    public var body: some View {
        HStack(alignment: .center, spacing: M.iconGap) {
            OnePlusLinearAppIcon(icon: icon, size: M.featuredIcon)
            VStack(alignment: .leading, spacing: M.textGap) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(name).linearText(M.featuredTitle, weight: .semibold).lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
                    if let price {
                        Text(price).linearText(M.keyText, weight: .semibold, color: OnePlusLinearColor.softKeyInk)
                            .padding(.horizontal, M.keyPadding).frame(height: M.keyHeight)
                            .background(OnePlusRaisedKey(shape: RoundedRectangle(cornerRadius: M.keyRadius, style: .continuous)))
                            .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4 }
                    }
                    Spacer(minLength: 6)
                }
                OnePlusLinearAppSummary(text: detail, size: M.featuredSummary, lines: M.featuredSummaryLines)
            }
            actionView
        }
        .padding(M.tilePadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OnePlusLinearAppTileSurface())
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// A half-width card with its cover edge to edge across the top, like an App Store Today card: the 118 pt cover,
/// then the 40 pt icon, the name, the capsule, and a two-line summary. Use two inside `OnePlusLinearAppShelf`.
public struct OnePlusLinearAppCoverCard: View {
    private let name: String
    private let summary: String
    private let icon: Image
    private let cover: Image
    private let coverAlignment: Alignment
    private let actionView: OnePlusLinearAppAction
    public init(_ name: String, summary: String, icon: Image, cover: Image, coverAlignment: Alignment = .top,
                action: OnePlusLinearAppAction) {
        self.name = name; self.summary = summary; self.icon = icon; self.cover = cover
        self.coverAlignment = coverAlignment; self.actionView = action
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear.frame(height: M.coverHeight).frame(maxWidth: .infinity)
                .overlay(alignment: coverAlignment) { cover.resizable().scaledToFill() }
                .clipped().accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 10) {
                    OnePlusLinearAppIcon(icon: icon, size: M.cardIcon)
                    Text(name).linearText(M.nameSize, weight: .semibold).lineLimit(1)
                    Spacer(minLength: 4)
                    actionView
                }
                OnePlusLinearAppSummary(text: summary)
            }
            .padding(M.cardPadding)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .background(OnePlusLinearColor.fillGroup)
        .clipShape(RoundedRectangle(cornerRadius: M.tileRadius, style: .continuous))
        .background(OnePlusLinearAppTileSurface())
    }
}

/// One open list row: the 64 pt icon, the 15 pt name over a two-line summary, then the capsule. A faded hairline
/// above every row but the first starts at the text column.
public struct OnePlusLinearAppRow: View {
    private let name: String
    private let summary: String
    private let icon: Image
    private let separator: Bool
    private let actionView: OnePlusLinearAppAction
    public init(_ name: String, summary: String, icon: Image, separator: Bool = true, action: OnePlusLinearAppAction) {
        self.name = name; self.summary = summary; self.icon = icon; self.separator = separator; self.actionView = action
    }
    public var body: some View {
        HStack(alignment: .center, spacing: M.iconGap) {
            OnePlusLinearAppIcon(icon: icon, size: M.rowIcon)
            VStack(alignment: .leading, spacing: M.textGap) {
                Text(name).linearText(M.nameSize, weight: .semibold).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                OnePlusLinearAppSummary(text: summary)
            }
            Spacer(minLength: 6)
            actionView
        }
        .padding(.vertical, M.rowPadding)
        .overlay(alignment: .top) {
            if separator { OnePlusLinearFadedHairline(OnePlusLinearColor.lineSoft).padding(.leading, M.rowIcon + M.iconGap) }
        }
    }
}
