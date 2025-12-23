import Foundation
import FirebaseFirestore

final class UserProfileService {
    static let shared = UserProfileService()
    private init() {}

    private let db = Firestore.firestore()
    
    func ensureProfileExists(uid: String) async throws {
        let ref = db.collection("users").document(uid)
        let snap = try await ref.getDocument()

        if snap.exists { return }

        let now = Date()
        let data: [String: Any] = [
            "uid": uid,
            "name": "",
            "goalTitle": "",
            "targetAmount": 0,
            "goalImageURL": NSNull(),
            "onboardingCompleted": false,
            "createdAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now)
        ]

        try await ref.setData(data, merge: true)
    }

    func upsertProfile(_ profile: UserProfile) async throws {
        let data: [String: Any] = [
            "uid": profile.uid,
            "name": profile.name,
            "goalTitle": profile.goalTitle,
            "targetAmount": profile.targetAmount,
            "goalImageURL": profile.goalImageURL as Any,
            "onboardingCompleted": profile.onboardingCompleted,
            "createdAt": Timestamp(date: profile.createdAt),
            "updatedAt": Timestamp(date: profile.updatedAt)
        ]

        try await db.collection("users")
            .document(profile.uid)
            .setData(data, merge: true)
    }

    func fetchProfile(uid: String) async throws -> UserProfile? {
        let snap = try await db.collection("users").document(uid).getDocument()
        guard let d = snap.data() else { return nil }

        return UserProfile(
            uid: uid,
            name: d["name"] as? String ?? "",
            goalTitle: d["goalTitle"] as? String ?? "",
            targetAmount: d["targetAmount"] as? Int ?? 0,
            goalImageURL: d["goalImageURL"] as? String,
            onboardingCompleted: d["onboardingCompleted"] as? Bool ?? false,
            createdAt: (d["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (d["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
