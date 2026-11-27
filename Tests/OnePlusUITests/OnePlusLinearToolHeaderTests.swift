import AppKit
import SwiftUI
import XCTest
@testable import OnePlusUI

/// The tool page header, "Small icon in the name line": the name line, then a description that is never cut at 3 lines.
@MainActor
final class OnePlusLinearToolHeaderTests: XCTestCase {
    private typealias M = OnePlusLinearEditorialMetrics
    /// The 820 pt main window: 605 pt pane less two 32 pt gutters.
    private let width: CGFloat = 541
    private let tools = [
        ("Color Picker", "Pick any color on screen, copy it, and keep a searchable history."),
        ("Text Extractor", "Select text anywhere on screen and copy it. Runs fully on your Mac."),
        ("Input Devices", "Tune mouse and trackpad scrolling: direction, speed, and smoothing."),
        ("Mac Tweaks", "Small Mac settings in one place, like Mic Lock for Bluetooth sound."),
        ("Event Viewer", "See MacPowerToys activity and recent macOS errors and faults."),
        ("Portman", "See local dev servers and forward private SSH ports to this Mac."),
        ("RSync UI", "Sync folders to the cloud with live progress and automatic retries."),
        ("Ruler", "Measure the screen with rulers in pixels, millimeters, or inches."),
        ("Awake", "Keep your Mac awake for good, for a while, or until a set time."),
        // The 70-character catalog limit, with wide letters.
        ("Marketplace Window Manager", "WWW MMMM Measure every window and margin with rulers, in pixels or mm."),
    ]

    private func height<V: View>(_ view: V, width: CGFloat) -> CGFloat {
        NSHostingView(rootView: view.frame(width: width)).fittingSize.height
    }

    private func detailHeight(_ detail: String, width: CGFloat) -> CGFloat {
        height(Text(detail).linearText(M.headerDetail).lineLimit(M.headerDetailLines).fixedSize(horizontal: false, vertical: true),
               width: width)
    }

    func testDescriptionBesideTileIsNeverCut() {
        let textWidth = width - M.headerTileGap - M.launchTile.width
        for (name, detail) in tools {
            let full = height(Text(detail).linearText(M.headerDetail).fixedSize(horizontal: false, vertical: true), width: textWidth)
            XCTAssertEqual(detailHeight(detail, width: textWidth), full, accuracy: 0.5, "\(name) needs more than 3 lines")
        }
    }

    func testHeaderIsNameLineOverDescriptionBesideTile() {
        let textWidth = width - M.headerTileGap - M.launchTile.width
        for (name, detail) in tools {
            let header = OnePlusLinearToolHeader(name, detail: detail) { size in Color.gray.frame(width: size, height: size) } actions: {
                OnePlusLinearLaunchTile(shortcut: "⇧⌘3", caption: "Pick Color") {}
            }
            let text = M.headerNameLine + M.headerDetailGap + detailHeight(detail, width: textWidth)
            XCTAssertEqual(height(header, width: width), max(text, M.launchTile.height), accuracy: 1, name)
        }
    }
}
