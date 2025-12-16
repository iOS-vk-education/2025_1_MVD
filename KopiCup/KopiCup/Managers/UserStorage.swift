import Combine

final class UserStorage: ObservableObject {
    // TODO(#200): Заменить временные поля на реальные данные пользователя из бэкенда
    @Published var name: String = "Guest"
    @Published var isLoggedIn: Bool = false
    @Published var userToken: String = ""
}
