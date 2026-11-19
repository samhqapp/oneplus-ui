import SwiftUI

/// The small Linear spacing steps between parts of one row or one block.
public enum OnePlusLinearSpace {
    public static let hair: CGFloat = 2
    public static let tight: CGFloat = 4
    public static let small: CGFloat = 6
    public static let row: CGFloat = 8
    public static let group: CGFloat = 12
    public static let section: CGFloat = 16
    public static let block: CGFloat = 20
    public static let page: CGFloat = 24
}

/// Fixed widths for a select or field column in a group row.
public enum OnePlusLinearControlWidth {
    public static let regular: CGFloat = 160
    public static let wide: CGFloat = 180
}

private struct OnePlusLinearGroupRowHover: ViewModifier {
    let selected: Bool
    @State private var hover = false
    @Environment(\.isEnabled) private var enabled
    func body(content: Content) -> some View {
        content.linearRowHover($hover, sample: .rest, enabled: enabled, panelStyle: .fillSteps, selected: selected)
    }
}

public extension View {
    /// The overflowing row hover of a main-window group: a radius 6 `fillRowHover` step, 4 pt inside the group
    /// sides and 1 pt inside the row, with its own hover state.
    func linearGroupRowHover(selected: Bool = false) -> some View { modifier(OnePlusLinearGroupRowHover(selected: selected)) }

    /// The main-window language for a page or sheet: editorial groups, sections, rows, and tables, and raised keys
    /// unless a surface already chose a control look.
    func onePlusLinearEditorialPage() -> some View {
        environment(\.onePlusLinearEditorial, true)
            .transformEnvironment(\.onePlusLinearControlLook) { if $0 == nil { $0 = .raisedKeys } }
    }
}

/// The fixed editorial body for a page that scrolls its own list or table: the editorial insets and block gap,
/// with no outer scroll. The last block takes the free height.
public struct OnePlusLinearEditorialFixedBody<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        VStack(alignment: .leading, spacing: OnePlusLinearEditorialMetrics.blockGap) { content }
            .padding(.top, OnePlusLinearEditorialMetrics.bodyTop)
            .padding(.horizontal, OnePlusLinearEditorialMetrics.gutter)
            .padding(.bottom, OnePlusLinearEditorialMetrics.bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .onePlusLinearEditorialPage()
    }
}

/// A sheet in the main-window language: a 48 pt title row with the 13 pt semibold title and a close key, the body
/// on the window color with the editorial insets, and right-aligned footer keys. No separators.
/// Present inside SwiftUI's native `.sheet` modifier.
public struct OnePlusLinearSheet<Body: View, Footer: View>: View {
    private let title: String
    private let width: CGFloat
    private let close: (() -> Void)?
    private let content: Body
    private let footer: Footer
    public init(_ title: String, width: OnePlusSheetWidth = .medium, close: (() -> Void)? = nil,
                @ViewBuilder content: () -> Body, @ViewBuilder footer: () -> Footer) {
        self.title = title; self.width = width.rawValue; self.close = close
        self.content = content(); self.footer = footer()
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: OnePlusLinearMetrics.appletActionGap) {
                Text(title).linearText(weight: .semibold).lineLimit(1).accessibilityAddTraits(.isHeader)
                Spacer(minLength: OnePlusLinearSpace.group)
                if let close {
                    OnePlusLinearIconButton(systemImage: "xmark", help: "Close", size: OnePlusLinearMetrics.toolbarButton,
                                            action: close)
                        .keyboardShortcut(.cancelAction)
                }
            }
            .padding(.horizontal, OnePlusLinearMetrics.gutter)
            .frame(height: OnePlusLinearMetrics.appletTitlebar)
            content.padding(.horizontal, OnePlusLinearMetrics.gutter)
                .padding(.bottom, OnePlusLinearEditorialMetrics.bottom)
                .frame(maxWidth: .infinity, alignment: .leading)
            if Footer.self != EmptyView.self {
                HStack(spacing: OnePlusLinearMetrics.appletActionGap) { Spacer(); footer }
                    .padding(.horizontal, OnePlusLinearMetrics.gutter)
                    .padding(.bottom, OnePlusLinearEditorialMetrics.bottom)
            }
        }
        .frame(width: width).background(OnePlusLinearColor.window)
        .onePlusLinearEditorialPage()
        .onePlusFocusPolicy()
        .onePlusAppAppearance()
    }
}

public extension OnePlusLinearSheet where Footer == EmptyView {
    init(_ title: String, width: OnePlusSheetWidth = .medium, close: (() -> Void)? = nil, @ViewBuilder content: () -> Body) {
        self.init(title, width: width, close: close, content: content) { EmptyView() }
    }
}
