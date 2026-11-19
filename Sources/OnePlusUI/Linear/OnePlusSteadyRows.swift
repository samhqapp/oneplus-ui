import SwiftUI

/// How many rows a panel list keeps room for, so the panel height holds steady while rows come and go
/// (owner, 2026-11-19). The list reserves at least `minimum` rows and grows at once when rows are added. It shrinks
/// only when the count drops at least 2 below the reserved rows, then to the new count, never below `minimum`.
public struct OnePlusSteadyRows: Equatable, Sendable {
    public static let minimum = 3
    public private(set) var reserved: Int

    public init(count: Int) { reserved = max(count, Self.minimum) }

    public mutating func update(count: Int) {
        if count > reserved || reserved - count >= 2 { reserved = max(count, Self.minimum) }
    }
}

public extension View {
    /// Keeps room for `OnePlusSteadyRows` rows of `rowHeight` points. The space a removed row leaves stays empty at
    /// the bottom until the rule fires. The count starts over each time the view appears.
    func onePlusSteadyRows(count: Int, rowHeight: CGFloat) -> some View {
        modifier(OnePlusSteadyRowsModifier(count: count, rowHeight: rowHeight))
    }
}

private struct OnePlusSteadyRowsModifier: ViewModifier {
    let count: Int
    let rowHeight: CGFloat
    @State private var rows: OnePlusSteadyRows?

    func body(content: Content) -> some View {
        content
            .frame(minHeight: rowHeight * CGFloat((rows ?? OnePlusSteadyRows(count: count)).reserved), alignment: .top)
            .onChange(of: count, initial: true) {
                var next = rows ?? OnePlusSteadyRows(count: count)
                next.update(count: count)
                if next != rows { rows = next }
            }
            .onDisappear { rows = nil }
    }
}
