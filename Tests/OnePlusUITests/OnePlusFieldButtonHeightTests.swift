import AppKit
import SwiftUI
import XCTest
@testable import OnePlusUI

/// A field, select, search, or stepper beside a button is the button's height in every size step:
/// 28 pt on a page (Raised keys), 24 pt in an applet (Quiet raised) and in the menu panel (no look).
@MainActor
final class OnePlusFieldButtonHeightTests: XCTestCase {
    func testInputsMatchTheButtonHeightInEverySizeStep() {
        let steps: [(String, OnePlusLinearControlLook?, CGFloat)] = [("page", .raisedKeys, 28), ("applet", .quietRaised, 24), ("panel", nil, 24)]
        let inputs: [(String, AnyView)] = [
            ("field", AnyView(OnePlusLinearTextField("Process ID", text: .constant("")).frame(width: 110))),
            ("select", AnyView(OnePlusLinearSelect(choices: [(0, "HEX")], selection: .constant(0), accessibilityLabel: "Format", width: 80))),
            ("search", AnyView(OnePlusLinearSearchField("Search", text: .constant(""), style: .applet).frame(width: 120))),
            ("stepper", AnyView(OnePlusStepperField("Minutes", value: .constant(15), in: 1...99, unit: "min").frame(width: 100))),
        ]
        for (step, look, expected) in steps {
            let button = height(Button("Attach") {}.buttonStyle(OnePlusLinearButtonStyle(.soft)), look)
            XCTAssertEqual(button, expected, accuracy: 0.01, "\(step) button")
            for (name, view) in inputs { XCTAssertEqual(height(view, look), button, accuracy: 0.01, "\(step) \(name) is not the button's height") }
        }
    }

    private func height<V: View>(_ view: V, _ look: OnePlusLinearControlLook?) -> CGFloat {
        NSHostingView(rootView: view.environment(\.onePlusLinearControlLook, look)).fittingSize.height
    }
}
