import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var userStorage: UserStorage

    private let userService: UserService = LocalUserService()
    private let goalService = FirebaseGoalService()
    private let challengeService: ChallengeService = LocalChallengeService()

    var body: some View {
        Group {
            if userStorage.isLoggedIn {
                MainTabView(
                    homeViewModel: HomeViewModel(
                        userService: userService,
                        goalService: goalService,
                        challengeService: challengeService
                    )
                )
            } else {
                NavigationStack {
                    AuthView(onAuthSuccess: {})
                }
            }
        }
    }
}
