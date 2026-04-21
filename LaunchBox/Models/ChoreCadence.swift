//
//  ChoreCadence.swift
//  LaunchBox
//

import Foundation

/// Cadence for when a chore comes due again (stored as JSON on `Chore`).
struct ChoreCadence: Codable, Equatable, Sendable {
    enum Mode: String, Codable, Sendable {
        case daily
        case weekly
        case everyNDays
    }

    var mode: Mode
    /// `Calendar` weekday: 1 = Sunday … 7 = Saturday
    var weekday: Int?
    /// For `everyNDays`, minimum 1
    var intervalDays: Int?

    static let dailyDefault = ChoreCadence(mode: .daily, weekday: nil, intervalDays: nil)

    static func weekly(weekday: Int) -> ChoreCadence {
        ChoreCadence(mode: .weekly, weekday: weekday, intervalDays: nil)
    }

    static func every(days: Int) -> ChoreCadence {
        ChoreCadence(mode: .everyNDays, weekday: nil, intervalDays: max(1, days))
    }

    func encodedJSON() throws -> String {
        let data = try JSONEncoder().encode(self)
        guard let s = String(data: data, encoding: .utf8) else {
            throw CadenceError.encodingFailed
        }
        return s
    }

    static func decode(json: String) throws -> ChoreCadence {
        guard let data = json.data(using: .utf8) else { throw CadenceError.decodingFailed }
        return try JSONDecoder().decode(ChoreCadence.self, from: data)
    }

    enum CadenceError: Error {
        case encodingFailed
        case decodingFailed
    }
}

enum ChoreDueDateCalculator {
    /// Next time this chore should be done, based on last completion (or creation if never done).
    static func nextDueDate(
        lastCompletedAt: Date?,
        createdAt: Date,
        cadence: ChoreCadence,
        calendar: Calendar = .current
    ) -> Date {
        let anchor = lastCompletedAt ?? createdAt.addingTimeInterval(-60)

        switch cadence.mode {
        case .daily:
            let start = calendar.startOfDay(for: anchor)
            return calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)

        case .weekly:
            let wd = cadence.weekday ?? 1
            return nextWeekday(after: anchor, weekday: wd, calendar: calendar)

        case .everyNDays:
            let n = max(1, cadence.intervalDays ?? 1)
            let start = calendar.startOfDay(for: anchor)
            return calendar.date(byAdding: .day, value: n, to: start) ?? start.addingTimeInterval(Double(n) * 86_400)
        }
    }

    private static func nextWeekday(after date: Date, weekday: Int, calendar: Calendar) -> Date {
        var c = calendar
        c.locale = Locale.current
        let target = min(max(weekday, 1), 7)
        var d = calendar.startOfDay(for: date)
        if let next = calendar.nextDate(
            after: d.addingTimeInterval(-1),
            matching: DateComponents(weekday: target),
            matchingPolicy: .nextTime,
            direction: .forward
        ) {
            return next
        }
        return d.addingTimeInterval(86_400 * 7)
    }

    static func isDueTodayOrOverdue(
        lastCompletedAt: Date?,
        createdAt: Date,
        cadence: ChoreCadence,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> Bool {
        let next = nextDueDate(
            lastCompletedAt: lastCompletedAt,
            createdAt: createdAt,
            cadence: cadence,
            calendar: calendar
        )
        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
        return next <= endOfToday
    }

    static func isUpcomingWithinDays(
        lastCompletedAt: Date?,
        createdAt: Date,
        cadence: ChoreCadence,
        days: Int = 7,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> Bool {
        guard
            !isDueTodayOrOverdue(
                lastCompletedAt: lastCompletedAt,
                createdAt: createdAt,
                cadence: cadence,
                calendar: calendar,
                now: now
            )
        else { return false }
        let next = nextDueDate(
            lastCompletedAt: lastCompletedAt,
            createdAt: createdAt,
            cadence: cadence,
            calendar: calendar
        )
        guard let horizon = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: now)) else {
            return false
        }
        return next <= horizon
    }
}
