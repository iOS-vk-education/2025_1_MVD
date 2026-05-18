import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var userStorage: UserStorage
    @EnvironmentObject private var l10n: L10n
    @StateObject private var rewardBannerCenter = RewardBannerCenter()
    @AppStorage("settings.theme.darkMode") private var isDarkMode: Bool = false

    // Храним единственный экземпляр HomeViewModel как @StateObject — он живёт всё время сессии.
    // Без этого AppRootView пересоздаёт HomeViewModel (и все listeners) при каждом изменении
    // userStorage.name / registrationDate / uid и т.д., что приводило к пропаданию цели.
    @StateObject private var homeViewModel = HomeViewModel(
        userService: LocalUserService(),
        goalService: FirebaseGoalService(),
        challengeService: FirebaseChallengeService()
    )
    private let appActivityService = AppActivityService()

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if userStorage.isLoggedIn {
                    MainTabView(homeViewModel: homeViewModel)
                        .onAppear {
                            appActivityService.markAppOpen()
                        }
                } else {
                    // .environment(\.colorScheme, .light) гарантирует светлую тему для всего
                    // экрана входа/регистрации независимо от глобального isDarkMode.
                    // .preferredColorScheme конкурирует с родительским значением и проигрывает;
                    // .environment напрямую перезаписывает значение в дереве — надёжнее.
                    NavigationStack {
                        AuthView(onAuthSuccess: {})
                    }
                    .environment(\.colorScheme, .light)
                }
            }

            if let banner = rewardBannerCenter.currentBanner {
                RewardToastView(data: banner)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .zIndex(999)
                    .allowsHitTesting(false)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        // Пробрасываем локаль системным форматтерам (Date, Number) по всему дереву
        .environment(\.locale, l10n.locale)
    }
}
