import AppKit
import SwiftUI
import XCTest
@testable import OnePlusUI

/// No shift on state change: a label that turns medium when selected keeps its width.
@MainActor
final class OnePlusSteadyTextTests: XCTestCase {
    private func width(_ view: some View) -> CGFloat { NSHostingView(rootView: view.fixedSize()).fittingSize.width }

    func testPlainWeightFlipChangesWidth() {
        // The failing case the steady text exists for: a plain weight flip widens "Accurate".
        XCTAssertNotEqual(width(Text("Accurate").linearText(weight: .regular)),
                          width(Text("Accurate").linearText(weight: .medium)))
    }

    func testSteadyTextKeepsWidthWhenSelected() {
        XCTAssertEqual(width(Text("Accurate").linearSteadyText(selected: false)),
                       width(Text("Accurate").linearSteadyText(selected: true)), accuracy: 0.01,
                       "Use linearSteadyText for any label whose weight follows selection.")
    }

    func testFittedSegmentedKeepsWidthAcrossPicks() {
        func segmented(_ pick: Int) -> some View {
            OnePlusLinearSegmented(choices: [(0, "Fast"), (1, "Accurate"), (2, "Custom")], selection: .constant(pick),
                                   accessibilityLabel: "Mode", sizing: .fitted)
        }
        XCTAssertEqual(width(segmented(0)), width(segmented(1)), accuracy: 0.01)
    }
}
