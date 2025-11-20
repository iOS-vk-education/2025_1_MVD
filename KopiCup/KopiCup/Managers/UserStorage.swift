import Combine

final class UserStorage: ObservableObject {
    var name: String = "Guest"
    var isLoggedIn: Bool = false
    var userToken: String = ""
}
