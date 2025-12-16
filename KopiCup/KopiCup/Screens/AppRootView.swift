
import SwiftUI


struct AppRootView: View {
    @EnvironmentObject private var userStorage: UserStorage
    

    var body: some View {
        if userStorage.isLoggedIn {
            MainTabView()
        } else {
            NavigationStack {
                AuthView(onAuthSuccess: {
                    // TODO(#201): Сохранить токен и профиль в userStorage при реальной авторизации
                    userStorage.isLoggedIn = true
                })
            }
        }
    }
}
