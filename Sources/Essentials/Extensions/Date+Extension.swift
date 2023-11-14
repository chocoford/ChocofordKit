//
//  File.swift
//  
//
//  Created by Chocoford on 2023/4/29.
//

import Foundation

public extension Date {
    enum SpanUnit: String, CaseIterable {
        case second
        case minute
        case hour
        case day
        case week
//        case month
        case year
        
        var interval: TimeInterval {
            switch self {
                case .second:
                    return TimeInterval(1)
                case .minute:
                    return SpanUnit.second.interval * 60
                case .hour:
                    return SpanUnit.minute.interval * 60
                case .day:
                    return SpanUnit.hour.interval * 24
                case .week:
                    return SpanUnit.day.interval * 7
                case .year:
                    return SpanUnit.day.interval * 365
//                case .month:
//                    return SpanUnit.week.interval
            }
        }
    }
    
    /// Get the relative formatted of `Date`
    /// - Parameters:
    ///   - units: The relative units allowed,
    ///   - maxRelative: if exceed the `maxRelative`, the absolute formatted will be displayed
    ///   - extensionOutput:
    ///   - fallbackFormat:
    /// - Returns: a date `String` representation
    func relativeFormatted(units: [SpanUnit] = SpanUnit.allCases,
                           maxRelative: SpanUnit = .year,
                           extensionOutput: (SpanUnit, _ value: Int) -> String = { unit, value in
        " \(unit.rawValue)\(value > 1 ? "s" : "") ago"
    },
                           fallbackFormat: () -> String = { "yyyy MMM dd" }) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = fallbackFormat() //"MMM dd"

        let now = Date()
        let timeDiff = now.timeIntervalSince(self)
        
        var result: String = "just now"

        for unit in units {
            let value = timeDiff / unit.interval
            if value <= 1 {
                return result
            } else if value > 1 && timeDiff <= maxRelative.interval {
                result = "\(Int(value))\(extensionOutput(unit, Int(value)))"
            } else {
                return formatter.string(from: self)
            }
        }
        
        return formatter.string(from: self)
    }
    
    
    /// Past days seperated by 00:00
    static func pastDays(duration: Int = 7) -> [Date] {
        let calendar = Calendar.current
        var today = calendar.date(byAdding: .day, value: -1 * duration, to: Date())!
        let dateEnding: Date = .now

        var matchingDates = [Date]()
        // Finding matching dates at midnight - adjust as needed
        let components = DateComponents(hour: 0, minute: 0, second: 0) // midnight
        var days: [Date] = []
        calendar.enumerateDates(startingAfter: today,
                                matching: components,
                                matchingPolicy: .nextTime) { (date, strict, stop) in
            if let date = date {
                if date <= dateEnding {
                    days.append(date)
                } else {
                    stop = true
                }
            }
        }
        
        return days
    }
}


