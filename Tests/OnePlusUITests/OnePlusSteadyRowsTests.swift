import XCTest
@testable import OnePlusUI

final class OnePlusSteadyRowsTests: XCTestCase {
    func testGrowsAtOnceAndShrinksOnlyTwoBelowTheReservedRows() {
        var rows = OnePlusSteadyRows(count: 1)
        XCTAssertEqual(rows.reserved, 3)
        rows.update(count: 5)
        XCTAssertEqual(rows.reserved, 5)
        rows.update(count: 4)
        XCTAssertEqual(rows.reserved, 5)
        rows.update(count: 3)
        XCTAssertEqual(rows.reserved, 3)
        rows.update(count: 1)
        XCTAssertEqual(rows.reserved, 3)
        rows.update(count: 0)
        XCTAssertEqual(rows.reserved, 3)
        rows.update(count: 4)
        XCTAssertEqual(rows.reserved, 4)
        rows.update(count: 2)
        XCTAssertEqual(rows.reserved, 3)
    }
}
