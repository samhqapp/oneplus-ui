import SwiftUI

public struct OnePlusSparkline: View {
    private let values: [Double]
    private let range: ClosedRange<Double>
    private let color: Color
    public init(values: [Double], range: ClosedRange<Double> = 0...100, color: Color = OnePlusColor.chartLine) {
        self.values = values; self.range = range; self.color = color
    }
    public var body: some View { OnePlusPlot(values: values, range: range, color: color, area: false) }
}

public struct OnePlusAreaChart: View {
    private let values: [Double]
    private let range: ClosedRange<Double>
    private let color: Color
    private let quietBackground: Bool
    public init(values: [Double], range: ClosedRange<Double> = 0...100, color: Color = OnePlusColor.chartLine,
                quietBackground: Bool = false) {
        self.values = values; self.range = range; self.color = color; self.quietBackground = quietBackground
    }
    public var body: some View { OnePlusPlot(values: values, range: range, color: color, area: true, quietBackground: quietBackground) }
}

private struct OnePlusPlot: View {
    @Environment(\.colorScheme) private var colorScheme
    let values: [Double]
    let range: ClosedRange<Double>
    let color: Color
    let area: Bool
    var quietBackground = false
    var body: some View {
        let paths = OnePlusChartPaths.cached(values: values, range: range, smoothed: quietBackground)
        Canvas { context, size in
            let width = size.width.isFinite ? max(0, size.width) : 0
            let height = size.height.isFinite ? max(0, size.height) : 0
            let transform = CGAffineTransform(scaleX: width, y: max(0, height - 2))
            let line = paths.line.applying(transform)
            if area && quietBackground {
                context.fill(paths.area.applying(transform), with: .color(color.opacity(0.07)))
            } else if area {
                for y in [CGFloat(0), 0.5, 1] {
                    var grid = Path()
                    grid.move(to: CGPoint(x: 0, y: y * height))
                    grid.addLine(to: CGPoint(x: width, y: y * height))
                    context.stroke(grid, with: .color(OnePlusColor.chartGrid), lineWidth: 1)
                }
                if let clip = OnePlusChartPattern.clip(paths.area.applying(transform)) { context.withCGContext { cg in
                    cg.saveGState()
                    cg.addPath(clip.cgPath)
                    cg.clip()
                    cg.beginTransparencyLayer(auxiliaryInfo: nil)
                    cg.setFillColorSpace(CGColorSpace(patternBaseSpace: CGColorSpaceCreateDeviceRGB())!)
                    let gray: CGFloat = colorScheme == .dark ? 1 : 0
                    var components: [CGFloat] = [gray, gray, gray, 1]
                    cg.setFillPattern(OnePlusChartPattern.pattern, colorComponents: &components)
                    cg.fill(CGRect(x: 0, y: 0, width: width, height: height))
                    cg.setBlendMode(.destinationIn)
                    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                              colors: [CGColor(gray: 0, alpha: 0.63), CGColor(gray: 0, alpha: 0.06)] as CFArray,
                                              locations: [0, 1])!
                    cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: height), options: [])
                    cg.endTransparencyLayer()
                    cg.restoreGState()
                } }
            }
            context.stroke(line, with: .color(color.opacity(quietBackground ? 0.35 : 1)),
                           style: StrokeStyle(lineWidth: quietBackground ? 1 : 1.2, lineCap: .round, lineJoin: .round))
        }
        .clipped().accessibilityElement(children: .ignore)
        .accessibilityLabel(values.last.flatMap { $0.isFinite ? "Latest value \($0.formatted())" : nil } ?? "No history")
    }
}

@MainActor
final class OnePlusChartPaths {
    let line: Path
    let area: Path
    private let values: [Double]
    private let range: ClosedRange<Double>
    private let smoothed: Bool
    private let slots: Int
    private static let cache: NSCache<NSNumber, OnePlusChartPaths> = {
        let cache = NSCache<NSNumber, OnePlusChartPaths>(); cache.countLimit = 128; return cache
    }()
    // A hash key avoids formatting the whole series into a string on every body pass; equality guards collisions.
    static func cached(values: [Double], range: ClosedRange<Double>, smoothed: Bool = false, slots: Int = 0) -> OnePlusChartPaths {
        var hasher = Hasher()
        hasher.combine(values); hasher.combine(range.lowerBound); hasher.combine(range.upperBound)
        hasher.combine(smoothed); hasher.combine(slots)
        let key = NSNumber(value: hasher.finalize())
        if let result = cache.object(forKey: key), result.smoothed == smoothed, result.slots == slots, result.range == range,
           result.values == values { return result }
        let result = OnePlusChartPaths(values: values, range: range, smoothed: smoothed, slots: slots)
        cache.setObject(result, forKey: key)
        return result
    }
    /// `slots` fixes the x step to a full window, right-aligned, so a short history never stretches.
    /// `smoothed` draws a monotone cubic through the points: no overshoot past a sample, flat runs stay flat.
    init(values: [Double], range: ClosedRange<Double>, smoothed: Bool = false, slots: Int = 0) {
        self.values = values; self.range = range; self.smoothed = smoothed; self.slots = slots
        let lower = range.lowerBound.isFinite ? range.lowerBound : 0
        let upper = range.upperBound.isFinite ? range.upperBound : 100
        let scale = max(lower.magnitude, upper.magnitude, 1)
        let scaledLower = lower / scale
        let scaledSpan = max(upper / scale - scaledLower, 0.001)
        let count = max(values.count, slots)
        let offset = count - values.count
        var runs: [[CGPoint]] = [[]]
        for (index, value) in values.enumerated() {
            guard value.isFinite else { if !runs[runs.count - 1].isEmpty { runs.append([]) }; continue }
            let x = count == 1 ? 0 : Double(index + offset) / Double(count - 1)
            let fraction = min(max((value / scale - scaledLower) / scaledSpan, 0), 1)
            runs[runs.count - 1].append(CGPoint(x: x, y: 1 - (fraction.isFinite ? fraction : 0)))
        }
        var line = Path()
        var area = Path()
        for run in runs where !run.isEmpty {
            var points = run
            if count == 1 { points.append(CGPoint(x: 1, y: run[0].y)) }
            line.move(to: points[0])
            area.move(to: CGPoint(x: points[0].x, y: 1))
            area.addLine(to: points[0])
            let tangents = smoothed ? Self.monotoneTangents(points) : []
            for index in 1..<max(points.count, 1) {
                let from = points[index - 1], to = points[index]
                if smoothed {
                    let third = (to.x - from.x) / 3
                    let control1 = CGPoint(x: from.x + third, y: from.y + third * tangents[index - 1])
                    let control2 = CGPoint(x: to.x - third, y: to.y - third * tangents[index])
                    line.addCurve(to: to, control1: control1, control2: control2)
                    area.addCurve(to: to, control1: control1, control2: control2)
                } else {
                    line.addLine(to: to)
                    area.addLine(to: to)
                }
            }
            area.addLine(to: CGPoint(x: points[points.count - 1].x, y: 1)); area.closeSubpath()
        }
        self.line = line; self.area = area
    }

    /// Steffen's monotone tangents (as in d3 `curveMonotoneX`): zero at a peak or valley and at most three
    /// times the smaller neighbor slope, so the curve never leaves the band between two samples.
    static func monotoneTangents(_ points: [CGPoint]) -> [CGFloat] {
        guard points.count > 1 else { return [0] }
        let slopes = (1..<points.count).map { index in
            let width = points[index].x - points[index - 1].x
            return width > 0 ? (points[index].y - points[index - 1].y) / width : 0
        }
        var tangents = [CGFloat](repeating: 0, count: points.count)
        for index in 1..<(points.count - 1) {
            let left = slopes[index - 1], right = slopes[index]
            guard left * right > 0 else { continue }
            let h0 = points[index].x - points[index - 1].x, h1 = points[index + 1].x - points[index].x
            let blend = (left * h1 + right * h0) / (h0 + h1)
            tangents[index] = (left > 0 ? 2 : -2) * min(abs(left), abs(right), abs(blend) / 2)
        }
        let last = points.count - 1
        tangents[0] = endTangent(slopes[0], neighbor: last > 1 ? tangents[1] : slopes[0])
        tangents[last] = endTangent(slopes[last - 1], neighbor: last > 1 ? tangents[last - 1] : slopes[last - 1])
        return tangents
    }

    private static func endTangent(_ slope: CGFloat, neighbor: CGFloat) -> CGFloat {
        let tangent = (3 * slope - neighbor) / 2
        guard tangent * slope > 0 else { return 0 }
        return abs(tangent) > 3 * abs(slope) ? 3 * slope : tangent
    }
}

/// Calm live charts: light sample smoothing and a y scale that steps up at once but settles down slowly.
/// Text values stay the raw current reading; only the drawn series uses these.
public enum OnePlusChartSmoothing {
    /// An exponential moving average. Run it over the full history, then take the visible window, so the
    /// visible points never change once drawn. A missing sample passes through and restarts the average.
    public static func eased(_ values: [Double], weight: Double = 0.5) -> [Double] {
        var last: Double?
        return values.map { value in
            guard value.isFinite else { last = nil; return value }
            let next = last.map { $0 + (value - $0) * weight } ?? value
            last = next
            return next
        }
    }

    /// The chart top: the next 1, 2, 2.5, or 5 step above `peak` times `headroom`, at least `minimum` and at most
    /// `maximum`. A higher peak raises it at once (nothing clips); a lower one lets it fall 20% of the gap per
    /// sample, so the line never jumps when a spike leaves the window.
    public static func ceiling(peak: Double, previous: Double?, minimum: Double, maximum: Double = .infinity,
                               headroom: Double = 1.25) -> Double {
        let peak = peak.isFinite ? max(peak, 0) : 0
        let target = min(maximum, niceStep(max(minimum, peak * headroom)))
        guard let previous, previous.isFinite, previous > 0, target < previous else { return target }
        let eased = max(previous - (previous - target) * 0.2, peak)
        return eased - target < target * 0.02 ? target : eased
    }

    static func niceStep(_ value: Double) -> Double {
        guard value.isFinite, value > 0 else { return 1 }
        let base = pow(10, floor(log10(value)))
        return [1, 2, 2.5, 5, 10].map { $0 * base }.first { $0 >= value * 0.999_999 } ?? 10 * base
    }
}

public struct OnePlusUsageBar: View {
    let value: Double
    let color: Color
    public init(value: Double, color: Color = OnePlusColor.chartSeries[0]) { self.value = value; self.color = color }
    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width.isFinite ? max(0, proxy.size.width) : 0
            let fraction = value.isFinite ? min(max(value, 0), 1) : 0
            Capsule().fill(OnePlusColor.line)
                .overlay(alignment: .leading) { Capsule().fill(color).frame(width: width * fraction) }
        }.frame(height: 5)
            .accessibilityElement(children: .ignore).accessibilityLabel("Usage")
            .accessibilityValue(value.isFinite ? "\(Int(min(max(value, 0), 1) * 100)) percent" : "Unavailable")
    }
}

public struct OnePlusSegmentBar: View {
    private let values: [Double]
    private let colors: [Color]
    public init(values: [Double], colors: [Color] = OnePlusColor.chartSeries) { self.values = values; self.colors = colors }
    public var body: some View {
        GeometryReader { proxy in
            let usable = values.map { $0.isFinite ? max(0, $0) : 0 }
            let largest = usable.max() ?? 0
            let weights = largest > 0 ? usable.map { $0 / largest } : usable
            let total = weights.reduce(0, +)
            let count = usable.filter { $0 > 0 }.count
            let available = proxy.size.width.isFinite ? max(0, proxy.size.width) : 0
            let width = max(0, available - CGFloat(max(0, count - 1)) * 2)
            HStack(spacing: 2) {
                ForEach(usable.indices, id: \.self) { index in
                    if usable[index] > 0, total > 0 {
                        Capsule().fill(colors.isEmpty ? OnePlusColor.chartLine : colors[index % colors.count])
                            .frame(width: width * weights[index] / total)
                    }
                }
            }.frame(maxWidth: .infinity, alignment: .leading).background(OnePlusColor.line, in: Capsule())
        }.frame(height: 5).accessibilityElement(children: .ignore)
            .accessibilityLabel("Usage by category").accessibilityValue(values.map { $0.formatted() }.joined(separator: ", "))
    }
}
