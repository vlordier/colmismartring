import Foundation

/// Represents detailed sports activity data for a specific time period
struct SportDetail {
    /// The date and time of the activity record
    let date: Date
    
    /// Total calories burned during this period
    let calories: Int
    
    /// Number of steps taken during this period
    let steps: Int
    
    /// Distance covered in meters during this period
    let distance: Int

    init(year: Int, month: Int, day: Int, timeIndex: Int, calories: Int, steps: Int, distance: Int) {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = timeIndex / 4
        components.minute = (timeIndex % 4) * 15

        date = calendar.date(from: components) ?? Date()
        self.calories = calories
        self.steps = steps
        self.distance = distance
    }
}

/// Represents an aggregated log of step data for a specific date
struct StepLog {
    /// The date this log corresponds to
    let date: Date
    
    /// Array of detailed sport records throughout the day
    let details: [SportDetail]
    
    /// Total step count for the entire day
    let totalSteps: Int

    /// Empty log instance for initialization
    static let empty = StepLog(date: Date(), details: [], totalSteps: 0)
}

/// Converts a Binary Coded Decimal (BCD) byte to its decimal representation
/// 
/// - Parameter bcd: The BCD encoded byte to convert
/// - Returns: The decimal integer value
private func bcdToDecimal(_ bcd: UInt8) -> Int {
    ((Int(bcd) >> 4) * 10) + (Int(bcd) & 0x0F)
}
