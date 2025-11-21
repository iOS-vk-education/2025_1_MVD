import SwiftUI

struct AppRootView: View {
    @State private var isRegistrated = false

    var body: some View {
        if isRegistrated {
            MainTabView()
        } else {
            NavigationStack {
                RegView(onRegSuccess: { isRegistrated = true })
            }
        }
    }
}
