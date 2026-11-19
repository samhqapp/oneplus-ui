import SwiftUI

/// The "Apps by Sam" parts (owner pick "Featured Pro, then a list", 2026-11-19): one featured block on the
/// track fill, then editorial rows with an Open or Get action and an optional Paid or Free word.
public enum OnePlusLinearAppListMetrics {
    public static let featuredIcon: CGFloat = 72
    public static let featuredGap: CGFloat = 16
    public static let featuredPadding: CGFloat = 18
    public static let featuredTitle: CGFloat = 17
    public static let featuredTextGap: CGFloat = 4
    public static let actionGap: CGFloat = 6
    public static let actionMinWidth: CGFloat = 34
    public static let rowTextGap: CGFloat = 1
}

/// A soft Open or Get button; a nil `action` draws it disabled at the shared 0.38 opacity.
public struct OnePlusLinearAppAction: View {
    private let title: String
    private let help: String?
    private let action: (() -> Void)?
    public init(_ title: String, help: String? = nil, action: (() -> Void)?) {
        self.title = title; self.help = help; self.action = action
    }
    public var body: some View {
        Button { action?() } label: { Text(title).frame(minWidth: OnePlusLinearAppListMetrics.actionMinWidth) }
            .buttonStyle(OnePlusLinearButtonStyle(.soft))
            .disabled(action == nil)
            .help(help ?? "")
    }
}

private struct OnePlusLinearAppPrice: View {
    let price: String?
    var body: some View {
        if let price { Text(price).linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.muted) }
    }
}

/// The featured block: a 72 pt icon, a muted caption, the 17 pt name and its description, and the action
/// over the price word on the trailing edge, on the `track` fill with the launch tile radius.
public struct OnePlusLinearFeaturedApp: View {
    private let name: String
    private let caption: String
    private let detail: String
    private let icon: Image
    private let price: String?
    private let actionView: OnePlusLinearAppAction
    public init(_ name: String, caption: String = "Featured", detail: String, icon: Image, price: String?,
                action: OnePlusLinearAppAction) {
        self.name = name; self.caption = caption; self.detail = detail; self.icon = icon; self.price = price
        self.actionView = action
    }
    public var body: some View {
        HStack(spacing: OnePlusLinearAppListMetrics.featuredGap) {
            icon.resizable().scaledToFit()
                .frame(width: OnePlusLinearAppListMetrics.featuredIcon, height: OnePlusLinearAppListMetrics.featuredIcon)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: OnePlusLinearAppListMetrics.featuredTextGap) {
                Text(caption).linearText(OnePlusLinearMetrics.caption, weight: .medium, color: OnePlusLinearColor.muted)
                Text(name).linearText(OnePlusLinearAppListMetrics.featuredTitle, weight: .semibold)
                    .accessibilityAddTraits(.isHeader)
                Text(detail).linearText(OnePlusLinearMetrics.control, color: OnePlusLinearColor.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: OnePlusLinearAppListMetrics.actionGap) {
                actionView
                OnePlusLinearAppPrice(price: price)
            }
        }
        .padding(OnePlusLinearAppListMetrics.featuredPadding)
        .background(RoundedRectangle(cornerRadius: OnePlusLinearEditorialMetrics.launchTileRadius).fill(OnePlusLinearColor.track))
    }
}

/// The editorial 48 pt app row: the 24 pt icon, the medium name over a one-line summary, then the optional
/// price word and the action where a tool row has its star and chevron.
public struct OnePlusLinearAppRow: View {
    private let name: String
    private let summary: String
    private let icon: Image
    private let price: String?
    private let actionView: OnePlusLinearAppAction
    public init(_ name: String, summary: String, icon: Image, price: String?, action: OnePlusLinearAppAction) {
        self.name = name; self.summary = summary; self.icon = icon; self.price = price; self.actionView = action
    }
    public var body: some View {
        HStack(spacing: OnePlusLinearMetrics.toolRowGap) {
            icon.resizable().scaledToFit()
                .frame(width: OnePlusLinearEditorialMetrics.toolIcon, height: OnePlusLinearEditorialMetrics.toolIcon)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: OnePlusLinearAppListMetrics.rowTextGap) {
                Text(name).linearText(OnePlusLinearMetrics.body, weight: .medium)
                Text(summary).linearText(OnePlusLinearMetrics.caption, color: OnePlusLinearColor.secondary)
            }
            .lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
            OnePlusLinearAppPrice(price: price)
            actionView
        }
        .padding(.horizontal, OnePlusLinearEditorialMetrics.toolRowInset)
        .frame(height: OnePlusLinearEditorialMetrics.toolRow)
    }
}
