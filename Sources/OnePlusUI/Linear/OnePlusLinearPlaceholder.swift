import SwiftUI

/// A loading stand-in for a tree card (a host row over its child rows, such as a Portman host card): the same
/// 40 pt header and 32 pt child rows, with soft bars where the icon, name, caption, and badges go. A light sheen
/// sweeps over the bars; Reduce Motion shows the bars only. Use it only while real work runs.
public struct OnePlusLinearTreeCardPlaceholder: View {
    private let children: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    private enum Bar {
        static let text: CGFloat = 8
        static let caption: CGFloat = 6
        static let lineGap: CGFloat = 6
        static let radius: CGFloat = 3
        static let name: CGFloat = 92
        static let detail: CGFloat = 148
        static let reading: CGFloat = 40
        static let badge: CGFloat = 40
        static let childName: CGFloat = 112
        static let sheenWidth: CGFloat = 0.45
    }

    public init(children: Int = 2) { self.children = children }

    public var body: some View {
        OnePlusLinearList(style: .panel) {
            bars(OnePlusLinearColor.barTrack)
                .overlay {
                    if !reduceMotion {
                        GeometryReader { proxy in
                            let band = proxy.size.width * Bar.sheenWidth
                            LinearGradient(colors: [.clear, OnePlusLinearColor.placeholderSheen, .clear],
                                           startPoint: .leading, endPoint: .trailing)
                                .frame(width: band)
                                .offset(x: -band + phase * (proxy.size.width + band))
                        }
                        .mask(bars(.white))
                        .onAppear {
                            withAnimation(.linear(duration: OnePlusMotion.sheenSweep).repeatForever(autoreverses: false)) {
                                phase = 1
                            }
                        }
                    }
                }
        }
        .allowsHitTesting(false)
        .accessibilityElement()
        .accessibilityLabel("Loading")
    }

    private func bars(_ fill: Color) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: OnePlusLinearMetrics.rowGap) {
                RoundedRectangle(cornerRadius: OnePlusLinearMetrics.hostIconRadius).fill(fill)
                    .frame(width: OnePlusLinearMetrics.hostIcon, height: OnePlusLinearMetrics.hostIcon)
                VStack(alignment: .leading, spacing: Bar.lineGap) {
                    bar(fill, width: Bar.name, height: Bar.text)
                    bar(fill, width: Bar.detail, height: Bar.caption)
                }
                Spacer(minLength: 0)
                bar(fill, width: Bar.reading, height: Bar.text)
            }
            .padding(.horizontal, OnePlusLinearMetrics.panelRowInset)
            .frame(height: OnePlusLinearMetrics.panelTwoLineRow)
            ForEach(0..<children, id: \.self) { _ in
                HStack(spacing: OnePlusLinearMetrics.rowGap) {
                    RoundedRectangle(cornerRadius: OnePlusLinearMetrics.badgeRadius).fill(fill)
                        .frame(width: Bar.badge, height: OnePlusLinearMetrics.badge)
                    bar(fill, width: Bar.childName, height: Bar.text)
                    Spacer(minLength: 0)
                }
                .padding(.leading, OnePlusLinearMetrics.treeChildInset)
                .padding(.trailing, OnePlusLinearMetrics.panelRowInset)
                .frame(height: OnePlusLinearMetrics.treeChildRow)
            }
        }
    }

    private func bar(_ fill: Color, width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: Bar.radius).fill(fill).frame(width: width, height: height)
    }
}

/// Which side a pushed page comes in from: `.trailing` going deeper (list to detail), `.leading` going back.
public enum OnePlusPushEdge: Sendable { case leading, trailing }

private struct OnePlusPushFrame { var x: CGFloat = 0; var opacity: Double = 1 }

private struct OnePlusPush<Trigger: Equatable>: ViewModifier {
    let trigger: Trigger
    let edge: OnePlusPushEdge
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: OnePlusPushFrame(), trigger: trigger) { view, frame in
            view.modifier(OnePlusPixelOffset(x: frame.x)).opacity(frame.opacity)
        } keyframes: { _ in
            let start = reduceMotion ? 0 : (edge == .trailing ? OnePlusMotion.pushOffset : -OnePlusMotion.pushOffset)
            let duration = reduceMotion ? 0 : OnePlusMotion.push
            KeyframeTrack(\.x) {
                MoveKeyframe(start)
                LinearKeyframe(0, duration: duration, timingCurve: OnePlusMotion.glideCurve)
            }
            KeyframeTrack(\.opacity) {
                MoveKeyframe(reduceMotion ? 1 : 0)
                LinearKeyframe(1, duration: duration, timingCurve: OnePlusMotion.easeOut)
            }
        }
    }
}

public extension View {
    /// A list to detail push. When `trigger` changes, the new page shows in its final layout at once (so the
    /// panel takes its new height in one step) and slides `OnePlusMotion.pushOffset` in from `edge` while it
    /// fades in. Only paint moves; layout never does. Reduce Motion makes it instant.
    func onePlusPush(trigger: some Equatable, from edge: OnePlusPushEdge) -> some View {
        modifier(OnePlusPush(trigger: trigger, edge: edge))
    }
}
