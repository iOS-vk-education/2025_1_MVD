import Foundation

struct StatsMetrics {
    let discipline: Double
    let planning: Double
    let friendship: Double
    let activity: Double
    let consistency: Double

    var radarValues: [Double] {
        [discipline, planning, friendship, activity, consistency]
    }
}

final class StatsService {
    private let dailyAmountStore = DailyAmountStore.shared
    private let appActivityStore = AppActivityStore.shared
    private let challengeStore = LocalChallengeStore.shared
    private let calendar = Calendar.current

    func loadMetrics(uid: String) async -> StatsMetrics {
        let amounts = await fetchLast30DaysAmounts(uid: uid)
        let activeDays = await fetchLast30ActiveDays(uid: uid)

        let discipline = calculateDisciplineScore(from: amounts)
        let planning = calculatePlanningScore(from: amounts)
        let activity = calculateActivityScore(activeDays: activeDays)
        let consistency = calculateConsistencyScore()

        return StatsMetrics(
            discipline: discipline,
            planning: planning,
            friendship: 50,   // пока мок
            activity: activity,
            consistency: consistency
        )
    }

    // MARK: - Daily amounts

    private func fetchLast30DaysAmounts(uid: String) async -> [Date: Int] {
        let all = await dailyAmountStore.getAll(uid: uid)
        let today = calendar.startOfDay(for: Date())

        var result: [Date: Int] = [:]

        for offset in 0..<30 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let key = DayKey.make(from: day)
            result[day] = all[key] ?? 0
        }

        return result
    }

    private func calculateDisciplineScore(from amounts: [Date: Int]) -> Double {
        let daysWithTopUp = amounts.values.filter { $0 > 0 }.count
        let score = (Double(daysWithTopUp) / 30.0) * 100.0
        return clamp(score)
    }

    private func calculatePlanningScore(from amounts: [Date: Int]) -> Double {
        let topUpDays = amounts
            .filter { $0.value > 0 }
            .map { calendar.startOfDay(for: $0.key) }
            .sorted()

        guard topUpDays.count >= 3 else {
            return 0
        }

        var intervals: [Int] = []

        for i in 1..<topUpDays.count {
            let days = calendar.dateComponents([.day], from: topUpDays[i - 1], to: topUpDays[i]).day ?? 0
            intervals.append(days)
        }

        guard !intervals.isEmpty else {
            return 0
        }

        let average = Double(intervals.reduce(0, +)) / Double(intervals.count)

        let meanDeviation = intervals
            .map { abs(Double($0) - average) }
            .reduce(0, +) / Double(intervals.count)

        let deviationPenalty = meanDeviation * 15.0
        let score = 100.0 - deviationPenalty

        return clamp(score)
    }

    // MARK: - Activity

    private func fetchLast30ActiveDays(uid: String) async -> Int {
        let allKeys = await appActivityStore.getAll(uid: uid)
        let today = calendar.startOfDay(for: Date())

        var count = 0

        for offset in 0..<30 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let key = DayKey.make(from: day)

            if allKeys.contains(key) {
                count += 1
            }
        }

        return count
    }

    private func calculateActivityScore(activeDays: Int) -> Double {
        let score = (Double(activeDays) / 30.0) * 100.0
        return clamp(score)
    }

    // MARK: - Consistency

    private func calculateConsistencyScore() -> Double {
        guard let state = challengeStore.loadActive() else {
            return 0
        }

        let completedDays = state.completedDayKeys.count
        let score = (Double(completedDays) / 7.0) * 100.0

        return clamp(score)
    }

    // MARK: - Helpers

    private func clamp(_ value: Double, min: Double = 0, max: Double = 100) -> Double {
        Swift.max(min, Swift.min(max, value))
    }
}
