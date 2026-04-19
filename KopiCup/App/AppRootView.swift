import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var userStorage: UserStorage
    @EnvironmentObject private var economy: EconomyStore

    private let userService: UserService = LocalUserService()
    private let goalService = FirebaseGoalService()
    private let challengeService: ChallengeService = LocalChallengeService()
    private let appActivityService = AppActivityService()

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
                .onAppear {
                    appActivityService.markAppOpen()
                }
            } else {
                NavigationStack {
                    AuthView(onAuthSuccess: {})
                }
            }
        }
        .task(id: userStorage.uid) {
            await economy.bootstrapForCurrentUser()
        }
    }
}
