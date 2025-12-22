import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem{
                    Label("Home", systemImage: "house")
                }
            StatsView()
                .tabItem{
                    Label("Stats", systemImage: "star")
                }
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage:    "person.circle")
                }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
