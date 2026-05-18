import SwiftUI

struct MainTabView: View {
    let homeViewModel: HomeViewModel
    @EnvironmentObject private var l10n: L10n

    var body: some View {
        TabView {
            HomeView(viewModel: homeViewModel)
                .tabItem {
                    Label(l10n.t(.tabHome), systemImage: "house")
                }
            StatsView()
                .tabItem {
                    Label(l10n.t(.tabStats), systemImage: "chart.bar")
                }
            ProfileView()
                .tabItem {
                    Label(l10n.t(.tabProfile), systemImage: "person.circle")
                }
        }
    }
}
