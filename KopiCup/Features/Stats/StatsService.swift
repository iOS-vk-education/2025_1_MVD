import Foundation
import FirebaseAuth

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

struct SavingsStatsSnapshot: Equatable {
    var weekTotal: Int
    var monthTotal: Int
    var avgPerDayThisMonth: Int
    var weekDailyTotals: [Double]
    var monthDynamicsValues: [Double]
    var monthDynamicsLabels: [String]

    static func empty(calendar: Calendar = .current) -> SavingsStatsSnapshot {
        let (labels, values) = sixMonthPlaceholders(calendar: calendar)
        return SavingsStatsSnapshot(
            weekTotal: 0,
            monthTotal: 0,
            avgPerDayThisMonth: 0,
            weekDailyTotals: Array(repeating: 0, count: 7),
            monthDynamicsValues: values,
            monthDynamicsLabels: labels
        )
    }

    private static func sixMonthPlaceholders(calendar: Calendar) -> ([String], [Double]) {
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        // Локаль из настроек приложения — реагирует на смену языка
        formatter.locale = L10n.shared.locale
        formatter.dateFormat = "LLL"

        var labels: [String] = []
        for offset in 0..<6 {
            guard let ref = calendar.date(byAdding: .month, value: offset - 5, to: today),
                  let mStart = calendar.date(from: calendar.dateComponents([.year, .month], from: ref))
            else { continue }
            labels.append(formatter.string(from: mStart).localizedCapitalized)
        }
        return (labels, Array(repeating: 0, count: labels.count))
    }
}

final class StatsService {
    private let dailyAmountStore = DailyAmountStore.shared
    private let appActivityStore = AppActivityStore.shared
    private let challengeStore = LocalChallengeStore.shared
    private let goalsRepository = GoalsRepository()
    private let piggyService: PiggyProfileService
    private let outfitCatalogService: PiggyOutfitCatalogService
    private let calendar = Calendar.current

    init(
        piggyService: PiggyProfileService = FirebasePiggyProfileService(),
        outfitCatalogService: PiggyOutfitCatalogService = FirebasePiggyOutfitCatalogService()
    ) {
        self.piggyService = piggyService
        self.outfitCatalogService = outfitCatalogService
    }

    func loadDashboard(uid: String) async -> (metrics: StatsMetrics, savings: SavingsStatsSnapshot) {
        let (deposits, fromRemote) = await loadDepositRecords(uid: uid)

        let amounts: [Date: Int]
        if fromRemote {
            amounts = buildLast30DaysAmountMap(fromDeposits: deposits, calendar: calendar)
        } else {
            amounts = await fetchLast30DaysAmounts(uid: uid)
        }

        let activeDays = await fetchLast30ActiveDays(uid: uid)

        let discipline = calculateDisciplineScore(from: amounts)
        let planning = calculatePlanningScore(from: amounts)
        let activity = calculateActivityScore(activeDays: activeDays)
        let consistency: Double
        if Auth.auth().currentUser?.uid == uid,
           let remote = await fetchRemoteConsistencyScore(uid: uid) {
            consistency = remote
        } else {
            consistency = calculateConsistencyScore()
        }

        // Дружба считается по взаимодействию с персонажем-копилкой.
        // Сейчас единственный источник — покупка костюмов.
        // Архитектура: добавить новый источник = написать новый
        // private func <name>Contribution(uid:) async -> Double
        // и включить его в calculateFriendshipScore с нужным весом.
        let friendship = await calculateFriendshipScore(uid: uid)

        let metrics = StatsMetrics(
            discipline: discipline,
            planning: planning,
            friendship: friendship,
            activity: activity,
            consistency: consistency
        )

        let savings: SavingsStatsSnapshot
        if fromRemote {
            savings = buildSavingsSnapshot(deposits: deposits, calendar: calendar)
        } else {
            // Нет удалённых данных — строим из локальных сумм (офлайн/удалена цель)
            savings = buildSavingsSnapshotFromLocal(amounts: amounts)
        }

        return (metrics, savings)
    }

    func loadMetrics(uid: String) async -> StatsMetrics {
        await loadDashboard(uid: uid).metrics
    }

    // MARK: - Friendship score

    private func calculateFriendshipScore(uid: String) async -> Double {
        let outfitScore = await outfitFriendshipContribution(uid: uid)
        // Единственный вклад — костюмы (вес 1.0).
        // При добавлении нового источника: взвешенная сумма / totalWeight.
        return clamp(outfitScore)
    }

    /// Костюмы: 1/4 = 25% (только дефолт), 2/4 = 50%, 3/4 = 75%, 4/4 = 100%.
    /// totalOutfits меняется при расширении каталога — остальное пересчитается само.
    private func outfitFriendshipContribution(uid: String) async -> Double {
        guard Auth.auth().currentUser?.uid == uid else { return 25 }
        do {
            async let profileResult = piggyService.fetchProfile(uid: uid)
            async let catalogResult = outfitCatalogService.fetchCatalog()
            let (profile, catalog) = try await (profileResult, catalogResult)
            let totalOutfits = max(catalog.count, 1)
            let owned = min(profile.ownedOutfitIds.count, totalOutfits)
            return (Double(owned) / Double(totalOutfits)) * 100.0
        } catch {
            return 25  // дефолт: только базовый костюм
        }
    }

    // MARK: - Firestore deposits

    private func loadDepositRecords(uid: String) async -> (records: [(Date, Int)], fromRemote: Bool) {
        guard Auth.auth().currentUser?.uid == uid else {
            return ([], false)
        }

        let today = calendar.startOfDay(for: Date())
        guard let windowStart = calendar.date(byAdding: .day, value: -200, to: today) else {
            return ([], false)
        }

        do {
            // Берём ID ВСЕХ целей пользователя — не только активной.
            // Это позволяет агрегировать историю пополнений по всем целям,
            // чтобы статистика не сбрасывалась при создании новой цели.
            let allGoalIds = try await withStatsTimeout(seconds: 8) {
                try await self.goalsRepository.fetchAllGoalIds()
            }
            guard !allGoalIds.isEmpty else {
                return ([], false)
            }

            // Собираем транзакции по каждой цели; каждый goalId — отдельный запрос.
            var allRecords: [(Date, Int)] = []
            for goalId in allGoalIds {
                let raw = try await withStatsTimeout(seconds: 8) {
                    try await self.goalsRepository.fetchDepositsSince(goalId: goalId, startDate: windowStart)
                }
                allRecords.append(contentsOf: raw.map { ($0.date, $0.amount) })
            }

            return (allRecords, true)
        } catch {
            print("loadDepositRecords error (fallback to local):", error)
            return ([], false)
        }
    }

    /// Запускает операцию с таймаутом; при истечении — CancellationError.
    private func withStatsTimeout<T: Sendable>(
        seconds: Double,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw CancellationError()
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    private func buildLast30DaysAmountMap(fromDeposits deposits: [(Date, Int)], calendar: Calendar) -> [Date: Int] {
        let today = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -29, to: today) else { return [:] }

        var map: [Date: Int] = [:]
        for offset in 0..<30 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            map[calendar.startOfDay(for: day)] = 0
        }

        for (date, amount) in deposits {
            let day = calendar.startOfDay(for: date)
            guard map[day] != nil else { continue }
            map[day, default: 0] += amount
        }

        return map
    }

    private func buildSavingsSnapshot(deposits: [(Date, Int)], calendar: Calendar) -> SavingsStatsSnapshot {
        var cal = calendar
        cal.firstWeekday = 2

        let today = cal.startOfDay(for: Date())
        guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: today) else {
            return .empty(calendar: calendar)
        }

        var weekDailyTotals = Array(repeating: 0.0, count: 7)
        var weekTotal = 0

        for (date, amount) in deposits {
            let d = cal.startOfDay(for: date)
            guard d >= weekInterval.start, d < weekInterval.end else { continue }
            let dayIndex = cal.dateComponents([.day], from: weekInterval.start, to: d).day ?? -1
            guard (0..<7).contains(dayIndex) else { continue }
            weekDailyTotals[dayIndex] += Double(amount) / 100.0
            weekTotal += amount / 100
        }

        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: today)),
              let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart)
        else {
            return .empty(calendar: calendar)
        }

        var monthTotal = 0
        for (date, amount) in deposits {
            let d = cal.startOfDay(for: date)
            if d >= monthStart, d < nextMonth {
                monthTotal += amount / 100
            }
        }

        let dayOfMonth = max(1, cal.component(.day, from: today))
        let avgPerDayThisMonth = monthTotal / dayOfMonth

        // Локаль из настроек приложения
        let formatter = DateFormatter()
        formatter.locale = L10n.shared.locale
        formatter.dateFormat = "LLL"

        var monthDynamicsValues: [Double] = []
        var monthDynamicsLabels: [String] = []

        for offset in 0..<6 {
            guard let ref = cal.date(byAdding: .month, value: offset - 5, to: today),
                  let mStart = cal.date(from: cal.dateComponents([.year, .month], from: ref)),
                  let mEnd = cal.date(byAdding: .month, value: 1, to: mStart)
            else { continue }

            var sum = 0
            for (date, amount) in deposits {
                let d = cal.startOfDay(for: date)
                if d >= mStart, d < mEnd {
                    sum += amount
                }
            }
            monthDynamicsValues.append(Double(sum) / 100.0)
            monthDynamicsLabels.append(formatter.string(from: mStart).localizedCapitalized)
        }

        return SavingsStatsSnapshot(
            weekTotal: weekTotal,
            monthTotal: monthTotal,
            avgPerDayThisMonth: avgPerDayThisMonth,
            weekDailyTotals: weekDailyTotals,
            monthDynamicsValues: monthDynamicsValues,
            monthDynamicsLabels: monthDynamicsLabels
        )
    }

    /// Снапшот из локального UserDefaults (нет активной цели / офлайн).
    private func buildSavingsSnapshotFromLocal(amounts: [Date: Int]) -> SavingsStatsSnapshot {
        var cal = calendar
        cal.firstWeekday = 2
        let today = cal.startOfDay(for: Date())

        guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: today),
              let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: today)),
              let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart)
        else { return .empty(calendar: calendar) }

        var weekDailyTotals = Array(repeating: 0.0, count: 7)
        var weekTotal = 0
        var monthTotal = 0

        for (date, amount) in amounts {
            let d = cal.startOfDay(for: date)
            if d >= weekInterval.start, d < weekInterval.end {
                let dayIndex = cal.dateComponents([.day], from: weekInterval.start, to: d).day ?? -1
                if (0..<7).contains(dayIndex) {
                    weekDailyTotals[dayIndex] += Double(amount) / 100.0
                    weekTotal += amount / 100
                }
            }
            if d >= monthStart, d < nextMonth {
                monthTotal += amount / 100
            }
        }

        let dayOfMonth = max(1, cal.component(.day, from: today))
        let empty = SavingsStatsSnapshot.empty(calendar: calendar)

        return SavingsStatsSnapshot(
            weekTotal: weekTotal,
            monthTotal: monthTotal,
            avgPerDayThisMonth: monthTotal / dayOfMonth,
            weekDailyTotals: weekDailyTotals,
            monthDynamicsValues: empty.monthDynamicsValues,
            monthDynamicsLabels: empty.monthDynamicsLabels
        )
    }

    // MARK: - Daily amounts (fallback)

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
        let localKeys = await appActivityStore.getAll(uid: uid)
        var allKeys = localKeys

        // Сливаем ключи с Firestore для учёта активности с других устройств
        if Auth.auth().currentUser?.uid == uid,
           let remoteKeys = await fetchRemoteActivityKeys(uid: uid) {
            let newKeys = remoteKeys.subtracting(localKeys)
            if !newKeys.isEmpty {
                // Записываем обратно в локальный кеш, чтобы офлайн тоже работал
                await appActivityStore.mergeKeys(uid: uid, keys: newKeys)
            }
            allKeys.formUnion(remoteKeys)
        }

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

    private func fetchRemoteActivityKeys(uid: String) async -> Set<String>? {
        do {
            let snap = try await withStatsTimeout(seconds: 5) {
                try await FirestorePaths.userDoc(uid: uid).getDocument()
            }
            let keys = snap.data()?["activeDayKeys"] as? [String] ?? []
            return Set(keys)
        } catch {
            print("StatsService: fetchRemoteActivityKeys error:", error)
            return nil
        }
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

    private func fetchRemoteConsistencyScore(uid: String) async -> Double? {
        do {
            let snapshot = try await FirestorePaths.activeChallengeState(uid: uid).getDocument()
            guard let data = snapshot.data() else { return nil }
            let completed = data["completedDayKeys"] as? [String] ?? []
            let score = (Double(completed.count) / 7.0) * 100.0
            return clamp(score)
        } catch {
            print("fetchRemoteConsistencyScore error:", error)
            return nil
        }
    }

    // MARK: - Helpers

    private func clamp(_ value: Double, min: Double = 0, max: Double = 100) -> Double {
        Swift.max(min, Swift.min(max, value))
    }
}
