import SwiftUI

struct MainTabView: View {

    let homeViewModel: HomeViewModel

    var body: some View {
        TabView {
            HomeView(viewModel: homeViewModel)
                .tabItem {
                    Label("Главная", systemImage: "house")
                }
            StatsView()
                .tabItem { Label("Статистика", systemImage: "chart.bar") }

            SettingsView()
                .tabItem { Label("Настройки", systemImage: "gear") }
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage:    "person.circle")
                }
        }
    }
}


struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        let homeViewModel = HomeViewModel(
            userService: MockUserService(),
            goalService: MockGoalService(),
            challengeService: MockChallengeService()
        )
        
        MainTabView(homeViewModel: homeViewModel)
    }
}
