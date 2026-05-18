import Foundation
import FirebaseAuth
import FirebaseFirestore

final class UserStorage: ObservableObject {

    @Published var name: String = "Гость"
    @Published var registrationDate: Date? = nil
    @Published private(set) var isLoggedIn: Bool = false
    @Published private(set) var uid: String? = nil

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        observeAuthState()
    }

    private func observeAuthState() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }

            self.uid = user?.uid
            self.isLoggedIn = (user != nil)
            self.registrationDate = user?.metadata.creationDate

            let local = LocalUserService()
            local.setActive(uid: user?.uid)
            LocalChallengeStore.shared.setActive(uid: user?.uid)

            if let user {
                let profile = local.fetchProfile()
                self.name = profile.name
                // Подтягиваем валюту с сервера — она единая для аккаунта, не для устройства
                Task { await self.syncCurrencyFromFirestore(uid: user.uid) }
            } else {
                self.name = "Гость"
            }
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Sign out error:", error)
        }

        let local = LocalUserService()
        local.setActive(uid: nil)

        LocalChallengeStore.shared.setActive(uid: nil)

        name = "Гость"
        registrationDate = nil
        uid = nil
        isLoggedIn = false
    }

    func loginSucceeded() {
    }

    // MARK: - Currency sync

    /// Читает валюту из Firestore и пишет в UserDefaults.
    /// Вызывается при логине — перезаписывает локальное устройство настройкой аккаунта.
    private func syncCurrencyFromFirestore(uid: String) async {
        do {
            let snap = try await FirestorePaths.userDoc(uid: uid).getDocument()
            if let code = snap.data()?["currencyCode"] as? String, !code.isEmpty {
                // ВАЖНО: @AppStorage наблюдает за UserDefaults и публикует изменения в SwiftUI.
                // Запись обязательно с главного потока — иначе "Publishing from background thread".
                await MainActor.run {
                    UserDefaults.standard.set(code, forKey: "settings.currency.code")
                }
            }
        } catch {
            print("UserStorage: currency sync error:", error)
        }
    }

    /// Записывает выбранную валюту в Firestore.
    /// Вызывается из ProfileView при смене валюты.
    func syncCurrencyToFirestore(code: String) {
        guard let uid = self.uid,
              Auth.auth().currentUser?.uid == uid else { return }
        Task {
            do {
                try await FirestorePaths.userDoc(uid: uid).setData([
                    "currencyCode": code
                ], merge: true)
            } catch {
                print("UserStorage: currency write error:", error)
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
