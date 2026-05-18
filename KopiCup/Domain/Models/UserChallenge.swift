//
//  UserChallenge.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI

struct UserChallenge: Equatable {
    let challenge: Challenge
    var startDate: Date
    var progress: [Bool]
    
    var currentDayIndex: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return max(days, 0)
    }

    var isExpired: Bool {
        guard let week = Self.challengeWeekInterval(for: startDate) else {
            return currentDayIndex > 6
        }
        return Date() >= week.end
    }

    var completedDaysCount: Int {
        progress.filter { $0 }.count
    }

    var startWeekDayIndex: Int? {
        weekDayIndex(for: startDate)
    }

    var currentWeekDayIndex: Int? {
        weekDayIndex(for: Date())
    }
    
    var isTodayCompleted: Bool {
        guard let index = currentWeekDayIndex, progress.indices.contains(index) else { return false }
        return progress[index]
    }

    static func challengeWeekInterval(for date: Date) -> DateInterval? {
        challengeCalendar.dateInterval(of: .weekOfYear, for: date)
    }

    private func weekDayIndex(for date: Date) -> Int? {
        guard let week = Self.challengeWeekInterval(for: startDate) else { return nil }
        let calendar = Self.challengeCalendar
        let day = calendar.startOfDay(for: date)
        guard day >= week.start, day < week.end else { return nil }
        let index = calendar.dateComponents([.day], from: week.start, to: day).day ?? 0
        return (0...6).contains(index) ? index : nil
    }

    private static var challengeCalendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }
}
