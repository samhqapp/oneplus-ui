import SwiftUI

/// A pull-down button that opens `OnePlusPopupMenu`. `.raised` draws the page's raised button
/// (`OnePlusLinearButtonStyle(.raised)`) with a down chevron, for a settings row. `.hostTitle` (title and
/// chevron) and `.hostIcon` (the image only) take the button style the host sets, so the button matches its
/// neighbors in a toolbar.
public struct OnePlusMenuButton: View {
    public enum Variant: Sendable { case neutral, ghost, borderedIcon, raised, hostTitle, hostIcon }

    private let title: String
    private let systemImage: String
    private let variant: Variant
    private let items: () -> [OnePlusPopupMenuEntry]
    @Environment(\.onePlusDensity) private var density
    @FocusState private var focused: Bool
    @State private var expanded = false
    @State private var anchor = OnePlusPopupAnchorReference()

    public init(_ title: String, systemImage: String = "ellipsis", variant: Variant = .ghost,
                items: [OnePlusPopupMenuEntry]) {
        self.title = title
        self.systemImage = systemImage
        self.variant = variant
        self.items = { items }
    }

    public init(_ title: String, systemImage: String = "ellipsis", variant: Variant = .ghost,
                items: @escaping () -> [OnePlusPopupMenuEntry]) {
        self.title = title
        self.systemImage = systemImage
        self.variant = variant
        self.items = items
    }

    public var body: some View {
        styled
        .environment(\.onePlusControlState, expanded ? .hover : .rest)
        .fixedSize()
        .focused($focused)
        .background { OnePlusPopupAnchor(reference: anchor) }
        .onMoveCommand { direction in
            if direction == .down, !expanded { toggle() }
        }
        .help(title)
        .accessibilityLabel(title)
        .accessibilityValue(expanded ? "Expanded" : "Collapsed")
        .accessibilityHint(expanded ? "Menu open" : "Opens menu")
    }

    @ViewBuilder private var styled: some View {
        switch variant {
        case .raised:
            Button(action: toggle) {
                HStack(spacing: 6) {
                    Text(title)
                    Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold)).accessibilityHidden(true)
                }
            }
            .buttonStyle(OnePlusLinearButtonStyle(.raised))
        case .hostTitle:
            Button(action: toggle) {
                HStack(spacing: 5) {
                    Text(title)
                    Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold)).accessibilityHidden(true)
                }
            }
        case .hostIcon:
            Button(action: toggle) { Image(systemName: systemImage).accessibilityHidden(true) }
        case .borderedIcon:
            Button(action: toggle) { Image(systemName: systemImage).accessibilityHidden(true) }
                .buttonStyle(OnePlusButtonStyle(.borderedIcon, height: density.controlHeight))
        case .neutral, .ghost:
            Button(action: toggle) {
                OnePlusControlContentLayout(pointSize: OnePlusTextRole.control.size(for: density), iconIndex: 1) {
                    Text(title)
                    Image(systemName: "chevron.down").accessibilityHidden(true)
                }
            }
            .buttonStyle(OnePlusButtonStyle(variant == .neutral ? .neutral : .ghost))
        }
    }

    private func toggle() {
        let items = items()
        let entries = items.isEmpty
            ? [.item(OnePlusPopupMenuItem("No actions", isEnabled: false) {})]
            : items
        OnePlusPopupPresenter.shared.toggle(anchor: anchor.view, entries: entries, density: density,
                                            initialID: entries.compactMap(\.item).first(where: \.isEnabled)?.id) { reason in
            expanded = false
            if reason == .escape { focused = true }
        }
        expanded = OnePlusPopupPresenter.shared.isOpen(for: anchor.view)
    }
}
