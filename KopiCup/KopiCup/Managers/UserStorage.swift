import Foundation
import Combine

final class UserStorage: ObservableObject {
    // TODO(#200): Заменить временные поля на реальные данные пользователя из бэкенда
    @Published var name: String = "Guest"
    @Published var userToken: String = ""
    @Published private(set) var isLoggedIn: Bool = false
    @Published var registrationDate: Date? = nil

    func loginSucceeded() {
        isLoggedIn = true
    }

    func logout() {
        isLoggedIn = false
    }
}
