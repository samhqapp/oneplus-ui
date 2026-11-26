import AppKit
import SwiftUI

public struct OnePlusEmptyState<Action: View>: View {
    let title: String
    let icon: String
    let caption: String?
    let action: Action
    public init(_ title: String, systemImage: String, caption: String? = nil, @ViewBuilder action: () -> Action) {
        self.title = title; icon = systemImage; self.caption = caption; self.action = action()
    }
    public var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 26)).foregroundStyle(OnePlusColor.muted).accessibilityHidden(true)
            Text(title).font(.system(size: 13, weight: .medium)).foregroundStyle(OnePlusColor.ink)
            if let caption { Text(caption).onePlusText(.caption).multilineTextAlignment(.center) }
            action.buttonStyle(OnePlusButtonStyle())
        }.padding(.vertical, 40).padding(.horizontal, 20).frame(maxWidth: .infinity)
    }
}

public extension OnePlusEmptyState where Action == EmptyView {
    init(_ title: String, systemImage: String, caption: String? = nil) {
        self.init(title, systemImage: systemImage, caption: caption, action: { EmptyView() })
    }
}

public struct OnePlusToast: View {
    let message: String
    let icon: String
    public init(_ message: String, systemImage: String = "checkmark.circle") { self.message = message; icon = systemImage }
    public var body: some View {
        Label(message, systemImage: icon).font(.system(size: 11)).foregroundStyle(OnePlusColor.ink)
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(OnePlusColor.raised.opacity(0.96), in: RoundedRectangle(cornerRadius: 6))
            .overlay { RoundedRectangle(cornerRadius: 6).strokeBorder(OnePlusColor.line, lineWidth: 1) }
            .padding(.bottom, 20).allowsHitTesting(false)
            .onChange(of: message, initial: true) { _, message in
                NSAccessibility.post(element: NSApp as Any, notification: .announcementRequested,
                                     userInfo: [.announcement: message, .priority: NSAccessibilityPriorityLevel.medium.rawValue])
            }
    }
}

public struct OnePlusBanner<Action: View>: View {
    public enum Tone: Sendable { case information, warning, error }
    let message: String
    let tone: Tone
    let action: Action
    public init(_ message: String, tone: Tone = .information, @ViewBuilder action: () -> Action) {
        self.message = message; self.tone = tone; self.action = action()
    }
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: tone == .information ? "info.circle" : tone == .warning ? "exclamationmark.triangle.fill" : "exclamationmark.circle")
                .symbolRenderingMode(tone == .warning ? .multicolor : .monochrome)
                .foregroundStyle(tone == .information ? OnePlusColor.secondary : tone == .warning ? Color.primary : OnePlusColor.danger)
                .accessibilityHidden(true)
            Text(message).onePlusText(.row).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            action.buttonStyle(OnePlusButtonStyle(.ghost, size: .small))
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(tone == .warning ? OnePlusLinearColor.warningFill : OnePlusColor.panel, in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6).strokeBorder(tone == .error ? OnePlusColor.dangerLine
                                                               : tone == .warning ? OnePlusLinearColor.warningLine : OnePlusColor.line, lineWidth: 1)
            }
    }
}

public extension OnePlusBanner where Action == EmptyView {
    init(_ message: String, tone: Tone = .information) { self.init(message, tone: tone, action: { EmptyView() }) }
}

/// `.panel` fits a sheet inside the 356 pt menu panel.
public enum OnePlusSheetWidth: CGFloat, Sendable { case panel = 340, small = 420, medium = 560, large = 700 }

/// The one sheet frame. Native macOS sheet look: no bar and no lines, a small centered title, and a red close light
/// at the window close-light spot, both on the 22 pt centerline of a 44 pt row. Footer keys sit right with no line.
/// The sheet stays within 90% of its window's height; the title and keys stay fixed and the middle scrolls.
/// Present inside SwiftUI's native `.sheet` modifier.
public struct OnePlusSheet<Body: View, Footer: View>: View {
    @Environment(\.displayScale) private var displayScale
    @State private var parentHeight: CGFloat?
    let title: String
    let width: CGFloat
    let close: (() -> Void)?
    let content: Body
    let footer: Footer
    public init(_ title: String, width: OnePlusSheetWidth = .medium, close: (() -> Void)? = nil,
                @ViewBuilder content: () -> Body, @ViewBuilder footer: () -> Footer) {
        self.init(title, points: width.rawValue, close: close, content: content, footer: footer)
    }
    init(_ title: String, points width: CGFloat, close: (() -> Void)?,
         @ViewBuilder content: () -> Body, @ViewBuilder footer: () -> Footer) {
        self.title = title; self.width = width; self.close = close
        self.content = content(); self.footer = footer()
    }
    /// A panel-width sheet sits inside a 356 pt menu panel, so it takes the tight inset.
    private var inset: CGFloat {
        width == OnePlusSheetWidth.panel.rawValue ? OnePlusMetrics.sheetPanelInset : OnePlusMetrics.sheetInset
    }
    private var hasFooter: Bool { Footer.self != EmptyView.self }
    private var middle: some View {
        content.padding(.horizontal, inset).padding(.bottom, hasFooter ? OnePlusMetrics.contentGap : inset)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    public var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .leading) {
                OnePlusHeaderTitleLayout(text: title, pointSize: OnePlusTextRole.sectionTitle.size(for: .regular),
                                         height: OnePlusMetrics.sheetTitleRow, scale: displayScale, centersCaps: true) {
                    Text(title).onePlusText(.sectionTitle).lineLimit(1).accessibilityAddTraits(.isHeader)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, OnePlusMetrics.trafficLightLeadingInset * 2 + OnePlusMetrics.sheetCloseLight)
                if let close { OnePlusSheetCloseLight(action: close).padding(.leading, OnePlusMetrics.trafficLightLeadingInset) }
            }.frame(height: OnePlusMetrics.sheetTitleRow)
            ViewThatFits(in: .vertical) {
                middle
                ScrollView { middle }.onePlusScrollIndicators()
            }
            if hasFooter {
                HStack(spacing: OnePlusMetrics.actionSpacing) { Spacer(); footer }
                    .padding(.horizontal, inset).padding(.bottom, inset)
            }
        }
        .frame(width: width)
        .frame(maxHeight: parentHeight.map { $0 * OnePlusMetrics.sheetMaxHeightFraction })
        .background(OnePlusColor.window).background(OnePlusSheetParentHeight(height: $parentHeight))
        .onePlusDensity(.regular)
        .onePlusNeutralControls()
        .onePlusFocusPolicy()
        .onePlusAppAppearance()
    }
}

/// The red close light of a sheet: the native window close button's size, color, and spot; the × shows on hover.
struct OnePlusSheetCloseLight: View {
    let action: () -> Void
    @State private var hovered = false
    var body: some View {
        Button(action: action) {
            Circle().fill(OnePlusColor.closeLight)
                .overlay(Circle().strokeBorder(OnePlusColor.closeLightEdge, lineWidth: OnePlusMetrics.sheetCloseLightEdge))
                .overlay {
                    if hovered {
                        Image(systemName: "xmark").font(.system(size: OnePlusMetrics.sheetCloseGlyph, weight: .bold))
                            .foregroundStyle(OnePlusColor.closeLightGlyph)
                    }
                }
                .frame(width: OnePlusMetrics.sheetCloseLight, height: OnePlusMetrics.sheetCloseLight)
                .contentShape(Circle())
        }
        .buttonStyle(.plain).focusable(false).onHover { hovered = $0 }
        .help("Close").accessibilityLabel("Close").keyboardShortcut(.cancelAction)
    }
}

/// Reads the height of the window a sheet is attached to.
private struct OnePlusSheetParentHeight: NSViewRepresentable {
    @Binding var height: CGFloat?
    func makeNSView(context: Context) -> Reader { Reader { height = $0 } }
    func updateNSView(_ nsView: Reader, context: Context) {}
    final class Reader: NSView {
        let report: @MainActor (CGFloat?) -> Void
        init(_ report: @escaping @MainActor (CGFloat?) -> Void) { self.report = report; super.init(frame: .zero) }
        required init?(coder: NSCoder) { nil }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            let height = window?.sheetParent?.frame.height
            Task { @MainActor in self.report(height) }
        }
    }
}

public extension OnePlusSheet where Footer == EmptyView {
    init(_ title: String, width: OnePlusSheetWidth = .medium, close: (() -> Void)? = nil, @ViewBuilder content: () -> Body) {
        self.init(title, width: width, close: close, content: content, footer: { EmptyView() })
    }
}
