import AppKit
import SwiftUI
import XCTest
@testable import OnePlusUI

/// The tool page header: beside a launch tile it is exactly the tile's height; with no actions it keeps the 48 pt look.
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

    private func height<V: View>(_ view: V) -> CGFloat {
        let host = NSHostingView(rootView: view.frame(width: width))
        return host.fittingSize.height
    }

    func testHeaderBesideTileMatchesTileHeight() {
        for (name, detail) in tools {
            let header = OnePlusLinearToolHeader(name, detail: detail) { size in Color.gray.frame(width: size, height: size) } actions: {
                OnePlusLinearLaunchTile(shortcut: "⇧⌘3", caption: "Pick Color") {}
            }
            XCTAssertEqual(height(header), M.launchTile.height, accuracy: 1, name)
            XCTAssertEqual(M.launchHeaderIcon, M.launchTile.height)
        }
    }

    func testDescriptionBesideTileIsNeverCut() {
        let textWidth = width - M.launchHeaderIcon - M.headerGap - M.headerTileGap - M.launchTile.width
        for (name, detail) in tools {
            let text = { (lines: Int?) in
                Text(detail).linearText(M.launchHeaderDetail).lineLimit(lines).fixedSize(horizontal: false, vertical: true)
                    .frame(width: textWidth, alignment: .leading)
            }
            let host = { (lines: Int?) in NSHostingView(rootView: text(lines)).fittingSize.height }
            XCTAssertEqual(host(M.launchHeaderDetailLines), host(nil), accuracy: 0.5, "\(name) needs more than 3 lines")
        }
    }

    func testHeaderWithoutActionsIsUnchanged() {
        for (name, detail) in tools {
            let header = OnePlusLinearToolHeader(name, detail: detail) { Color.gray } actions: { EmptyView() }
            let reference = HStack(alignment: .top, spacing: M.headerGap) {
                Color.gray.frame(width: M.headerTileIcon, height: M.headerTileIcon)
                OnePlusLinearPageTitle(name, subtitle: detail, subtitleLines: M.headerDetailLines)
            }.frame(maxWidth: .infinity, alignment: .leading)
            XCTAssertEqual(height(header), height(reference), accuracy: 0.01, name)
        }
    }
}
