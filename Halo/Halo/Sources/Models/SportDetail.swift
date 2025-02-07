struct SportDetail {
    let date: Date
    let calories: Int
    let steps: Int
    let distance: Int // Meters
    
    init(year: Int, month: Int, day: Int, timeIndex: Int, calories: Int, steps: Int, distance: Int) {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = timeIndex / 4
        components.minute = (timeIndex % 4) * 15
        
        self.date = calendar.date(from: components) ?? Date()
        self.calories = calories
        self.steps = steps
        self.distance = distance
    }
}

struct StepLog {
    let date: Date
    let details: [SportDetail]
    let totalSteps: Int
    
    static let empty = StepLog(date: Date(), details: [], totalSteps: 0)
}

fileprivate func bcdToDecimal(_ bcd: UInt8) -> Int {
    return ((Int(bcd) >> 4) * 10) + (Int(bcd) & 0x0F)
}
