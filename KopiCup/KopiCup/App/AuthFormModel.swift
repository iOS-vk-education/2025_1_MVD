import Foundation
import Combine
import FirebaseAuth

final class AuthFormModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var rememberMe: Bool = false
    @Published var didTapSubmit: Bool = false
    @Published var isLoading: Bool = false
    @Published var firebaseError: String? = nil
    
    private func validateEmailError() -> String? {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return "х Пожалуйста, введите Email"
        }

        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        guard predicate.evaluate(with: trimmed) else {
            return "х Пожалуйста, введите корректный Email"
        }

        return nil
    }

    private func validatePasswordError() -> String? {
        guard !password.isEmpty else {
            return "х Пожалуйста, введите пароль"
        }
        return nil
    }
    
    var hasLocalValidationErrors: Bool {
        validateEmailError() != nil || validatePasswordError() != nil
    }
    
    var isFormFilled: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    var displayErrorForEmail: String? {
        // Если есть ошибка Firebase, показываем её
        if let firebaseError = firebaseError, firebaseError.contains("email") || firebaseError.contains("пользователь") {
            return firebaseError
        }
        return validateEmailError()
    }
    
    var displayErrorForPassword: String? {
        if let firebaseError = firebaseError, firebaseError.contains("пароль") || firebaseError.contains("password") {
            return firebaseError
        }
        return validatePasswordError()
    }
    
    func signIn(onSuccess: @escaping () -> Void) {
        didTapSubmit = true
        firebaseError = nil

        if hasLocalValidationErrors { return }

        isLoading = true

        Auth.auth().signIn(
            withEmail: email.trimmingCharacters(in: .whitespaces),
            password: password
        ) { _, error in
            self.isLoading = false

            if let error {
                self.firebaseError = error.localizedDescription
            } else {
                onSuccess()
            }
        }
    }
}
