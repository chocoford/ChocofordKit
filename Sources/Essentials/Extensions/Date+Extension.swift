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
    
    func relativeFormatted(units: [SpanUnit] = SpanUnit.allCases,
                           maxRelative: SpanUnit = .year,
                           extensionOutput: (SpanUnit, _ value: Int) -> String = { unit, value in
        " \(unit.rawValue)\(value > 1 ? "s" : "") ago"
    },
                           fallbackFormat: () -> String = { "yyyy MMM dd" }) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        
        let now = Date()
        let timeDiff = now.timeIntervalSince(self)
        
        var result: String = "just now"

        for unit in units {
            let value = timeDiff / unit.interval
            if value > 1 && timeDiff <= maxRelative.interval {
                result = "\(Int(value))\(extensionOutput(unit, Int(value)))"
            } else {
                return result
            }
        }
        
        formatter.dateFormat = fallbackFormat() //"MMM dd"
        return formatter.string(from: self)
//        if Calendar.current.isDate(self, equalTo: now, toGranularity: .year) {
//            return dateString
//        } else {
//            formatter.dateFormat = "yyyy MMM dd"
//            let dateStringWithYear = formatter.string(from: self)
//            return dateStringWithYear
//        }
    }
}
