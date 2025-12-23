import Foundation
import FirebaseAuth

@MainActor
final class OnboardingViewModel: ObservableObject {

    @Published var isSaving = false
    @Published var errorText: String?

    func saveOnboarding(
        name: String,
        goalTitle: String,
        targetAmount: Int,
        goalImageURL: String?
    ) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorText = "Пользователь не авторизован"
            return
        }

        isSaving = true
        defer { isSaving = false }

        let now = Date()
        let profile = UserProfile(
            uid: uid,
            name: name,
            goalTitle: goalTitle,
            targetAmount: targetAmount,
            goalImageURL: goalImageURL,
            onboardingCompleted: true,
            createdAt: now,
            updatedAt: now
        )

        do {
            try await UserProfileService.shared.upsertProfile(profile)
        } catch {
            errorText = "Не удалось сохранить данные"
            print("Save onboarding error:", error)
        }
    }
}
