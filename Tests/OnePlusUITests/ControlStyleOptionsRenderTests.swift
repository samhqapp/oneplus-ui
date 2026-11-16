import AppKit
import SwiftUI
import XCTest
@testable import OnePlusUIShowcase

/// Writes the round 3 control-style options as full Ruler Defaults applets, Light and Dark at 2x.
@MainActor
final class ControlStyleOptionsRenderTests: XCTestCase {
    private static let output = "/Volumes/External1TB/data/_custom/orca/workspaces/powertoys/v15-controls-r3"

    func testRenderControlStyleOptions() throws {
        try FileManager.default.createDirectory(atPath: Self.output, withIntermediateDirectories: true)
        let size = CGSize(width: 420, height: 500)
        let samples = [("quietRaised", ControlStyleRulerDefaults(option: .quietRaised))]
            + ResetStyle.allCases.map { ("reset-\($0.rawValue)", ControlStyleRulerDefaults(option: .quietRaised, reset: $0)) }
        for (name, sample) in samples {
            for appearance: NSAppearance.Name in [.aqua, .darkAqua] {
                let render = try LinearRender.bitmap(NSHostingView(rootView: sample.frame(width: size.width, height: size.height)),
                                                     size: size, scale: 2, appearance: appearance)
                let data = try XCTUnwrap(render.retagging(with: .sRGB)?.representation(using: .png, properties: [:]))
                try data.write(to: URL(fileURLWithPath: "\(Self.output)/\(name)-\(appearance == .darkAqua ? "dark" : "light").png"))
            }
        }
    }
}
