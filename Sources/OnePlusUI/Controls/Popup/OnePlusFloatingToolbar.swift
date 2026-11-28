import SwiftUI

/// A small floating capsule of tool buttons, such as the text format pill over a selection (owner, 2026-11-28):
/// 30 pt tall, 15 pt corners, 26 x 24 buttons. It fades in with a 4 pt rise and a 0.96 scale over 140 ms.
public enum OnePlusFloatingToolbarMetrics {
    public static let height: CGFloat = 30
    public static let buttonSize = CGSize(width: 26, height: 24)
    public static let show: TimeInterval = 0.14
    public static let hide: TimeInterval = 0.09
    /// Room around the capsule for its shadow, when it sits in its own window.
    public static let shadowRoom: CGFloat = 20
}

public struct OnePlusFloatingToolbar<Content: View>: View {
    let content: Content
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    init(shown: Bool, @ViewBuilder content: () -> Content) { self.content = content(); _shown = State(initialValue: shown) }

    public var body: some View {
        HStack(spacing: 0) { content }
            .padding(.horizontal, 3)
            .frame(height: OnePlusFloatingToolbarMetrics.height)
            .background(OnePlusPopupColor.background, in: Capsule())
            .overlay { Capsule().strokeBorder(OnePlusPopupColor.ring, lineWidth: 0.5) }
            .shadow(color: .black.opacity(0.22), radius: 9, y: 6)
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 4)
            .scaleEffect(shown || reduceMotion ? 1 : 0.96)
            .onAppear {
                withAnimation(.timingCurve(0.25, 1, 0.5, 1, duration: OnePlusFloatingToolbarMetrics.show)) { shown = true }
            }
    }
}

public struct OnePlusFloatingToolbarButton<Label: View>: View {
    let title: String
    let isActive: Bool
    let action: () -> Void
    let label: Label
    @State private var hovering = false

    public init(_ title: String, isActive: Bool = false, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.title = title
        self.isActive = isActive
        self.action = action
        self.label = label()
    }

    public var body: some View {
        Button(action: action) {
            label
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isActive ? OnePlusLinearColor.pushProminent : OnePlusPopupColor.ink)
                .frame(width: OnePlusFloatingToolbarMetrics.buttonSize.width, height: OnePlusFloatingToolbarMetrics.buttonSize.height)
                .background {
                    if hovering { RoundedRectangle(cornerRadius: 7, style: .continuous).fill(OnePlusPopupColor.picked) }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(title)
        .accessibilityLabel(title)
    }
}

/// The 1 x 16 line between button groups.
public struct OnePlusFloatingToolbarSeparator: View {
    public init() {}
    public var body: some View {
        Rectangle().fill(OnePlusPopupColor.hair).frame(width: 1, height: 16).padding(.horizontal, 3).accessibilityHidden(true)
    }
}
