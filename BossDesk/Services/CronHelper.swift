import Foundation

/// Utility for parsing and interpreting cron expressions.
/// Provides human-readable descriptions for common patterns.
enum CronHelper {

    /// Returns a human-readable description for common cron patterns.
    /// Returns nil for unknown or complex patterns.
    static func humanReadableDescription(_ cron: String) -> String? {
        let components = cron.split(separator: " ").map(String.init)
        guard components.count == 5 else { return nil }

        let minute = components[0]
        let hour = components[1]
        let dayOfMonth = components[2]
        let month = components[3]
        let dayOfWeek = components[4]

        // Every N minutes
        if minute.hasPrefix("*/"), hour == "*", dayOfMonth == "*", month == "*", dayOfWeek == "*" {
            let n = minute.dropFirst(2)
            return "Every \(n) minutes"
        }

        // Every hour
        if minute == "0", hour == "*", dayOfMonth == "*", month == "*", dayOfWeek == "*" {
            return "Every hour"
        }

        // Every N hours
        if minute == "0", hour.hasPrefix("*/"), dayOfMonth == "*", month == "*", dayOfWeek == "*" {
            let n = hour.dropFirst(2)
            return "Every \(n) hours"
        }

        // Daily at specific time
        if let hourNum = Int(hour), let minuteNum = Int(minute),
           dayOfMonth == "*", month == "*", dayOfWeek == "*" {
            let time = String(format: "%02d:%02d", hourNum, minuteNum)
            return "Daily at \(time)"
        }

        // Weekly on specific day
        if let dayNum = Int(dayOfWeek), dayNum >= 0, dayNum <= 7,
           let hourNum = Int(hour), let minuteNum = Int(minute),
           dayOfMonth == "*", month == "*" {
            // Normalize: cron allows Sunday as 0 or 7
            let normalizedDay = dayNum == 7 ? 0 : dayNum
            let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            let time = String(format: "%02d:%02d", hourNum, minuteNum)
            return "Weekly on \(days[normalizedDay]) at \(time)"
        }

        // Monthly on specific day
        if let dayNum = Int(dayOfMonth), dayNum >= 1, dayNum <= 31,
           let hourNum = Int(hour), let minuteNum = Int(minute),
           month == "*", dayOfWeek == "*" {
            let time = String(format: "%02d:%02d", hourNum, minuteNum)
            let suffix = daySuffix(dayNum)
            return "Monthly on the \(dayNum)\(suffix) at \(time)"
        }

        return nil
    }

    /// Estimates the next run time for simple cron patterns.
    /// Returns nil for complex patterns that require advanced parsing.
    static func estimateNextRun(_ cron: String, timezone: String?) -> Date? {
        let components = cron.split(separator: " ").map(String.init)
        guard components.count == 5 else { return nil }

        let minute = components[0]
        let hour = components[1]
        let dayOfMonth = components[2]
        let month = components[3]
        let dayOfWeek = components[4]

        let timeZone = TimeZone(identifier: timezone ?? "UTC") ?? .current
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        let now = Date()
        var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)

        // Handle every N minutes pattern
        if minute.hasPrefix("*/"), hour == "*", dayOfMonth == "*", month == "*", dayOfWeek == "*" {
            if let interval = Int(minute.dropFirst(2)), interval > 0 {
                let currentMinute = dateComponents.minute ?? 0
                let nextMinute = ((currentMinute / interval) + 1) * interval

                if nextMinute >= 60 {
                    // No valid minute left in current hour, move to next hour at minute 0
                    // Cron step values reset at each hour boundary
                    dateComponents.minute = 0
                    if let baseDate = calendar.date(from: dateComponents) {
                        return calendar.date(byAdding: .hour, value: 1, to: baseDate)
                    }
                } else {
                    // Next valid minute is in the current hour
                    dateComponents.minute = nextMinute
                    return calendar.date(from: dateComponents)
                }
            }
        }

        // Handle hourly pattern (0 * * * *)
        if minute == "0", hour == "*", dayOfMonth == "*", month == "*", dayOfWeek == "*" {
            dateComponents.minute = 0
            if let baseDate = calendar.date(from: dateComponents) {
                // Add 1 hour, handles day rollover automatically
                return calendar.date(byAdding: .hour, value: 1, to: baseDate)
            }
        }

        // Handle every N hours pattern (0 */N * * *)
        if minute == "0", hour.hasPrefix("*/"), dayOfMonth == "*", month == "*", dayOfWeek == "*" {
            if let interval = Int(hour.dropFirst(2)), interval > 0, interval <= 24 {
                let currentHour = dateComponents.hour ?? 0

                // Calculate next valid hour in step sequence
                // Cron */N resets at midnight (0, N, 2N, 3N, ...)
                let nextHour = ((currentHour / interval) + 1) * interval

                if nextHour >= 24 {
                    // Next run is tomorrow at hour 0
                    dateComponents.hour = 0
                    dateComponents.minute = 0
                    if let baseDate = calendar.date(from: dateComponents) {
                        return calendar.date(byAdding: .day, value: 1, to: baseDate)
                    }
                } else {
                    // Next run is today at calculated hour
                    dateComponents.hour = nextHour
                    dateComponents.minute = 0
                    return calendar.date(from: dateComponents)
                }
            }
        }

        // Handle daily at specific time
        if let hourNum = Int(hour), let minuteNum = Int(minute), dayOfMonth == "*", month == "*", dayOfWeek == "*" {
            dateComponents.hour = hourNum
            dateComponents.minute = minuteNum

            if let candidateDate = calendar.date(from: dateComponents), candidateDate > now {
                return candidateDate
            } else {
                // Move to next day using proper date arithmetic
                if let baseDate = calendar.date(from: dateComponents) {
                    return calendar.date(byAdding: .day, value: 1, to: baseDate)
                }
            }
        }

        // Handle weekly pattern (M H * * D)
        if let dayNum = Int(dayOfWeek), dayNum >= 0, dayNum <= 7,
           let hourNum = Int(hour), let minuteNum = Int(minute),
           dayOfMonth == "*", month == "*" {

            // Normalize: cron allows Sunday as 0 or 7
            let normalizedDay = dayNum == 7 ? 0 : dayNum

            dateComponents.hour = hourNum
            dateComponents.minute = minuteNum

            // Calculate next occurrence of target weekday
            let currentWeekday = calendar.component(.weekday, from: now) // 1=Sunday
            let targetWeekday = normalizedDay == 0 ? 1 : (normalizedDay + 1) // Cron: 0=Sunday, Calendar: 1=Sunday

            var daysToAdd = targetWeekday - currentWeekday

            // If target day is today, check if time has passed
            if daysToAdd == 0 {
                if let candidateDate = calendar.date(from: dateComponents),
                   candidateDate > now {
                    return candidateDate // Today, future time
                }
                daysToAdd = 7 // Today but past time, next week
            } else if daysToAdd < 0 {
                daysToAdd += 7 // Target is earlier in week, go to next week
            }

            if let baseDate = calendar.date(from: dateComponents) {
                return calendar.date(byAdding: .day, value: daysToAdd, to: baseDate)
            }
        }

        // Handle monthly pattern (M H D * *)
        if let dayNum = Int(dayOfMonth), dayNum >= 1, dayNum <= 31,
           let hourNum = Int(hour), let minuteNum = Int(minute),
           month == "*", dayOfWeek == "*" {

            dateComponents.hour = hourNum
            dateComponents.minute = minuteNum
            dateComponents.day = dayNum

            // Try current month first
            if let candidateDate = calendar.date(from: dateComponents),
               candidateDate > now {
                return candidateDate
            }

            // Current month's date has passed or doesn't exist (e.g., Feb 31)
            // Advance to next month
            if let baseDate = calendar.date(from: dateComponents) {
                return calendar.date(byAdding: .month, value: 1, to: baseDate)
            }

            // Fallback: If date construction failed (invalid day), try next month
            var nextMonthComponents = calendar.dateComponents([.year, .month], from: now)
            nextMonthComponents.month = (nextMonthComponents.month ?? 1) + 1
            nextMonthComponents.day = dayNum
            nextMonthComponents.hour = hourNum
            nextMonthComponents.minute = minuteNum

            return calendar.date(from: nextMonthComponents)
        }

        return nil
    }

    private static func daySuffix(_ day: Int) -> String {
        switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }
}
