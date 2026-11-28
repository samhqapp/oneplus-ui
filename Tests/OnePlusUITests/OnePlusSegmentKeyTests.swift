import XCTest
@testable import OnePlusUI

/// The segmented key look (owner pick 2026-11-28): a round seam in the middle of a track was the bug.
final class OnePlusSegmentKeyTests: XCTestCase {
    func testKeyIsConcentricWithItsTrack() {
        XCTAssertEqual(OnePlusSegmentKey.radius(track: 6, inset: 2), 4, "24 pt applet control")
        XCTAssertEqual(OnePlusSegmentKey.radius(track: 7, inset: 2), 5, "28 pt main window control")
        XCTAssertEqual(OnePlusSegmentKey.radius(track: 1, inset: 2), 0, "never a negative radius")
        XCTAssertEqual(OnePlusMetrics.segmentRadius, OnePlusSegmentKey.radius(track: 6, inset: 2), "old OnePlusSegmented")
        for look in [OnePlusLinearControlLook.quietRaised, .raisedKeys] {
            let well = OnePlusLinearWell(look)
            XCTAssertEqual(well.innerRadius, look.radius - OnePlusLinearWell.inset)
            XCTAssertEqual(well.innerHeight, look.height - 2 * OnePlusLinearWell.inset, "key inset 2 pt on every side")
        }
    }

    func testDividerIsShortAndHidesBesideTheKeyAndHover() {
        XCTAssertEqual(OnePlusSegmentKey.dividerHeight(inner: 20), 12)
        XCTAssertFalse(OnePlusSegmentKey.showsDivider(before: 0, selected: nil, hovered: nil), "no line before the first segment")
        // Three segments, middle picked: both lines touch the key.
        XCTAssertFalse(OnePlusSegmentKey.showsDivider(before: 1, selected: 1, hovered: nil))
        XCTAssertFalse(OnePlusSegmentKey.showsDivider(before: 2, selected: 1, hovered: nil))
        // First picked: only the far line shows, until its neighbor is hovered.
        XCTAssertFalse(OnePlusSegmentKey.showsDivider(before: 1, selected: 0, hovered: nil))
        XCTAssertTrue(OnePlusSegmentKey.showsDivider(before: 2, selected: 0, hovered: nil))
        XCTAssertFalse(OnePlusSegmentKey.showsDivider(before: 2, selected: 0, hovered: 2))
    }

    func testMiddleSegmentHoverIsLessRoundThanTheEdges() {
        let outer = OnePlusLinearWell(.raisedKeys).innerRadius
        let first = OnePlusSegmentKey.hoverCorners(index: 0, count: 3, outer: outer)
        let middle = OnePlusSegmentKey.hoverCorners(index: 1, count: 3, outer: outer)
        let last = OnePlusSegmentKey.hoverCorners(index: 2, count: 3, outer: outer)
        XCTAssertEqual(first.topLeading, outer, "the first segment's outer side follows the key radius")
        XCTAssertEqual(last.bottomTrailing, outer, "the last segment's outer side follows the key radius")
        for corner in [first.topTrailing, middle.topLeading, middle.bottomTrailing, last.bottomLeading] {
            XCTAssertLessThan(corner, outer, "a side that faces another segment stays small: use OnePlusSegmentKey.hoverCorners")
        }
        let only = OnePlusSegmentKey.hoverCorners(index: 0, count: 1, outer: outer)
        XCTAssertEqual(only.topLeading, outer); XCTAssertEqual(only.topTrailing, outer)
    }
}
