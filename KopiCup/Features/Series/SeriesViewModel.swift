import SwiftUI
import Combine

final class SeriesViewModel: ObservableObject {
    @Published var series: Series?
    @Published var dailyTarget: Int = 0
    @Published var todayAddedAmount: Int = 0
    @Published var showAddMoneyModal = false
    @Published var selectedDate: Date? = nil
    @Published var perDayAdded: [Int] = Array(repeating: 0, count: 7)
    @Published var displayedWeekStart: Date

    // Глобальная валюта отображения
    @Published var currencyCode: String = UserDefaults.standard.string(forKey: "settings.currency.code") ?? "RUB"

    @Published var goal: Goal? = nil

    private let goalService: GoalService
    private let uid: String
    private let rewardService = RewardService.shared
    private let dailyAmountService = DailyAmountService()
    private var allDayAmounts: [String: Int] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var udObserver: NSObjectProtocol?

    // MARK: - Persistence
    private let ud = UserDefaults.standard
    private enum Keys {
        static let streakDays = "series.streakDays"
        static let lastAddedDate = "series.lastAddedDate"
    }

    init(goalService: GoalService, uid: String) {
        self.goalService = goalService
        self.uid = uid
        self.displayedWeekStart = Self.weekStart(for: Date())

        loadPersistedSeriesState()
        refreshAmountsFromStore()

        // Цель приходит через HomeViewModel.goalVM.$currentGoal binding,
        // НЕ через прямой observeGoal — иначе stopAllListening() убивает
        // листенеры GoalViewModel и currentGoal зависает в nil.

        // Реагируем на смену глобальной валюты в профиле
        udObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let newCode = UserDefaults.standard.string(forKey: "settings.currency.code") ?? "RUB"
            if newCode != self.currencyCode {
                self.currencyCode = newCode
            }
        }
    }

    deinit {
        if let udObserver {
            NotificationCenter.default.removeObserver(udObserver)
        }
    }

    var totalSavedThisWeek: Int {
        perDayAdded.reduce(0, +)
    }

    var savedDaysCount: Int {
        perDayAdded.filter { $0 > 0 }.count
    }

    var currentDayIndex: Int {
        Self.dayIndex(for: Date())
    }

    var canShowNextWeek: Bool {
        displayedWeekStart < Self.weekStart(for: Date())
    }

    var weekRangeText: String {
        let end = Self.addDays(6, to: displayedWeekStart)
        let formatter = DateFormatter()
        formatter.locale = currentLocale
        formatter.setLocalizedDateFormatFromTemplate("d MMM")

        let startText = formatter.string(from: displayedWeekStart)
        let endText = formatter.string(from: end)
        return "\(startText) - \(endText)"
    }

    func addMoney(_ amountMinorUnits: Int) {
        addMoney(amountMinorUnits, for: selectedDate ?? Date())
    }

    func addMoney(_ amountMinorUnits: Int, for date: Date) {
        guard amountMinorUnits > 0 else { return }
        guard Self.isSameDay(date, Date()) else { return }

        let didCompleteGoal = willCompleteGoal(with: amountMinorUnits)
        let wasWeekAlreadyComplete = weekProgress(for: Self.weekStart(for: Date())).allSatisfy { $0 }
        let targetDate = Self.startOfDay(date)
        let key = DayKey.make(from: targetDate)

        goalService.addMoney(amountMinorUnits, for: targetDate)

        allDayAmounts[key, default: 0] += amountMinorUnits
        applyAmountsToDisplayedWeek()
        todayAddedAmount = allDayAmounts[DayKey.make(from: Date())] ?? 0
        recomputeSeries(lastAddedDate: targetDate)

        let isWeekNowComplete = weekProgress(for: Self.weekStart(for: Date())).allSatisfy { $0 }
        let didCompleteWeek = !wasWeekAlreadyComplete && isWeekNowComplete

        Task {
            await claimRewardsIfNeeded(
                didCompleteGoal: didCompleteGoal,
                didCompleteWeek: didCompleteWeek
            )
        }
    }

    func completeGoal() {
        let remaining = max(dailyTarget - todayAddedAmount, 0)
        guard remaining > 0 else { return }
        addMoney(remaining, for: Date())
    }

    var canCloseGoal: Bool {
        dailyTarget > 0 && todayAddedAmount < dailyTarget
    }

    var remainingAmountText: String {
        let remaining = max(dailyTarget - todayAddedAmount, 0)
        return formatWithCurrentCurrency(remaining)
    }

    var remainingToGoal: Int {
        guard let g = goal else { return 0 }
        return max(g.targetAmount - g.currentAmount, 0)
    }

    var remainingToGoalText: String {
        formatWithCurrentCurrency(remainingToGoal)
    }

    var canCloseFullGoal: Bool {
        remainingToGoal > 0
    }

    func closeFullGoal() {
        let remaining = remainingToGoal
        guard remaining > 0 else { return }
        addMoney(remaining, for: Date())
    }

    func showPreviousWeek() {
        displayedWeekStart = Self.addDays(-7, to: displayedWeekStart)
        applyAmountsToDisplayedWeek()
    }

    func showNextWeek() {
        guard canShowNextWeek else { return }
        displayedWeekStart = Self.addDays(7, to: displayedWeekStart)
        applyAmountsToDisplayedWeek()
    }

    func showCurrentWeek() {
        displayedWeekStart = Self.weekStart(for: Date())
        applyAmountsToDisplayedWeek()
    }

    func dateForDisplayedWeek(dayIndex: Int) -> Date {
        Self.addDays(dayIndex, to: displayedWeekStart)
    }

    func amountForDisplayedWeek(dayIndex: Int) -> Int {
        guard dayIndex >= 0, dayIndex < perDayAdded.count else { return 0 }
        return perDayAdded[dayIndex]
    }

    func isDayCompleted(_ dayIndex: Int) -> Bool {
        amountForDisplayedWeek(dayIndex: dayIndex) > 0
    }

    func isToday(dayIndex: Int) -> Bool {
        Self.isSameDay(dateForDisplayedWeek(dayIndex: dayIndex), Date())
    }

    func canAddMoney(dayIndex: Int) -> Bool {
        isToday(dayIndex: dayIndex)
    }

    // Форматирование по текущей глобальной валюте
    func formatWithCurrentCurrency(_ minorUnits: Int) -> String {
        let value = Double(minorUnits) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = currentLocale
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value) \(currencyCode)"
    }

    private var currentLocale: Locale {
        let languageCode = UserDefaults.standard.string(forKey: "settings.language.code") ?? "ru"
        switch AppLanguage(rawValue: languageCode) ?? .ru {
        case .ru:
            return Locale(identifier: "ru_RU")
        case .en:
            return Locale(identifier: "en_US")
        }
    }

    private func refreshAmountsFromStore() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let amounts = try await dailyAmountService.allDays()
                await MainActor.run {
                    self.allDayAmounts = amounts
                    self.applyAmountsToDisplayedWeek()
                    self.todayAddedAmount = amounts[DayKey.make(from: Date())] ?? 0
                    self.recomputeSeries(lastAddedDate: self.latestDepositDate())
                }
            } catch {
                print("SeriesViewModel daily amounts error:", error)
            }
        }
    }

    private func loadPersistedSeriesState() {
        let streakDays = ud.integer(forKey: key(Keys.streakDays))
        let lastTime = ud.double(forKey: key(Keys.lastAddedDate))
        let lastDate = lastTime > 0 ? Date(timeIntervalSince1970: lastTime) : Date.distantPast

        if streakDays > 0 || lastTime > 0 {
            series = Series(
                streakDays: streakDays,
                weekProgress: Array(repeating: false, count: 7),
                lastAddedDate: lastDate
            )
        }
    }

    private func key(_ suffix: String) -> String {
        "user.\(uid)." + suffix
    }

    private func saveSeriesCoreState() {
        guard let s = series else { return }
        ud.set(s.streakDays, forKey: key(Keys.streakDays))
        ud.set((s.lastAddedDate ?? Date.distantPast).timeIntervalSince1970, forKey: key(Keys.lastAddedDate))
    }

    private func applyAmountsToDisplayedWeek() {
        perDayAdded = (0..<7).map { index in
            let date = Self.addDays(index, to: displayedWeekStart)
            return allDayAmounts[DayKey.make(from: date)] ?? 0
        }
    }

    private func recomputeSeries(lastAddedDate: Date?) {
        series = Series(
            streakDays: currentStreakDays(),
            weekProgress: weekProgress(for: Self.weekStart(for: Date())),
            lastAddedDate: lastAddedDate
        )
        saveSeriesCoreState()
    }

    private func weekProgress(for weekStart: Date) -> [Bool] {
        (0..<7).map { index in
            let date = Self.addDays(index, to: weekStart)
            return (allDayAmounts[DayKey.make(from: date)] ?? 0) > 0
        }
    }

    private func currentStreakDays() -> Int {
        var cursor = Self.startOfDay(Date())

        if (allDayAmounts[DayKey.make(from: cursor)] ?? 0) == 0 {
            cursor = Self.addDays(-1, to: cursor)
        }

        var count = 0
        while (allDayAmounts[DayKey.make(from: cursor)] ?? 0) > 0 {
            count += 1
            cursor = Self.addDays(-1, to: cursor)
        }
        return count
    }

    private func latestDepositDate() -> Date? {
        let latestKey = allDayAmounts
            .filter { $0.value > 0 }
            .keys
            .max()

        guard let latestKey else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: latestKey)
    }

    private static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private static func weekStart(for date: Date) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        return calendar.startOfDay(for: start)
    }

    private static func addDays(_ days: Int, to date: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }

    private static func dayIndex(for date: Date) -> Int {
        (Calendar.current.component(.weekday, from: date) + 5) % 7
    }

    private static func isSameDay(_ d1: Date, _ d2: Date) -> Bool {
        Calendar.current.isDate(d1, inSameDayAs: d2)
    }

    private func willCompleteGoal(with addedAmount: Int) -> Bool {
        guard let goal else { return false }
        guard let goalId = goal.id, !goalId.isEmpty else { return false }
        guard goal.targetAmount > 0 else { return false }

        let oldAmount = goal.currentAmount
        let newAmount = oldAmount + addedAmount

        return oldAmount < goal.targetAmount && newAmount >= goal.targetAmount
    }

    private func makeWeekRewardKey(from date: Date) -> String {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let week = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.yearForWeekOfYear, from: date)
        return "\(year)-W\(week)"
    }

    private func claimRewardsIfNeeded(
        didCompleteGoal: Bool,
        didCompleteWeek: Bool
    ) async {
        if didCompleteGoal, let goalId = goal?.id {
            do {
                _ = try await rewardService.claimGoalCompleted(goalId: goalId)
            } catch {
                print("SeriesViewModel goal reward error:", error)
            }
        }

        if didCompleteWeek {
            let weekKey = makeWeekRewardKey(from: Date())
            do {
                _ = try await rewardService.claimWeeklyStreak(weekKey: weekKey)
            } catch {
                print("SeriesViewModel weekly streak reward error:", error)
            }
        }
    }
}
