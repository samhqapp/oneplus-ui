import AppKit
@testable import OnePlusUI
import SwiftUI
import XCTest

@MainActor
final class OnePlusContextMenuTests: XCTestCase {
    private let screen = CGRect(x: 0, y: 0, width: 1512, height: 982), size = CGSize(width: 236, height: 300)

    func testMenuOpensAtTheClickAndStaysOnScreen() {
        let inside = onePlusContextMenuFrame(click: CGPoint(x: 400, y: 800), size: size, screen: screen)
        XCTAssertEqual(inside, CGRect(x: 400, y: 500, width: 236, height: 300), "top-left corner on the click")
        let corner = onePlusContextMenuFrame(click: CGPoint(x: 1500, y: 20), size: size, screen: screen)
        XCTAssertEqual(corner.maxX, screen.maxX - 4, "kept 4 pt inside the right edge")
        XCTAssertEqual(corner.minY, 4, "kept 4 pt above the bottom edge")
        let top = onePlusContextMenuFrame(click: CGPoint(x: -20, y: 990), size: size, screen: screen)
        XCTAssertEqual(top.minX, 4)
        XCTAssertEqual(top.maxY, screen.maxY - 4, "kept 4 pt under the top edge")
    }

    func testArrowsSkipDisabledRowsAndWrap() {
        let a = OnePlusPopupMenuItem("New note") {}, off = OnePlusPopupMenuItem("Off", isEnabled: false) {}
        let b = OnePlusPopupMenuItem("Delete", role: .destructive) {}
        let session = OnePlusContextMenuSession(entries: [.item(a), .separator(), .item(off), .item(b)])
        var picked: UUID?
        session.select = { picked = $0 }
        XCTAssertNil(session.highlightedID, "nothing is highlighted on open")
        XCTAssertTrue(session.handle(.select))
        XCTAssertNil(picked, "Return with nothing highlighted picks nothing")
        _ = session.handle(.down)
        XCTAssertEqual(session.highlightedID, a.id)
        _ = session.handle(.down)
        XCTAssertEqual(session.highlightedID, b.id, "the disabled row is skipped")
        _ = session.handle(.down)
        XCTAssertEqual(session.highlightedID, a.id, "wraps to the top")
        _ = session.handle(.select)
        XCTAssertEqual(picked, a.id)
    }

    /// ONEPLUS_MENU_RENDER=<folder> saves the menu and the format pill in Light and Dark for a look.
    func testMenuAndPillRender() throws {
        guard let folder = ProcessInfo.processInfo.environment["ONEPLUS_MENU_RENDER"] else { return }
        let entries: [OnePlusPopupMenuEntry] = [
            .item(.init("New note", systemImage: "plus") {}), .item(.init("Rename", systemImage: "pencil") {}),
            .separator(), .item(.init("Open window", systemImage: "macwindow") {}),
            .item(.init("Float on top", systemImage: "pin", isSelected: true) {}), .separator(),
            .item(.init("Settings…", systemImage: "gearshape") {}), .separator(),
            .item(.init("Delete", systemImage: "trash", role: .destructive) {}),
        ]
        let header = VStack(spacing: 0) {
            HStack {
                Text("Bank").font(.system(size: 13, weight: .semibold))
                Spacer()
                HStack(spacing: OnePlusContextMenuMetrics.swatchGap) {
                    ForEach([Color.yellow, .orange, .pink, .blue, .green], id: \.self) { color in
                        OnePlusContextMenuSwatch("Color", color: color, isSelected: color == .yellow) {}
                    }
                }
            }
            .padding(EdgeInsets(top: 2, leading: 5, bottom: 8, trailing: 5))
            HStack(spacing: OnePlusContextMenuMetrics.tileGap) {
                ForEach(["Ribbon", "Split", "Tab", "Side"], id: \.self) { name in
                    OnePlusContextMenuTile(name, isSelected: name == "Tab") {} picture: {
                        RoundedRectangle(cornerRadius: 3).frame(width: 14, height: 8)
                    }
                }
            }
            .padding(.horizontal, 2).padding(.bottom, 2)
            OnePlusContextMenuSeparator()
        }
        let session = OnePlusContextMenuSession(entries: entries)
        session.hover(entries[0].id)
        let pill = OnePlusFloatingToolbar(shown: true) {
            OnePlusFloatingToolbarButton("Bold", isActive: true) {} label: { Text("B") }
            OnePlusFloatingToolbarButton("Italic") {} label: { Text("I").italic() }
            OnePlusFloatingToolbarButton("Strikethrough") {} label: { Text("S").strikethrough() }
            OnePlusFloatingToolbarSeparator()
            OnePlusFloatingToolbarButton("Bullet list") {} label: { Image(systemName: "list.bullet") }
            OnePlusFloatingToolbarButton("Checklist") {} label: { Image(systemName: "checklist") }
        }
        let appAppearance = NSApplication.shared.appearance
        defer { NSApplication.shared.appearance = appAppearance }
        for name in [NSAppearance.Name.aqua, .darkAqua] {
            NSApplication.shared.appearance = NSAppearance(named: name)
            let menu = OnePlusContextMenuView(session: session, header: header, anchor: .topLeading, shown: true)
                .padding(30).background(OnePlusLinearColor.window)
            let menuHost = NSHostingView(rootView: menu)
            let menuRender = try LinearRender.bitmap(menuHost, size: menuHost.fittingSize, scale: 2, appearance: name)
            try menuRender.representation(using: .png, properties: [:])?
                .write(to: URL(fileURLWithPath: folder).appendingPathComponent("menu-\(name.rawValue).png"))
            // ImageRenderer: cacheDisplay draws a stroked capsule with stray straight lines at its ends.
            let renderer = ImageRenderer(content: pill.padding(24).background(OnePlusLinearColor.window)
                .environment(\.colorScheme, name == .darkAqua ? .dark : .light))
            renderer.scale = 2
            let image = try XCTUnwrap(renderer.cgImage)
            try NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])?
                .write(to: URL(fileURLWithPath: folder).appendingPathComponent("pill-\(name.rawValue).png"))
        }
    }
}
