import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var userStorage: UserStorage
    @StateObject private var session = SessionManager()

    var body: some View {
        Group {
            if session.isLoggedIn {
                MainTabView()
            } else {
                NavigationStack {
                    AuthView(onAuthSuccess: {
                        // TODO(#201): Сохранить токен и профиль в userStorage при реальной авторизации
                    })
                }
            }
        }
        .onAppear {
            session.start()
        }
        .onChange(of: session.isLoggedIn) { isLoggedIn in
            if isLoggedIn {
                userStorage.loginSucceeded()
            } else {
                userStorage.logout()
            }
        }
    }
}
