import SwiftUI

struct Outfit: Identifiable, Equatable, Codable {
    let id: String
    let imageName: String
    let price: Price

    enum Price: Codable, Equatable {
        case free
        case coins(Int)
        case trophies(Int)
    }
}

final class EconomyStore: ObservableObject {
    @Published private(set) var coins: Int = 0
    @Published private(set) var trophies: Int = 0

    @Published private(set) var ownedOutfitIds: Set<String> = []
    @Published private(set) var selectedOutfitId: String = "piggy_cool"

    // Каталог нарядов
    let catalog: [Outfit] = [
        Outfit(id: "piggy_cool",     imageName: "piggy_cool",     price: .free),
        Outfit(id: "piggy_wizard",   imageName: "piggy_wizard",   price: .coins(20)),
        Outfit(id: "piggy_ballerina",imageName: "piggy_ballerina",price: .coins(30)),
        Outfit(id: "piggy_queen",    imageName: "piggy_queen",    price: .trophies(3))
    ]

    private let store: LocalEconomyStore

    init(store: LocalEconomyStore = .shared) {
        self.store = store
        reloadFromStore()
        ensureDefaultOutfit()
    }

    // MARK: - Accessors

    var selectedOutfit: Outfit {
        catalog.first(where: { $0.id == selectedOutfitId }) ?? catalog[0]
    }

    var selectedOutfitImageName: String { selectedOutfit.imageName }

    var isGiftAvailableToday: Bool {
        let today = DayKey.make(from: Date())
        return store.lastGiftDayKey != today
    }

    // MARK: - Public API

    func setCoins(_ value: Int) {
        coins = max(0, value)
        store.save(coins: coins)
        objectWillChange.send()
    }

    func setTrophies(_ value: Int) {
        trophies = max(0, value)
        store.save(trophies: trophies)
        objectWillChange.send()
    }

    func canBuy(_ outfit: Outfit) -> Bool {
        guard !ownedOutfitIds.contains(outfit.id) else { return false }
        switch outfit.price {
        case .free: return true
        case .coins(let c): return coins >= c
        case .trophies(let t): return trophies >= t
        }
    }

    func buy(_ outfit: Outfit) -> Bool {
        guard !ownedOutfitIds.contains(outfit.id) else { return true }
        switch outfit.price {
        case .free:
            ownedOutfitIds.insert(outfit.id)
        case .coins(let c):
            guard coins >= c else { return false }
            coins -= c
            ownedOutfitIds.insert(outfit.id)
        case .trophies(let t):
            guard trophies >= t else { return false }
            trophies -= t
            ownedOutfitIds.insert(outfit.id)
        }
        persistOwnedAndBalances()
        return true
    }

    func select(_ outfit: Outfit) {
        guard ownedOutfitIds.contains(outfit.id) else { return }
        selectedOutfitId = outfit.id
        store.save(selectedOutfitId: selectedOutfitId)
        objectWillChange.send()
    }

    // Кнопка подарка: раз в день +10 кубков
    @discardableResult
    func collectDailyGift() -> Bool {
        let today = DayKey.make(from: Date())
        guard store.lastGiftDayKey != today else { return false }
        trophies += 10
        store.save(trophies: trophies)
        store.save(lastGiftDayKey: today)
        objectWillChange.send()
        return true
    }

    func reloadFromStore() {
        self.coins = store.loadCoins()
        self.trophies = store.loadTrophies()
        self.ownedOutfitIds = store.loadOwnedOutfits()
        self.selectedOutfitId = store.loadSelectedOutfitId() ?? "piggy_cool"
    }

    // Когда меняется активный пользователь
    func onActiveUserChanged() {
        reloadFromStore()
        ensureDefaultOutfit()
        objectWillChange.send()
    }

    // MARK: - Private

    private func ensureDefaultOutfit() {
        if !ownedOutfitIds.contains("piggy_cool") {
            ownedOutfitIds.insert("piggy_cool")
            store.save(ownedOutfits: ownedOutfitIds)
        }
        if catalog.first(where: { $0.id == selectedOutfitId }) == nil {
            selectedOutfitId = "piggy_cool"
            store.save(selectedOutfitId: selectedOutfitId)
        }
    }

    private func persistOwnedAndBalances() {
        store.save(coins: coins)
        store.save(trophies: trophies)
        store.save(ownedOutfits: ownedOutfitIds)
    }
}
