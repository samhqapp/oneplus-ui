import SwiftUI

/// A date and time field on the stepper well (`OnePlusLinearStepper`): the date, hour, and minute are segments.
/// Click a segment, then step it with the chevron key or the Up and Down arrows; Left and Right move between
/// segments. Until a segment is picked, the key steps the minute. A step that would pass `minimum` stops on it.
/// shortcut: segments step only, typing digits is not supported; add typing when a field needs far-off dates.
public struct OnePlusLinearDateField: View {
    public enum Part: Hashable, Sendable { case day, hour, minute }

    private let title: String
    @Binding private var selection: Date
    private let minimum: Date?
    private let parts: [Part]
    @State private var picked: Part?
    @FocusState private var focused: Bool
    @Environment(\.onePlusLinearControlLook) private var look

    public init(_ title: String, selection: Binding<Date>, minimum: Date? = nil, showsDate: Bool = true) {
        self.title = title; _selection = selection; self.minimum = minimum
        parts = showsDate ? [.day, .hour, .minute] : [.hour, .minute]
    }

    private var active: Part { picked ?? .minute }

    public var body: some View {
        OnePlusLinearStepper(title, canDecrement: minimum.map { selection > $0 } ?? true,
                             decrement: { step(-1) }, increment: { step(1) }) {
            HStack(spacing: 0) {
                ForEach(parts, id: \.self) { part in
                    if part == .minute { Text(":").linearText(color: OnePlusLinearColor.secondary) }
                    segment(part).padding(.trailing, part == .day ? Self.dayGap : 0)
                }
                if Self.uses12Hour {
                    Text(Self.period.string(from: selection)).linearText()
                        .padding(.leading, Self.dayGap / 2)
                }
            }
            .focusable().focusEffectDisabled().focused($focused)
            .onKeyPress(keys: [.upArrow, .downArrow, .leftArrow, .rightArrow]) { press in
                guard press.modifiers.isEmpty else { return .ignored }
                switch press.key {
                case .upArrow: step(1)
                case .downArrow: step(-1)
                default:
                    let index = parts.firstIndex(of: active) ?? parts.count - 1
                    picked = parts[min(max(index + (press.key == .leftArrow ? -1 : 1), 0), parts.count - 1)]
                }
                return .handled
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }

    private func segment(_ part: Part) -> some View {
        let on = picked == part
        return Button { picked = part; focused = true } label: {
            Text(Self.formatter(part).string(from: selection))
                .linearText(weight: on ? .medium : .regular).monospacedDigit()
                .frame(maxHeight: .infinity)
                .background {
                    if on {
                        RoundedRectangle(cornerRadius: OnePlusLinearWell(look).innerRadius).fill(OnePlusLinearColor.fillThumb)
                            .padding(.horizontal, -Self.segmentPadding)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain).focusEffectDisabled()
        .accessibilityLabel(part == .day ? "Date" : part == .hour ? "Hour" : "Minute")
        .accessibilityValue(Self.formatter(part).string(from: selection))
        .accessibilityAdjustableAction { direction in
            picked = part
            step(direction == .increment ? 1 : -1)
        }
    }

    private func step(_ delta: Int) {
        let unit: Calendar.Component = switch active { case .day: .day; case .hour: .hour; case .minute: .minute }
        guard let next = Calendar.current.date(byAdding: unit, value: delta, to: selection) else { return }
        selection = minimum.map { max(next, $0) } ?? next
    }

    static var dayGap: CGFloat { 6 }
    static var segmentPadding: CGFloat { 2 }

    static let uses12Hour = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current)?.contains("a") ?? false

    private static func make(_ format: String, template: Bool = false) -> DateFormatter {
        let formatter = DateFormatter()
        if template { formatter.setLocalizedDateFormatFromTemplate(format) } else { formatter.dateFormat = format }
        return formatter
    }

    private static let day = make("EEEMMMd", template: true)
    private static let hour = make(uses12Hour ? "h" : "HH")
    private static let minute = make("mm")
    private static let period = make("a")

    private static func formatter(_ part: Part) -> DateFormatter {
        switch part { case .day: day; case .hour: hour; case .minute: minute }
    }
}
