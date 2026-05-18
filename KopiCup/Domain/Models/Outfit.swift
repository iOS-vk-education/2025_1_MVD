import Foundation

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

extension Outfit {
    static let defaultCatalog: [Outfit] = [
        Outfit(id: "piggy_cool", imageName: "piggy_cool", price: .free),
        Outfit(id: "piggy_wizard", imageName: "piggy_wizard", price: .coins(20)),
        Outfit(id: "piggy_ballerina", imageName: "piggy_ballerina", price: .coins(30)),
        Outfit(id: "piggy_queen", imageName: "piggy_queen", price: .trophies(3))
    ]

    static let defaultOutfitId = "piggy_cool"
}
