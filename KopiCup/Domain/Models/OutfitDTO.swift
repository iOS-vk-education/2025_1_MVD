import Foundation
import FirebaseFirestore

struct OutfitDTO: Codable {
    @DocumentID var documentId: String?
    var id: String?
    var imageName: String
    var priceType: String
    var priceAmount: Int?
    var sortOrder: Int
    var isEnabled: Bool?

    init(
        documentId: String? = nil,
        id: String? = nil,
        imageName: String,
        priceType: String,
        priceAmount: Int?,
        sortOrder: Int,
        isEnabled: Bool? = true
    ) {
        self.documentId = documentId
        self.id = id
        self.imageName = imageName
        self.priceType = priceType
        self.priceAmount = priceAmount
        self.sortOrder = sortOrder
        self.isEnabled = isEnabled
    }
}

extension OutfitDTO {
    init(outfit: Outfit, sortOrder: Int) {
        let priceType: String
        let priceAmount: Int?

        switch outfit.price {
        case .free:
            priceType = "free"
            priceAmount = nil
        case .coins(let amount):
            priceType = "coins"
            priceAmount = amount
        case .trophies(let amount):
            priceType = "trophies"
            priceAmount = amount
        }

        self.init(
            documentId: outfit.id,
            id: outfit.id,
            imageName: outfit.imageName,
            priceType: priceType,
            priceAmount: priceAmount,
            sortOrder: sortOrder,
            isEnabled: true
        )
    }

    func toDomain() -> Outfit? {
        let resolvedId = (id?.isEmpty == false ? id : documentId) ?? ""
        guard !resolvedId.isEmpty else { return nil }

        let price: Outfit.Price
        switch priceType {
        case "free":
            price = .free
        case "coins":
            price = .coins(max(0, priceAmount ?? 0))
        case "trophies":
            price = .trophies(max(0, priceAmount ?? 0))
        default:
            return nil
        }

        return Outfit(
            id: resolvedId,
            imageName: imageName,
            price: price
        )
    }
}
