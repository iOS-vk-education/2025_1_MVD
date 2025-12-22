import SwiftUI
import FirebaseAuth

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var isLoading = false

    @State private var showAlert = false
    @State private var alertTitle = "Восстановление пароля"
    @State private var alertMessage = ""
    @State private var shouldDismissAfterAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.2)
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color(red: 102/255, green: 190/255, blue: 0).opacity(0.3),
                                Color(red: 78/255, green: 146/255, blue: 0).opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    header

                    formFields

                    if isLoading {
                        ProgressView()
                            .padding(.top, 12)
                    }
                }
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 36)
                .padding(.vertical, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if shouldDismissAfterAlert { dismiss() }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 112/255, green: 154/255, blue: 69/255))
                    .frame(width: 89, height: 89)
                    .offset(y: 5)

                Image(systemName: "key.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
                    .frame(width: 89, height: 89)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 112/255, green: 154/255, blue: 69/255).opacity(0.001))
                    )
            }

            Text("Восстановление пароля")
                .font(.system(size: 18, design: .rounded))
                .bold()

            Text("Введите email, указанный при регистрации. Если аккаунт существует, мы отправим ссылку для сброса пароля.")
                .multilineTextAlignment(.center)
                .font(.system(size: 13, design: .rounded))
                .bold()
                .foregroundColor(Color.secondary)
                .padding(.horizontal, 6)
        }
        .padding(.top, 6)
    }

    private var formFields: some View {
        VStack(spacing: 20) {
            // Если хочешь 1-в-1, можно заменить на ваш LabeledTextField.
            // Я оставил простой вариант, чтобы оно собиралось даже если компонент в другом модуле.
//            VStack(alignment: .leading, spacing: 8) {
//                Text("Email")
//                    .font(.system(size: 14, design: .rounded))
//                    .bold()
//
//                HStack(spacing: 10) {
//                    Image(systemName: "at")
//                        .foregroundColor(.secondary)
//
//                    TextField("email@example.com", text: $email)
//                        .textInputAutocapitalization(.never)
//                        .keyboardType(.emailAddress)
//                        .textContentType(.emailAddress)
//                }
//                .padding(.vertical, 12)
//                .padding(.horizontal, 12)
//                .background(Color.white)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 10)
//                        .stroke(Color.secondary, lineWidth: 2)
//                )
//                .clipShape(RoundedRectangle(cornerRadius: 10))
//            }
            LabeledTextField(
              title: "Email",
              placeholder: "email@example.com",
              iconName: "at",
              text: $email,
              error: nil
            )

            GreenButton(
                title: isLoading ? "Отправляем..." : "Отправить ссылку",
                isDisabled: email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading
            ) {
                sendReset()
            }
            .padding(.top, 8)

            Text("Если письмо не пришло - проверь «Спам» и «Промоакции».")
                .font(.system(size: 11, design: .rounded))
                .bold()
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sendReset() {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            showError("Введите email")
            return
        }

        isLoading = true
        shouldDismissAfterAlert = false

        Auth.auth().sendPasswordReset(withEmail: trimmed) { error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    showError(convertFirebaseError(error))
                } else {
                    alertTitle = "Готово"
                    alertMessage = "Если аккаунт с таким email существует, мы отправили ссылку для сброса пароля."
                    shouldDismissAfterAlert = true
                    showAlert = true
                }
            }
        }
    }

    private func showError(_ message: String) {
        alertTitle = "Ошибка"
        alertMessage = message
        showAlert = true
    }

    private func convertFirebaseError(_ error: Error) -> String {
        let nsError = error as NSError
        switch nsError.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return "Неверный формат email"
        case AuthErrorCode.networkError.rawValue:
            return "Проблемы с сетью. Проверьте подключение к интернету"
        default:
            return "Ошибка: \(error.localizedDescription)"
        }
    }
}
