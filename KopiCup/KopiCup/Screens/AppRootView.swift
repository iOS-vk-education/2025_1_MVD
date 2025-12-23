import SwiftUI
import FirebaseAuth

struct AppRootView: View {
    @EnvironmentObject private var userStorage: UserStorage
    @StateObject private var session = SessionManager()

    @StateObject private var onboardingVM = OnboardingViewModel()   // <-- ДОБАВИЛИ

    @State private var isResolvingOnboarding = false
    @State private var shouldShowOnboarding = false

    // TODO(#201): Сохранить токен и профиль в userStorage при реальной авторизации
    var body: some View {
        Group {
            if session.isLoggedIn {
                if isResolvingOnboarding {
                    ProgressView()
                } else {
                    MainTabView()
                        .fullScreenCover(isPresented: $shouldShowOnboarding) {
                            OnboardingView(
                                onSubmit: { name, goalTitle, targetAmount, imageData in
                                    await onboardingVM.saveOnboarding(
                                        name: name,
                                        goalTitle: goalTitle,
                                        targetAmount: targetAmount,
                                        goalImageURL: nil
                                    )
                                    shouldShowOnboarding = false
                                },
                                onFillLater: {
                                    shouldShowOnboarding = false
                                }
                            )
                        }
                }
            } else {
                NavigationStack {
                    AuthView(onAuthSuccess: {})
                }
            }
        }
        .onAppear {
            session.start()
        }
        .onChange(of: session.isLoggedIn) { isLoggedIn in
            if isLoggedIn {
                userStorage.loginSucceeded()
                isResolvingOnboarding = true

                Task { @MainActor in
                    await refreshOnboardingState()
                    isResolvingOnboarding = false
                }
            } else {
                userStorage.logout()
                shouldShowOnboarding = false
                isResolvingOnboarding = false
            }
        }
    }

    @MainActor
    private func refreshOnboardingState() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            shouldShowOnboarding = false
            return
        }

        try? await UserProfileService.shared.ensureProfileExists(uid: uid)

        let profile = try? await UserProfileService.shared.fetchProfile(uid: uid)
        let completed = profile?.onboardingCompleted ?? false

        shouldShowOnboarding = !completed
    }
}

