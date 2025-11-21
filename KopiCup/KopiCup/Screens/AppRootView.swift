import SwiftUI

struct AppRootView: View {
    @State private var isAuthorized = false

    var body: some View {
        if isAuthorized {
            MainTabView()
        } else {
            NavigationStack {
                AuthView(onAuthSuccess: { isAuthorized = true })
            }
        }
    }
}
