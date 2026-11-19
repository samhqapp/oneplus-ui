import AppKit
import SwiftUI

/// The table look. A table inside an editorial body (`onePlusLinearEditorial`) takes `.linear`, the main-window
/// language: a 12 pt semibold `secondary` header in sentence case on the group fill, one `fillGroup` fill for every
/// row, the `fillRowHover` hover, `lineSoft` separators, and 13 pt `ink` or 12 pt `secondary` cell text.
struct OnePlusTablePalette: Equatable {
    let linear: Bool
    static let standard = Self(linear: false)
    static let linear = Self(linear: true)
    static func `for`(editorial: Bool) -> Self { editorial ? .linear : .standard }

    var panel: Color { linear ? OnePlusLinearColor.fillGroup : OnePlusColor.panel }
    var headerFill: Color { linear ? OnePlusLinearColor.fillGroup : OnePlusColor.sidebar }
    var hover: Color { linear ? OnePlusLinearColor.fillRowHover : OnePlusColor.raised }
    var selection: Color { linear ? OnePlusLinearColor.fillButtonHover : OnePlusColor.selection }
    var selectionInactive: Color { linear ? OnePlusLinearColor.fillRowHover : OnePlusColor.selectionInactive }
    var line: Color { linear ? OnePlusLinearColor.lineSoft : OnePlusColor.lineSoft }
    var ink: Color { linear ? OnePlusLinearColor.ink : OnePlusColor.ink }
    var secondary: Color { linear ? OnePlusLinearColor.secondary : OnePlusColor.secondary }
    func row(_ index: Int) -> Color { linear ? OnePlusLinearColor.fillGroup : OnePlusTable.rowBackground(index) }

    func headerLabel(_ string: String) -> NSAttributedString {
        linear
            ? NSAttributedString(string: string, attributes: [
                .font: NSFont.systemFont(ofSize: OnePlusLinearMetrics.control, weight: .semibold),
                .foregroundColor: NSColor(OnePlusLinearColor.secondary)
            ])
            : NSAttributedString(string: string.uppercased(), attributes: [
                .font: NSFont.systemFont(ofSize: 9, weight: .medium),
                .foregroundColor: NSColor(OnePlusColor.muted), .kern: 0.4
            ])
    }

    /// Linear cell type: `row` is 13 pt `ink`; `mono` 12 pt monospaced `secondary`; every other role 12 pt `secondary`.
    func cellFont(_ role: OnePlusTextRole, density: OnePlusDensity) -> (size: CGFloat, weight: Font.Weight, mono: Bool) {
        guard linear else { return (role.size(for: density), role.weight, role == .mono) }
        switch role {
        case .row: return (OnePlusLinearMetrics.body, .regular, false)
        case .mono: return (OnePlusLinearMetrics.control, .regular, true)
        case .cardTitle, .sectionTitle: return (OnePlusLinearMetrics.body, .semibold, false)
        default: return (OnePlusLinearMetrics.control, .regular, false)
        }
    }

    func cellColor(_ role: OnePlusTextRole) -> Color {
        guard linear else { return role.color }
        return role == .row || role == .cardTitle || role == .sectionTitle ? OnePlusLinearColor.ink : OnePlusLinearColor.secondary
    }
}

struct OnePlusTableCellModifier: ViewModifier {
    let column: OnePlusGridColumn
    let position: OnePlusTable.CellPosition
    @Environment(\.onePlusLinearEditorial) private var editorial
    @Environment(\.onePlusDensity) private var density
    func body(content: Content) -> some View {
        let palette = OnePlusTablePalette.for(editorial: editorial)
        let role = column.textRole ?? .row
        let font = palette.cellFont(role, density: density)
        // ponytail: AppKit's bordered Table reserves 6pt at each outside edge;
        // the native geometry regression test gates updates to that platform inset.
        return Group {
            if palette.linear {
                content.font(.system(size: font.size, weight: font.weight, design: font.mono ? .monospaced : .default))
                    .foregroundStyle(column.textColor ?? palette.cellColor(role)).monospacedDigit()
            } else {
                content.onePlusText(role, color: column.textColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: column.swiftUIAlignment)
        .padding(.leading, max(0, column.leadingInset - (position == .first ? 6 : 0)))
        .padding(.trailing, max(0, column.trailingInset - (position == .last ? 6 : 0)))
    }
}
