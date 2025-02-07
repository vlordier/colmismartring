//
//  DateUtilsTests.swift
//  HaloTests
//

@testable import Halo
import XCTest

final class DateUtilsTests: XCTestCase {
    func testStartOfDay() {
        // Given
        let date = Date(timeIntervalSince1970: 1_706_400_000) // Some arbitrary date

        // When
        let startOfDay = startOfDay(for: date)

        // Then
        XCTAssertNotNil(startOfDay)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: startOfDay!)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testEndOfDay() {
        // Given
        let date = Date(timeIntervalSince1970: 1_706_400_000)

        // When
        let endOfDay = endOfDay(for: date)

        // Then
        XCTAssertNotNil(endOfDay)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: endOfDay!)
        XCTAssertEqual(components.hour, 23)
        XCTAssertEqual(components.minute, 59)
        XCTAssertEqual(components.second, 59)
    }

    func testDatesBetween() throws {
        // Given
        let start = Date(timeIntervalSince1970: 1_706_400_000)
        let end = Calendar.current.date(byAdding: .day, value: 2, to: start)!

        // When
        let dates = try datesBetween(start: start, end: end)

        // Then
        XCTAssertEqual(dates.count, 3)
        XCTAssertEqual(Calendar.current.isDate(dates[0], inSameDayAs: start), true)
        XCTAssertEqual(Calendar.current.isDate(dates[2], inSameDayAs: end), true)
    }

    func testDatesBetweenInvalidRange() {
        // Given
        let start = Date(timeIntervalSince1970: 1_706_400_000)
        let end = Calendar.current.date(byAdding: .day, value: -1, to: start)!

        // Then
        XCTAssertThrowsError(try datesBetween(start: start, end: end))
    }
}
