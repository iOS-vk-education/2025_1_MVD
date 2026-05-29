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

    /// Days elapsed since startDate (0 = challenge day 1, 1 = challenge day 2, …).
    /// Can exceed 6 if the challenge has expired.
    var currentDayIndex: Int {
        let s = Calendar.current.startOfDay(for: startDate)
        let t = Calendar.current.startOfDay(for: Date())
        let days = Calendar.current.dateComponents([.day], from: s, to: t).day ?? 0
        return max(days, 0)
    }

    /// True when more than 6 days have passed since startDate.
    var isExpired: Bool {
        currentDayIndex > 6
    }

    var completedDaysCount: Int {
        progress.filter { $0 }.count
    }

    /// Whether today's sequential slot in the challenge is already marked.
    var isTodayCompleted: Bool {
        let index = currentDayIndex
        guard index < 7 else { return false }
        return progress[index]
    }
}
