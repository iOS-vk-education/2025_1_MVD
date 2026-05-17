import Foundation
import Combine

@MainActor
final class AchievementsViewModel: ObservableObject {

    struct ID {
        static let lightningStart = "lightning_start"
        static let firstTopup     = "first_topup"
        static let sevenDays      = "seven_days"
        static let goalReached    = "goal_reached"
        static let thirtyDays     = "thirty_days"
        static let bestFriend     = "best_friend" // ранее "savings_master"
        
        static let all: [String] = [
            lightningStart, firstTopup, sevenDays, goalReached, thirtyDays, bestFriend
        ]
    }

    @Published private(set) var unlockedIDs: Set<String> = []

    private let goalService: GoalService
    private var economyStore: EconomyStore?
    private var store: AchievementsStore

    // Текущий uid и буфер достижений, полученных до его установки
    private var currentUid: String? = nil
    private var pendingUnlocks: Set<String> = []

    private var cancellables = Set<AnyCancellable>()

    init(goalService: GoalService = FirebaseGoalService()) {
        self.goalService = goalService
        self.store = AchievementsStore(uid: nil)

        // Наблюдаем цель и стрик
        goalService.observeGoal { [weak self] goal in
            Task { @MainActor in
                self?.handleGoal(goal)
            }
        }
        goalService.observeSeries { [weak self] series in
            Task { @MainActor in
                self?.handleSeries(series)
            }
        }

        // Мгновенная реакция на пополнение (не ждём синка цели из Firestore)
        NotificationCenter.default.publisher(for: .didDeposit)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.unlock(ID.firstTopup)
            }
            .store(in: &cancellables)

        // Начальная загрузка кэша (без uid — локальный, но мы не будем туда писать)
        refreshUnlockedFromStore()
    }

    func setEconomyStore(_ economy: EconomyStore) {
        economyStore = economy

        economy.$ownedOutfitIds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] owned in
                self?.handleOwnedOutfits(owned)
            }
            .store(in: &cancellables)

        // первичный прогон
        handleOwnedOutfits(economy.ownedOutfitIds)
    }

    func setUid(_ uid: String?) {
        currentUid = uid
        store.setUid(uid)

        // Если до этого успели получить достижения — фиксируем их уже на uid
        if !pendingUnlocks.isEmpty {
            let toApply = pendingUnlocks
            pendingUnlocks.removeAll()

            for id in toApply {
                let isFirstTime = !store.isUnlocked(id)
                store.unlock(id)
                if isFirstTime {
                    didUnlockFirstTime(id)
                }
            }
        }

        refreshUnlockedFromStore()

        // После смены uid прогоняем текущие состояния ещё раз,
        // чтобы сразу выдать достижения, если условия уже выполнены.
        if let economy = economyStore {
            handleOwnedOutfits(economy.ownedOutfitIds)
        }
    }

    // MARK: - Handlers

    private func handleGoal(_ goal: Goal?) {
        if goal != nil {
            unlock(ID.lightningStart)
        }

        if let goal {
            if goal.currentAmount > 0 {
                unlock(ID.firstTopup)
            }
            if isGoalCompleted(goal) {
                unlock(ID.goalReached)
            }
        }

        refreshUnlockedFromStore()
    }

    private func handleSeries(_ series: Series) {
        if series.streakDays >= 7 {
            unlock(ID.sevenDays)
        }
        if series.streakDays >= 30 {
            unlock(ID.thirtyDays)
        }
        refreshUnlockedFromStore()
    }

    private func handleOwnedOutfits(_ owned: Set<String>) {
        // Любой костюм сверх дефолтного "piggy_cool"
        if owned.subtracting(["piggy_cool"]).isEmpty == false {
            unlock(ID.bestFriend)
        }
        refreshUnlockedFromStore()
    }

    // MARK: - Helpers

    private func isGoalCompleted(_ goal: Goal) -> Bool {
        let status = goal.status.lowercased()
        if ["completed", "closed", "done", "finished"].contains(status) {
            return true
        }
        if goal.targetAmount > 0, goal.currentAmount >= goal.targetAmount {
            return true
        }
        return false
    }

    private func unlock(_ id: String) {
        // Если uid ещё не известен — буферизуем, чтобы не писать в "local"
        guard currentUid != nil else {
            pendingUnlocks.insert(id)
            return
        }

        // Показываем баннер только при первом получении достижения для данного uid
        let isFirstTime = !store.isUnlocked(id)
        store.unlock(id)

        if isFirstTime {
            didUnlockFirstTime(id)
        }
    }

    private func didUnlockFirstTime(_ id: String) {
        // Баннер для любого достижения
        guard let text = achievementPopupText(for: id) else { return }
        postAchievementPopup(title: text.title, message: text.message)
    }

    private func achievementPopupText(for id: String) -> (title: String, message: String)? {
        switch id {
        case ID.lightningStart:
            return ("Молниеносный старт", "Цель добавлена. Отличное начало!")
        case ID.firstTopup:
            return ("Первое пополнение", "Отличное начало накоплений!")
        case ID.sevenDays:
            return ("7 дней подряд", "Вы пополняли копилку 7 дней подряд!")
        case ID.goalReached:
            return ("Цель достигнута", "Поздравляем! Вы собрали всю нужную сумму.")
        case ID.thirtyDays:
            return ("30 дней подряд", "Вы пополняли копилку 30 дней подряд!")
        case ID.bestFriend:
            return ("Лучший друг", "Вы купили костюм для маскота.")
        default:
            return nil
        }
    }

    private func postAchievementPopup(title: String, message: String) {
        NotificationCenter.default.post(
            name: .rewardDidApply,
            object: nil,
            userInfo: [
                RewardNotificationUserInfoKeys.type: "achievement",
                RewardNotificationUserInfoKeys.title: title,
                RewardNotificationUserInfoKeys.message: message
            ]
        )
    }

    private func refreshUnlockedFromStore() {
        unlockedIDs = store.loadUnlocked(ids: ID.all)
    }
}

// MARK: - Persistence

private final class AchievementsStore {
    private let defaults: UserDefaults = .standard
    private var uid: String? = nil

    init(uid: String?) {
        self.uid = uid
    }

    func setUid(_ uid: String?) {
        self.uid = uid
    }

    func loadUnlocked(ids: [String]) -> Set<String> {
        Set(ids.filter { isUnlocked($0) })
    }

    func unlock(_ id: String) {
        defaults.set(true, forKey: key(for: id))
    }

    func isUnlocked(_ id: String) -> Bool {
        defaults.bool(forKey: key(for: id))
    }

    private func key(for id: String) -> String {
        "achievements.v1.\(uid ?? "local").\(id)"
    }
}

