import AppKit
import SwiftUI

private typealias C = OnePlusLinearColor
private typealias M = OnePlusLinearMetrics
private typealias A = OnePlusAboutMetrics

// MARK: - Pro: the license card

/// One label-value row of a license card, such as "Licensed to" / "suraj@samhq.app".
public struct OnePlusAboutLicenseRow: Identifiable {
    public let label: String
    public let value: String
    public var id: String { label }
    public init(_ label: String, _ value: String) { self.label = label; self.value = value }
}

/// The About window of a paid app: icon over a quiet activity line, then the license card with the thank-you header.
public struct OnePlusAboutProLicense: View {
    private let info: OnePlusAboutInfo
    private let update: OnePlusAboutUpdate
    private let rows: [OnePlusAboutLicenseRow]
    private let manage: (() -> Void)?
    public static let size = A.proWindow

    public init(info: OnePlusAboutInfo, update: OnePlusAboutUpdate = .none, rows: [OnePlusAboutLicenseRow],
                manage: (() -> Void)? = nil) {
        self.info = info; self.update = update; self.rows = rows; self.manage = manage
    }

    public var body: some View {
        VStack(spacing: 0) {
            ZStack {
                OnePlusAboutActivityLine(color: info.tints[0]).frame(height: A.activityHeight).offset(y: A.activityOffset)
                OnePlusAboutGlow(tint: info.tints[0])
                OnePlusAboutIcon(info.icon, size: A.proIcon, shadow: A.windowIconShadow)
            }
            .frame(height: A.proHeader).padding(.top, A.proHeaderTop)
            Text(info.name).aboutText(A.proTitle, weight: .semibold)
            OnePlusAboutUpdateLine(info: info, update: update).padding(.top, A.taglineTop + 2)
            card.padding(.horizontal, A.cardInset).padding(.top, A.cardTop)
            Spacer(minLength: 0)
            OnePlusAboutFooterLinks(info: info).padding(.bottom, A.footerBottom)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background(C.window)
    }

    private var card: some View {
        VStack(spacing: 0) {
            HStack(spacing: A.cardGlyphGap) {
                Image(systemName: "checkmark.seal.fill").font(.system(size: A.sealGlyph)).foregroundStyle(C.success)
                Text("Thanks for your support").aboutText(M.body, weight: .semibold)
                Spacer(minLength: 0)
                if let manage { Button("Manage…", action: manage).buttonStyle(OnePlusLinearButtonStyle(.inline)) }
            }
            .padding(.horizontal, A.cardPadding).frame(height: A.cardHeader)
            .overlay(alignment: .bottom) { C.line.frame(height: 1) }
            ForEach(rows) { row in
                HStack {
                    Text(row.label).aboutText(M.control, color: C.secondary)
                    Spacer(minLength: M.rowGap)
                    Text(verbatim: row.value).aboutText(M.control, weight: .medium).lineLimit(1).truncationMode(.middle)
                        .textSelection(.enabled)
                }
                .padding(.horizontal, A.cardPadding).frame(height: A.cardRow)
                .overlay(alignment: .bottom) { if row.id != rows.last?.id { C.lineSoft.frame(height: 1) } }
            }
        }
        .aboutGroup()
    }
}

/// "Website  ·  Release notes  ·  Licenses  ·  © 2026 Suraj Mandal", each link a quiet text button.
struct OnePlusAboutFooterLinks: View {
    let info: OnePlusAboutInfo
    var body: some View {
        HStack(spacing: A.footerGap) {
            ForEach(links) { link in
                Button(link.label) { OnePlusAbout.open(link.url) }.buttonStyle(.plain)
                    .aboutText(M.caption, color: C.muted)
                Text("·").aboutText(M.caption, color: C.tertiary)
            }
            Text(info.copyright).aboutText(M.caption, color: C.muted)
        }
    }

    private var links: [OnePlusAboutLink] {
        [info.website.map { OnePlusAboutLink("Website", title: $0.title, url: $0.url) },
         info.releaseNotes.map { OnePlusAboutLink("Release notes", title: $0.title, url: $0.url) },
         info.license.map { OnePlusAboutLink("Licenses", title: $0.title, url: $0.url) }].compactMap { $0 }
    }
}

/// A static spiky activity line that fades out at both ends, the look of a system monitor's CPU history.
struct OnePlusAboutActivityLine: View {
    let color: Color
    private static let samples: [CGFloat] = {
        var seed: UInt64 = 0x9E3779B97F4A7C15
        return (0..<40).map { index in
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let noise = CGFloat(seed >> 33) / CGFloat(UInt32.max >> 1)
            let spike: CGFloat = [7, 15, 22, 31, 36].contains(index) ? 0.45 : 0
            return 0.18 + noise * 0.28 + spike
        }
    }()

    var body: some View {
        Canvas { context, size in
            let step = A.activityPeriod / CGFloat(Self.samples.count)
            var points: [CGPoint] = []
            var x = -A.activityPhase * A.activityPeriod
            var index = 0
            while x <= size.width + step {
                let value = Self.samples[index % Self.samples.count]
                points.append(CGPoint(x: x, y: size.height * 0.92 - value * size.height * 0.62))
                x += step; index += 1
            }
            var line = Path()
            line.addLines(points)
            var fill = line
            fill.addLine(to: CGPoint(x: points[points.count - 1].x, y: size.height))
            fill.addLine(to: CGPoint(x: points[0].x, y: size.height))
            fill.closeSubpath()
            context.fill(fill, with: .linearGradient(Gradient(colors: [color.opacity(A.activityFill), color.opacity(0)]),
                                                    startPoint: CGPoint(x: 0, y: size.height * 0.2),
                                                    endPoint: CGPoint(x: 0, y: size.height)))
            context.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: A.activityStroke, lineJoin: .round))
        }
        .mask {
            LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.18),
                                   .init(color: .black, location: 0.82), .init(color: .clear, location: 1)],
                           startPoint: .leading, endPoint: .trailing)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Classic: the compare table with Buy now

/// One compare row: a feature and whether the free app has it. The paid app has every row.
public struct OnePlusAboutCompareRow: Identifiable {
    public let feature: String
    public let free: Bool
    public var id: String { feature }
    public init(_ feature: String, free: Bool) { self.feature = feature; self.free = free }
}

/// The paid sibling a free app offers: its name, icon, price line, and where Buy now goes.
public struct OnePlusAboutUpgrade {
    public let name: String
    public let shortName: String
    public let icon: NSImage
    public let price: String
    public let buy: URL
    public let note: String
    public init(name: String, shortName: String, icon: NSImage, price: String, buy: URL, note: String) {
        self.name = name; self.shortName = shortName; self.icon = icon; self.price = price; self.buy = buy; self.note = note
    }
}

/// The About window of a free app with a paid sibling: header, the free vs paid table, a note, and Buy now.
public struct OnePlusAboutCompare: View {
    private let info: OnePlusAboutInfo
    private let freeName: String
    private let rows: [OnePlusAboutCompareRow]
    private let upgrade: OnePlusAboutUpgrade
    public static let size = A.classicWindow

    public init(info: OnePlusAboutInfo, freeName: String, rows: [OnePlusAboutCompareRow], upgrade: OnePlusAboutUpgrade) {
        self.info = info; self.freeName = freeName; self.rows = rows; self.upgrade = upgrade
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: A.classicHeaderGap) {
                OnePlusAboutIcon(info.icon, size: A.classicIcon, shadow: A.noShadow)
                VStack(alignment: .leading, spacing: A.taglineTop) {
                    Text(info.name).aboutText(A.classicTitle, weight: .semibold)
                    Text("\(info.versionLine)  ·  Free").aboutText(M.caption, color: C.muted)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, A.classicHeaderTop).padding(.horizontal, M.gutter)
            HStack {
                Spacer(minLength: 0)
                Text(freeName).aboutText(M.caption, weight: .medium, color: C.muted).frame(width: A.compareColumn)
                Text(upgrade.shortName).aboutText(M.caption, weight: .semibold, color: C.cpuText).frame(width: A.compareColumn)
            }
            .padding(.horizontal, M.gutter + A.cardPadding).padding(.top, A.compareHeadTop)
            table.padding(.horizontal, M.gutter).padding(.top, A.compareTop)
            Text(upgrade.note).aboutText(M.caption, color: C.muted)
                .padding(.horizontal, M.gutter).padding(.top, A.compareNoteTop)
            Spacer(minLength: 0)
            footer
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background(C.window)
    }

    private var table: some View {
        VStack(spacing: 0) {
            ForEach(rows) { row in
                HStack(spacing: 0) {
                    Text(row.feature).aboutText(M.control).frame(maxWidth: .infinity, alignment: .leading)
                    mark(row.free, paid: false).frame(width: A.compareColumn)
                    mark(true, paid: true).frame(width: A.compareColumn)
                }
                .padding(.horizontal, A.cardPadding).frame(height: A.compareRow)
                .overlay(alignment: .bottom) { if row.id != rows.last?.id { C.lineSoft.frame(height: 1) } }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(row.feature): \(freeName) \(row.free ? "yes" : "no"), \(upgrade.shortName) yes")
            }
        }
        .aboutGroup()
    }

    private func mark(_ yes: Bool, paid: Bool) -> some View {
        Image(systemName: yes ? "checkmark" : "minus").font(.system(size: M.caption, weight: .bold))
            .foregroundStyle(yes ? (paid ? C.cpuText : C.secondary) : C.tertiary)
    }

    private var footer: some View {
        HStack(spacing: A.cardGlyphGap) {
            OnePlusAboutIcon(upgrade.icon, size: A.upgradeIcon, shadow: A.noShadow)
            VStack(alignment: .leading, spacing: 2) {
                Text(upgrade.name).aboutText(M.body, weight: .semibold)
                Text(upgrade.price).aboutText(M.caption, color: C.muted)
            }
            Spacer(minLength: 0)
            Button("Buy now") { OnePlusAbout.open(upgrade.buy) }.buttonStyle(OnePlusLinearButtonStyle(.filled))
        }
        .padding(.horizontal, A.footerPadding).frame(height: A.footer)
        .background(C.panelFooter)
        .overlay(alignment: .top) { C.line.frame(height: 1) }
    }
}

// MARK: - The window

/// Opens one About window per app: fixed size, close button only, its last position restored before it shows.
@MainActor
public enum OnePlusAboutWindow {
    private static var window: NSWindow?

    public static func show<Content: View>(size: CGSize, @ViewBuilder content: () -> Content) {
        let root = content()
            .ignoresSafeArea()
            .onePlusFocusPolicy()
            .onePlusAppAppearance()
        if let window {
            (window.contentViewController as? NSHostingController<AnyView>)?.rootView = AnyView(root)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }
        let host = NSHostingController(rootView: AnyView(root))
        host.sizingOptions = []
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                              styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        window.contentViewController = host
        window.setContentSize(size)
        window.identifier = NSUserInterfaceItemIdentifier("about")
        window.title = "About"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.backgroundColor = NSColor(C.window)
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.center()
        window.setFrameAutosaveName("OnePlusAboutWindow")
        if let screen = window.screen ?? NSScreen.main, !screen.visibleFrame.contains(window.frame) { window.center() }
        Self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }
}
