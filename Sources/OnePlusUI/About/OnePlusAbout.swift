import AppKit
import SwiftUI

private typealias C = OnePlusLinearColor
private typealias M = OnePlusLinearMetrics
private typealias A = OnePlusAboutMetrics

/// A link row or button on an About surface: "Website" opens `url`.
public struct OnePlusAboutLink: Identifiable {
    public let label: String
    public let title: String
    public let url: URL
    public var id: String { label }
    public init(_ label: String, title: String, url: URL) { self.label = label; self.title = title; self.url = url }
}

/// An app's update state as the About surfaces show it. `check` is nil when the app has no updater.
public struct OnePlusAboutUpdate {
    public enum State: Equatable { case idle, checking, current, available(String), failed }
    public let state: State
    public let check: (() -> Void)?
    public init(_ state: State, check: (() -> Void)?) { self.state = state; self.check = check }
    public static var none: Self { Self(.idle, check: nil) }

    var line: String? {
        switch state {
        case .idle: nil
        case .checking: "Checking for updates..."
        case .current: "Up to date"
        case .available(let version): "Version \(version) is available"
        case .failed: "Update check failed"
        }
    }
}

/// What every About surface shows. Name, version, build, and icon come from the bundle.
public struct OnePlusAboutInfo {
    public let name: String
    public let tagline: String
    public let version: String
    public let build: String
    public let icon: NSImage
    public let website: OnePlusAboutLink?
    public let releaseNotes: OnePlusAboutLink?
    public let support: String?
    public let license: OnePlusAboutLink?
    public let credits: [OnePlusAboutLink]
    public let copyright: String
    /// The icon's most colorful points, for the color field and glow.
    public let tints: [Color]

    public init(bundle: Bundle = .main, name: String? = nil, tagline: String, icon: NSImage? = nil,
                website: OnePlusAboutLink? = nil, releaseNotes: OnePlusAboutLink? = nil, support: String? = nil,
                license: OnePlusAboutLink? = nil, credits: [OnePlusAboutLink] = [],
                copyright: String = "© 2026 Suraj Mandal") {
        let info = bundle.infoDictionary ?? [:]
        self.name = name ?? (info["CFBundleDisplayName"] as? String) ?? (info["CFBundleName"] as? String) ?? ""
        self.tagline = tagline
        version = info["CFBundleShortVersionString"] as? String ?? ""
        build = info["CFBundleVersion"] as? String ?? ""
        self.icon = icon ?? NSApp.applicationIconImage ?? NSImage()
        self.website = website; self.releaseNotes = releaseNotes; self.support = support
        self.license = license; self.credits = credits; self.copyright = copyright
        tints = Self.colors(of: self.icon)
    }

    public var versionLine: String { build.isEmpty || build == version ? "Version \(version)" : "Version \(version) (\(build))" }

    static func colors(of image: NSImage) -> [Color] {
        let side = 8
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8,
                                         samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                                         bytesPerRow: 0, bitsPerPixel: 0) else { return [C.accent, C.accent] }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(x: 0, y: 0, width: side, height: side))
        NSGraphicsContext.restoreGraphicsState()
        var pixels: [NSColor] = []
        for x in 0..<side { for y in 0..<side { if let c = rep.colorAt(x: x, y: y), c.alphaComponent > 0.6 { pixels.append(c) } } }
        guard !pixels.isEmpty else { return [C.accent, C.accent] }
        let sorted = pixels.sorted { $0.saturationComponent * $0.brightnessComponent > $1.saturationComponent * $1.brightnessComponent }
        return [sorted[0], sorted[sorted.count / 5]].map { Color(nsColor: $0) }
    }
}

public enum OnePlusAbout {
    /// The About window's Animation setting (Bool, default on). Reduce Motion always stops the glow.
    public static let animationKey = "onePlusAbout.animation"

    static func open(_ url: URL) { NSWorkspace.shared.open(url) }
}

// MARK: - Settings > About: the centered hero

/// Settings > About for any app: centered icon hero, Links, Credits, the About window Animation setting,
/// then `content` (app sections such as a license card), then the copyright line.
public struct OnePlusAboutSettingsSection<Content: View>: View {
    private let info: OnePlusAboutInfo
    private let update: OnePlusAboutUpdate
    private let content: Content
    @AppStorage(OnePlusAbout.animationKey) private var animates = true

    public init(info: OnePlusAboutInfo, update: OnePlusAboutUpdate = .none, @ViewBuilder content: () -> Content) {
        self.info = info; self.update = update; self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: M.sectionGap) {
            hero
            section("Links") {
                ForEach(rowLinks) { link in
                    linkRow(link, separator: link.id != rowLinks.last?.id)
                }
            }
            if !info.credits.isEmpty {
                section("Credits") {
                    ForEach(info.credits) { link in linkRow(link, separator: link.id != info.credits.last?.id) }
                }
            }
            section("About window") {
                OnePlusSettingRow("Animation", caption: "The glow behind the icon breathes slowly.",
                                  controlWidth: OnePlusCatalogMetrics.placementWidth, separator: false) {
                    Toggle("Animation", isOn: $animates).toggleStyle(OnePlusLinearSwitchStyle())
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            content
            Text(info.copyright).aboutText(M.caption, color: C.muted).frame(maxWidth: .infinity)
        }
    }

    private var rowLinks: [OnePlusAboutLink] {
        var links = [info.website, info.releaseNotes].compactMap { $0 }
        if let support = info.support, let url = URL(string: "mailto:" + support) {
            links.append(OnePlusAboutLink("Support", title: support, url: url))
        }
        if let license = info.license { links.append(license) }
        return links
    }

    private var hero: some View {
        VStack(spacing: 0) {
            OnePlusAboutIcon(info.icon, size: A.heroIcon)
            Text(info.name).aboutText(A.heroTitle, weight: .semibold).padding(.top, A.heroTitleTop)
            Text(info.tagline).aboutText(M.control, color: C.secondary).padding(.top, A.taglineTop)
            Text(update.line.map { "\(info.versionLine)  ·  \($0)" } ?? info.versionLine)
                .aboutText(M.caption, color: C.muted).padding(.top, A.versionTop)
            if update.check != nil || info.releaseNotes != nil {
                HStack(spacing: M.rowGap) {
                    if let check = update.check {
                        Button(update.state == .checking ? "Checking..." : "Check for Updates", action: check)
                            .buttonStyle(OnePlusLinearButtonStyle(.raised)).disabled(update.state == .checking)
                    }
                    if let notes = info.releaseNotes {
                        Button("What's New") { OnePlusAbout.open(notes.url) }.buttonStyle(OnePlusLinearButtonStyle(.ghost))
                    }
                }
                .padding(.top, A.buttonsTop)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, A.heroTop)
    }

    private func section<Rows: View>(_ title: String, @ViewBuilder rows: () -> Rows) -> some View {
        VStack(alignment: .leading, spacing: M.sectionCaptionBelow) {
            OnePlusLinearSectionCaption(title)
            OnePlusCard { rows() }
        }
    }

    private func linkRow(_ link: OnePlusAboutLink, separator: Bool) -> some View {
        OnePlusSettingRow(link.label, controlWidth: OnePlusCatalogMetrics.placementWidth, separator: separator) {
            Button { OnePlusAbout.open(link.url) } label: {
                HStack(spacing: A.linkArrowGap) {
                    Text(verbatim: link.title).aboutText(M.control, color: C.secondary).lineLimit(1).truncationMode(.middle)
                    Image(systemName: "arrow.up.right").font(.system(size: A.linkArrow, weight: .semibold)).foregroundStyle(C.muted)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(link.url.absoluteString)
        }
    }
}

public extension OnePlusAboutSettingsSection where Content == EmptyView {
    init(info: OnePlusAboutInfo, update: OnePlusAboutUpdate = .none) { self.init(info: info, update: update) { EmptyView() } }
}

// MARK: - About window: the color field glow (free apps)

/// The About window of a free app: the icon on a soft color field taken from the icon, with a breathing glow.
public struct OnePlusAboutColorField: View {
    private let info: OnePlusAboutInfo
    private let update: OnePlusAboutUpdate
    public static let size = A.freeWindow

    public init(info: OnePlusAboutInfo, update: OnePlusAboutUpdate = .none) { self.info = info; self.update = update }

    public var body: some View {
        VStack(spacing: 0) {
            OnePlusAboutField(info: info, height: A.fieldHeight, iconSize: A.windowIcon)
            Text(info.name).aboutText(A.windowTitle, weight: .semibold)
            Text(info.tagline).aboutText(M.control, color: C.secondary).multilineTextAlignment(.center)
                .padding(.horizontal, M.gutter).padding(.top, A.taglineTop + 1)
            OnePlusAboutUpdateLine(info: info, update: update).padding(.top, A.versionTop + 2)
            if let check = update.check {
                Button("Check for Updates", action: check).buttonStyle(OnePlusLinearButtonStyle(.raised))
                    .disabled(update.state == .checking).padding(.top, A.windowButtonTop)
            }
            Spacer(minLength: 0)
            OnePlusAboutFooterLinks(info: info).padding(.bottom, A.footerBottom)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background(C.window)
    }
}

/// The color field header: blurred icon and two icon tints, faded into the window, with the breathing glow.
struct OnePlusAboutField: View {
    let info: OnePlusAboutInfo
    let height: CGFloat
    let iconSize: CGFloat
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let tints = info.tints
        ZStack {
            ZStack {
                Image(nsImage: info.icon).resizable().frame(width: A.fieldBlurIcon, height: A.fieldBlurIcon)
                    .blur(radius: A.fieldBlur)
                    .opacity(scheme == .dark ? A.fieldIconOpacity.dark : A.fieldIconOpacity.light)
                RadialGradient(colors: [tints[0].opacity(A.fieldTintOpacity.first), .clear],
                               center: UnitPoint(x: 0.2, y: 0.1), startRadius: 0, endRadius: A.fieldTintRadius.first)
                RadialGradient(colors: [tints[1].opacity(A.fieldTintOpacity.second), .clear],
                               center: UnitPoint(x: 0.85, y: 0.2), startRadius: 0, endRadius: A.fieldTintRadius.second)
            }
            .frame(maxWidth: .infinity).frame(height: height).clipped()
            .mask(LinearGradient(colors: [.black, .black, .clear], startPoint: .top, endPoint: .bottom))
            OnePlusAboutGlow(tint: tints[0])
            OnePlusAboutIcon(info.icon, size: iconSize, shadow: A.windowIconShadow)
        }
        .frame(maxWidth: .infinity).frame(height: height).clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(info.name) icon")
    }
}

/// A soft radial glow in the icon's tint. It breathes while the Animation setting is on and Reduce Motion is off.
struct OnePlusAboutGlow: View {
    let tint: Color
    @AppStorage(OnePlusAbout.animationKey) private var animates = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.controlActiveState) private var active
    @State private var bright = false

    private var breathing: Bool { animates && !reduceMotion && active != .inactive }

    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [tint.opacity(A.glowOpacity.max), .clear], center: .center,
                                 startRadius: 0, endRadius: A.glow / 2))
            .frame(width: A.glow, height: A.glow)
            .opacity(bright ? 1 : A.glowOpacity.min / A.glowOpacity.max)
            .onAppear { breathe(breathing) }
            .onChange(of: breathing) { _, on in breathe(on) }
    }

    private func breathe(_ on: Bool) {
        if on {
            withAnimation(.easeInOut(duration: A.glowBreath).repeatForever(autoreverses: true)) { bright = true }
        } else {
            withAnimation(nil) { bright = false }
        }
    }
}

struct OnePlusAboutUpdateLine: View {
    let info: OnePlusAboutInfo
    let update: OnePlusAboutUpdate
    var suffix: String?

    var body: some View {
        HStack(spacing: A.updateGlyphGap) {
            if update.state == .current {
                Image(systemName: "checkmark.circle.fill").font(.system(size: M.caption)).foregroundStyle(C.success)
            }
            Text([info.versionLine, update.line, suffix].compactMap { $0 }.joined(separator: "  ·  "))
                .aboutText(M.caption, color: C.muted)
        }
    }
}

struct OnePlusAboutIcon: View {
    let image: NSImage
    let size: CGFloat
    let shadow: OnePlusAboutMetrics.Shadow
    @Environment(\.colorScheme) private var scheme
    init(_ image: NSImage, size: CGFloat, shadow: OnePlusAboutMetrics.Shadow = A.heroIconShadow) {
        self.image = image; self.size = size; self.shadow = shadow
    }
    var body: some View {
        Image(nsImage: image).resizable().interpolation(.high).frame(width: size, height: size)
            .shadow(color: .black.opacity(shadowOpacity), radius: shadow.radius, y: shadow.y)
            .accessibilityHidden(true)
    }
    private var shadowOpacity: Double { scheme == .light ? shadow.lightOpacity ?? shadow.opacity : shadow.opacity }
}

extension View {
    func aboutText(_ size: CGFloat, weight: Font.Weight = .regular, color: Color = C.ink) -> some View {
        font(.system(size: size, weight: weight)).foregroundStyle(color)
    }

    /// The grouped card of the license card and compare table: `fillGroup`, `line` border drawn inset.
    func aboutGroup() -> some View {
        background(C.fillGroup, in: RoundedRectangle(cornerRadius: A.groupRadius, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: A.groupRadius, style: .continuous).strokeBorder(C.line) }
    }
}
