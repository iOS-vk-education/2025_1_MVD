import Foundation
import Combine

final class AuthFormModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var rememberMe: Bool = false
    @Published var didTapSubmit: Bool = false
    @Published var isLoading: Bool = false
    @Published var firebaseError: String? = nil
    
    var emailValidationError: String? {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return "х Пожалуйста, введите Email"
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        if !emailPredicate.evaluate(with: trimmed) {
            return "х Пожалуйста, введите корректный Email"
        }
        
        return nil
    }
    
    var passwordValidationError: String? {
        guard !password.isEmpty else {
            return "х Пожалуйста, введите пароль"
        }
        return nil
    }
    
    var hasLocalValidationErrors: Bool {
        emailValidationError != nil || passwordValidationError != nil
    }
    
    var isFormFilled: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    var displayErrorForEmail: String? {
        // Если есть ошибка Firebase, показываем её
        if let firebaseError = firebaseError, firebaseError.contains("email") || firebaseError.contains("пользователь") {
            return firebaseError
        }
        return emailValidationError
    }
    
    var displayErrorForPassword: String? {
        if let firebaseError = firebaseError, firebaseError.contains("пароль") || firebaseError.contains("password") {
            return firebaseError
        }
        return passwordValidationError
    }
}
