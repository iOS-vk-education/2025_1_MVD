import Foundation
import FirebaseFirestore

protocol PiggyOutfitCatalogService {
    func fetchCatalog() async throws -> [Outfit]
}

final class FirebasePiggyOutfitCatalogService: PiggyOutfitCatalogService {
    private var catalogRef: CollectionReference {
        FirestorePaths.piggyOutfitsCatalog()
    }

    func fetchCatalog() async throws -> [Outfit] {
        let snapshot = try await catalogRef
            .order(by: "sortOrder")
            .getDocuments()

        let catalog = snapshot.documents.compactMap { document -> Outfit? in
            guard let dto = try? document.data(as: OutfitDTO.self),
                  dto.isEnabled ?? true else {
                return nil
            }
            return dto.toDomain()
        }

        return catalog
    }
}
