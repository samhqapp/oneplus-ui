import SwiftUI

/// One keyboard key: 20 pt high, at least 20 pt wide, 11 pt medium `secondary` text on the `kbd` fill with a 1 pt
/// `line` ring, radius 5, and a 1 pt contact shadow.
public struct OnePlusLinearKeyCap: View {
    private let key: String
    public init(_ key: String) { self.key = key }
    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: 5, style: .continuous)
        Text(key).linearText(OnePlusLinearMetrics.caption, weight: .medium, color: OnePlusLinearColor.secondary).fixedSize()
            .frame(minWidth: 20).frame(height: 20).padding(.horizontal, key.count > 1 ? 4 : 0)
            .background(shape.fill(OnePlusLinearColor.kbd))
            .overlay(shape.strokeBorder(OnePlusLinearColor.line, lineWidth: 1))
            .shadow(color: OnePlusLinearColor.fillTileContact, radius: 0, y: 1)
    }
}

/// A shortcut as one key cap per key, 3 pt apart.
public struct OnePlusLinearKeyCombo: View {
    private let keys: [String]
    public init(keys: [String]) { self.keys = keys }
    /// Splits a shortcut such as "⌘⇧3" or "⌃⌥Space" into its modifier glyphs and the key.
    public init(_ shortcut: String) { keys = Self.keys(in: shortcut) }
    public var body: some View {
        HStack(spacing: 3) { ForEach(keys.indices, id: \.self) { OnePlusLinearKeyCap(keys[$0]) } }
            .accessibilityElement(children: .ignore).accessibilityLabel(keys.joined(separator: " "))
    }

    public static func keys(in shortcut: String) -> [String] {
        let modifiers = "⌘⇧⌥⌃"
        let mods = shortcut.prefix { modifiers.contains($0) }.map(String.init)
        let key = shortcut.drop { modifiers.contains($0) }
        return mods + (key.isEmpty ? [] : [String(key)])
    }
}

/// One How to use step: a 13 pt accent glyph and the step text.
public struct OnePlusLinearChecklistStep: Sendable, Hashable {
    public let symbol: String
    public let text: String
    public init(_ symbol: String, _ text: String) { self.symbol = symbol; self.text = text }
}

/// One How to use shortcut: the keys and what they do.
public struct OnePlusLinearChecklistKey: Sendable, Hashable {
    public let keys: [String]
    public let text: String
    public init(_ keys: [String], _ text: String) { self.keys = keys; self.text = text }
}

/// The "Checklist" How to use card (owner pick 2026-11-19): one radius 12 group, the steps as 40 pt rows with an
/// accent glyph, then the shortcuts as 36 pt rows with a keyboard glyph and the key caps trailing, then notes as
/// rows with an info glyph. Rows after the first have a `lineSoft` hairline from the text edge.
public struct OnePlusLinearChecklist: View {
    private let steps: [OnePlusLinearChecklistStep]
    private let keys: [OnePlusLinearChecklistKey]
    private let notes: [String]
    public init(steps: [OnePlusLinearChecklistStep], keys: [OnePlusLinearChecklistKey] = [], notes: [String] = []) {
        self.steps = steps; self.keys = keys; self.notes = notes
    }
    public var body: some View {
        VStack(spacing: 0) {
            ForEach(steps.indices, id: \.self) { index in
                row(symbol: steps[index].symbol, tint: OnePlusLinearColor.accent, text: steps[index].text, height: 40, first: index == 0)
            }
            ForEach(keys.indices, id: \.self) { index in
                row(symbol: "keyboard", tint: OnePlusLinearColor.secondary, text: keys[index].text, height: 36,
                    first: steps.isEmpty && index == 0) { OnePlusLinearKeyCombo(keys: keys[index].keys) }
            }
            ForEach(notes.indices, id: \.self) { index in
                row(symbol: "info.circle", tint: OnePlusLinearColor.secondary, text: notes[index], height: 36,
                    first: steps.isEmpty && keys.isEmpty && index == 0)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(OnePlusLinearColor.fillGroup)
                .shadow(color: OnePlusLinearColor.fillTileContact, radius: 0.75, y: 0.5)
                .shadow(color: OnePlusLinearColor.fillTileShadow, radius: 8, y: 3)
        }
    }

    private func row(symbol: String, tint: Color, text: String, height: CGFloat, first: Bool,
                     @ViewBuilder trailing: () -> some View = { EmptyView() }) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 13)).foregroundStyle(tint).frame(width: 18).accessibilityHidden(true)
            Text(text).linearText(color: OnePlusLinearColor.ink).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            trailing()
        }
        .padding(.horizontal, 14).padding(.vertical, 8).frame(minHeight: height)
        .overlay(alignment: .top) { if !first { OnePlusLinearColor.lineSoft.frame(height: 1).padding(.leading, 44) } }
        .accessibilityElement(children: .combine)
    }
}
