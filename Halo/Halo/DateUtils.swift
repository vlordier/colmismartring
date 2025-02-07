//
//  DateUtils.swift
//  Halo
//
//  Created by Yannis De Cleene on 27/01/2025.
//

import Foundation

/// Returns the start of the day (midnight 00:00:00) for a given date
///
/// This function strips the time component from a date, returning just
/// the calendar date at midnight. Useful for aligning timestamps with
/// daily boundaries.
///
/// - Parameter date: The date to get the start of day for
/// - Returns: Date object set to midnight (00:00:00) of the given date, or nil if calculation fails
func startOfDay(for date: Date) -> Date? {
    let calendar = Calendar.current
    return calendar.startOfDay(for: date)
}

/// Returns the end of the day (23:59:59) for a given date
///
/// This function calculates the last second of the given date,
/// useful for range queries that should include the entire day.
///
/// - Parameter date: The date to get the end of day for
/// - Returns: Date object set to the last second (23:59:59) of the given date, or nil if calculation fails
func endOfDay(for date: Date) -> Date? {
    guard let start = startOfDay(for: date) else { return nil }
    let calendar = Calendar.current
    return calendar.date(byAdding: DateComponents(day: 1, second: -1), to: start)
}

/// Returns an array of dates between two dates (inclusive)
///
/// This function generates a sequence of dates, one for each day between
/// the start and end dates. Each date is set to midnight (00:00:00).
///
/// - Parameters:
///   - start: The starting date of the range
///   - end: The ending date of the range
/// - Returns: Array of dates, one for each day in the range
/// - Throws: NSError if start date is after end date
func datesBetween(start: Date, end: Date) throws -> [Date] {
    guard start <= end else {
        throw NSError(domain: "InvalidRange", code: 1, userInfo: [NSLocalizedDescriptionKey: "Start date is after end date"])
    }
    
    var dates: [Date] = []
    let calendar = Calendar.current
    var current = startOfDay(for: start)!
    
    while current <= end {
        dates.append(current)
        guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
        current = next
    }
    
    return dates
}

/// Returns the current date and time
///
/// Wrapper around Date() initializer for consistency with other date utilities
/// and potential future timestamp standardization.
///
/// - Returns: Current date and time as Date object
func now() -> Date {
    return Date()
}

/// Calculates the number of minutes elapsed since midnight for a given date
///
/// This function is useful for calculating time-based indices or positions
/// within a day, such as for heart rate measurements taken at regular intervals.
///
/// - Parameter date: The date to calculate elapsed minutes for
/// - Returns: Number of minutes since midnight plus 1 (to match legacy behavior),
///           or nil if start of day cannot be calculated
func minutesSoFar(on date: Date) -> Int? {
    let calendar = Calendar.current
    guard let startOfDay = startOfDay(for: date) else { return nil }
    let elapsed = date.timeIntervalSince(startOfDay)
    return Int(elapsed / 60) + 1 // Adding 1 to match the Python behavior
}

/// Checks if a given date falls on the current calendar day
///
/// This function compares the calendar day components of the given date
/// with today's date, ignoring time components.
///
/// - Parameter date: The date to check
/// - Returns: true if the date is today, false otherwise
func isToday(date: Date) -> Bool {
    let calendar = Calendar.current
    return calendar.isDateInToday(date)
}
