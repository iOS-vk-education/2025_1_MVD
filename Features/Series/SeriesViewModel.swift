import SwiftUI
import Combine

final class SeriesViewModel: ObservableObject {
    @Published var series: Series?
    @Published var dailyTarget: Int = 0
    @Published var todayAddedAmount: Int = 0
    @Published var showAddMoneyModal = false
    @Published var selectedDayIndex: Int? = nil
    @Published var perDayAdded: [Int] = Array(repeating: 0, count: 7)
    @Published var currencyCode: String = "RUB"
    
    @Published var goal: Goal? = nil
    
    private let goalService: GoalService
    private let uid: String
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Persistence
    private let ud = UserDefaults.standard
    private enum Keys {
        static let perDayAdded = "series.perDayAdded"
        static let weekProgress = "series.weekProgress"
        static let streakDays = "series.streakDays"
        static let lastAddedDate = "series.lastAddedDate"
    }
    
    init(goalService: GoalService, uid: String) {
        self.goalService = goalService
        self.uid = uid
        
        loadPersistedState()
        rollWeekIfNeeded()
        if perDayAdded.indices.contains(currentDayIndex) {
            todayAddedAmount = perDayAdded[currentDayIndex]
        }
        
//        goalService.observeSeries { [weak self] remoteSeries in
//            DispatchQueue.main.async {
//                guard let self else { return }
//                
//                if self.goal == nil, self.series != nil {
//                    return
//                }
//                
//                if let local = self.series {
//                    let chosen = self.preferSeries(local: local, remote: remoteSeries)
//                    self.series = chosen
//                } else {
//                    self.series = remoteSeries
//                }
//
//                self.saveSeriesCoreState()
//                self.rollWeekIfNeeded()
//            }
//        }
        
        goalService.observeGoal { [weak self] goal in
            DispatchQueue.main.async {
                self?.goal = goal
                if let code = goal?.currency, !code.isEmpty {
                    self?.currencyCode = code
                }
                _ = goal
            }
        }
    }
    
    var totalSavedThisWeek: Int {
        perDayAdded.reduce(0, +)
    }
    
    var savedDaysCount: Int {
        guard let progress = series?.weekProgress else { return 0 }
        return progress.filter { $0 }.count
    }
    
    var currentDayIndex: Int {
        (Calendar.current.component(.weekday, from: Date()) + 5) % 7
    }
    
    func addMoney(_ amountMinorUnits: Int) {
        addMoney(amountMinorUnits, for: currentDayIndex)
    }
    
    func addMoney(_ amountMinorUnits: Int, for dayIndex: Int) {
        guard amountMinorUnits > 0 else { return }
        
        guard dayIndex == currentDayIndex else { return }
        
        goalService.addMoney(amountMinorUnits)
        
        guard dayIndex >= 0, dayIndex < perDayAdded.count else { return }
        perDayAdded[dayIndex] += amountMinorUnits
        if dayIndex == currentDayIndex {
            todayAddedAmount = perDayAdded[dayIndex]
        }
        
        if let s = series {
            var newProgress = s.weekProgress
            var newStreak = s.streakDays
            
            if dayIndex >= 0, dayIndex < newProgress.count, newProgress[dayIndex] == false {
                newProgress[dayIndex] = true
                newStreak += 1
            }
            
            series = Series(
                streakDays: newStreak,
                weekProgress: newProgress,
                lastAddedDate: Date()
            )
        } else {
            var newProgress = Array(repeating: false, count: 7)
            newProgress[dayIndex] = true
            series = Series(
                streakDays: 1,
                weekProgress: newProgress,
                lastAddedDate: Date()
            )
        }
        
        savePerDayAdded()
        saveSeriesCoreState()
    }
    
    func completeGoal() {
        let remaining = max(dailyTarget - todayAddedAmount, 0)
        guard remaining > 0 else { return }
        addMoney(remaining, for: currentDayIndex)
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
        addMoney(remaining, for: currentDayIndex)
    }
    
    func isDayCompleted(_ dayIndex: Int) -> Bool {
        guard let progress = series?.weekProgress,
              dayIndex >= 0, dayIndex < progress.count else { return false }
        return progress[dayIndex]
    }
    
    func formatWithCurrentCurrency(_ minorUnits: Int) -> String {
        let value = Double(minorUnits) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value) \(currencyCode)"
    }
    
    
    private func loadPersistedState() {
        if let arr = ud.array(forKey: key(Keys.perDayAdded)) as? [Int] {
            // гарантируем длину 7
            if arr.count == 7 {
                perDayAdded = arr
            } else {
                perDayAdded = Array(arr.prefix(7)) + Array(repeating: 0, count: max(0, 7 - arr.count))
            }
        }
        
        let weekProgress = (ud.array(forKey: key(Keys.weekProgress)) as? [Bool]) ?? Array(repeating: false, count: 7)
        let streakDays = ud.integer(forKey: key(Keys.streakDays))
        let lastTime = ud.double(forKey: key(Keys.lastAddedDate))
        let lastDate = lastTime > 0 ? Date(timeIntervalSince1970: lastTime) : Date.distantPast
        
        if weekProgress.contains(true) || streakDays > 0 || lastTime > 0 {
            series = Series(
                streakDays: streakDays,
                weekProgress: weekProgress.count == 7 ? weekProgress : Array(weekProgress.prefix(7)) + Array(repeating: false, count: max(0, 7 - weekProgress.count)),
                lastAddedDate: lastDate
            )
        }
    }
    
    private func key(_ suffix: String) -> String {
        "user.\(uid)." + suffix
    }
    
    private func savePerDayAdded() {
        ud.set(perDayAdded, forKey: key(Keys.perDayAdded))
    }
    
    private func saveSeriesCoreState() {
        guard let s = series else { return }
        ud.set(s.weekProgress, forKey: key(Keys.weekProgress))
        ud.set(s.streakDays, forKey: key(Keys.streakDays))
        ud.set((s.lastAddedDate ?? Date.distantPast).timeIntervalSince1970, forKey: key(Keys.lastAddedDate))
    }
    
    private func rollWeekIfNeeded() {
        guard let s = series else { return }
        let now = Date()
        let last = s.lastAddedDate ?? Date.distantPast
        if !isSameWeek(last, now) {
            perDayAdded = Array(repeating: 0, count: 7)
            todayAddedAmount = 0
            series = Series(
                streakDays: s.streakDays,
                weekProgress: Array(repeating: false, count: 7),
                lastAddedDate: now
            )
            savePerDayAdded()
            saveSeriesCoreState()
        }
    }
    
    private func isSameWeek(_ d1: Date, _ d2: Date) -> Bool {
        let cal = Calendar.current
        return cal.component(.weekOfYear, from: d1) == cal.component(.weekOfYear, from: d2)
        && cal.component(.yearForWeekOfYear, from: d1) == cal.component(.yearForWeekOfYear, from: d2)
    }
    
    private func preferSeries(local: Series, remote: Series) -> Series {
        let localDate = local.lastAddedDate ?? .distantPast
        let remoteDate = remote.lastAddedDate ?? .distantPast
        
        if remoteDate > localDate {
            return remote
        } else if remoteDate < localDate {
            return local
        } else {
            let localCount = local.weekProgress.filter { $0 }.count
            let remoteCount = remote.weekProgress.filter { $0 }.count
            return remoteCount >= localCount ? remote : local
        }
    }
}
