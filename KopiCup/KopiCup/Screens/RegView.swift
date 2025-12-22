import SwiftUI
import FirebaseAuth
import AuthenticationServices

struct RegView: View {
    let onRegSuccess: () -> Void
    
    @StateObject private var form = RegFormModel()
    @State private var isMainTabPresented = false
    @State private var showFirebaseError = false
    
    var shouldShowEmailError: Bool {
        form.didTapSubmit && form.emailError != nil
    }

    var shouldShowPasswordError: Bool {
        form.didTapSubmit && form.passwordError != nil
    }

    var shouldShowConfirmedPasswordError: Bool {
        form.didTapSubmit && form.confirmedPasswordError != nil
    }

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
                
                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 112/255, green: 154/255, blue: 69/255))
                            .frame(width: 89, height: 89)
                            .offset(y: 5)
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 89, height: 89)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 16)
                            )
                    }
                    
                    Text("Создайте свою копилку мечты!")
                        .font(.system(size: 18, design: .rounded))
                        .bold()
                    Text("Ваша цель ждет - начните копить уже сегодня")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 13, design: .rounded))
                        .bold()
                        .foregroundColor(Color.secondary)
                    
                    formFields
                    
                    if form.isLoading {
                        ProgressView()
                            .padding(.top, 20)
                    }
                }
                .padding()
                .background(.white)
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )
                .padding(.horizontal, 36)
                .padding(.vertical, 16)
            }
            .onChange(of: form.errorMessage) { msg in
                showFirebaseError = (msg != nil)
            }
            .alert("Ошибка регистрации", isPresented: $showFirebaseError) {
                Button("OK", role: .cancel) { form.errorMessage = nil }
            } message: {
                Text(form.errorMessage ?? "Неизвестная ошибка")
            }
        }
    }
    
    private var formFields: some View {
        VStack(spacing: 16) {
            LabeledTextField(
                title: "Email",
                placeholder: "email@example.com",
                iconName: "at",
                text: $form.email,
                error: form.didTapSubmit ? form.emailError : nil
            )
            
            LabeledSecureField(
                title: "Придумайте пароль",
                placeholder: "Создайте надежный пароль",
                iconName: "lock",
                text: $form.password,
                error: form.didTapSubmit ? form.passwordError : nil
            )
            
            LabeledSecureField(
                title: "Подтверждение пароля",
                placeholder: "Повторите пароль",
                iconName: "checkmark.circle",
                text: $form.confirmedPassword,
                error: form.didTapSubmit ? form.confirmedPasswordError : nil
            )
            
            GreenButton(
                title: form.isLoading ? "Регистрация..." : "Старт к мечте!",
                isDisabled: !form.isFormFilled || form.isLoading
            ) {
                form.signUp {
                    onRegSuccess()
                }
            }
            .padding(.top, 8)
            .padding(.top, 8)

            
            socialLoginSection
                .padding(.top, 4)

        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var socialLoginSection: some View {
        VStack(spacing: 12) {
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
                
                Text("или войдите через")
                    .font(.system(size: 11, design: .rounded))
                    .bold()
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .layoutPriority(1)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    // TODO: Интегрировать вход через Google
                }) {
                    HStack(spacing: 8) {
                        Image("Google")
                            .resizable()
                            .scaledToFit()
                            .frame(width:20, height: 20)
                        Text("Google")
                    }
                    .foregroundColor(.black)
                    .font(.system(size: 11))
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button(action: {
                    // TODO: Регистрация через VK ID
                }) {
                    HStack(spacing: 8) {
                        Image("VK")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("VK ID")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.black)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        Task {
                            do {
                                try await AuthManager.shared.signInWithApple(result: result)
                            } catch {
                                print("Apple error:", error)
                            }
                        }
                    }
                )
                .signInWithAppleButtonStyle(.white)
                .frame(height: 44)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary, lineWidth: 1)
                )
            }
            
            HStack {
                Text("Уже есть аккаунт?")
                NavigationLink("Войти") {
                    AuthView(onAuthSuccess: {})
                }
            }
            .font(.system(size: 14, design: .rounded))
            .bold()
            .padding(.top, 12)
        }
    }
}

struct LabeledTextField: View {
    let title: String
    let placeholder: String
    let iconName: String?
    @Binding var text: String
    let error: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, design: .rounded))
                .bold()
            
            Label {
                TextField(
                    "",
                    text: $text,
                    prompt: Text(placeholder)
                        .foregroundColor(.gray.opacity(0.6))
                )
                .textInputAutocapitalization(.never)
            } icon: {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        error == nil ? Color.secondary : Color.red,
                        lineWidth: 2
                    )
            )
            
            if let error = error {
                Text(error)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.red)
            }
        }
    }
}

struct LabeledSecureField: View {
    let title: String
    let placeholder: String
    let iconName: String?
    @Binding var text: String
    let error: String?
    
    @State private var isSecure: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, design: .rounded))
                .bold()
            
            HStack {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .foregroundColor(.secondary)
                }
                
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .textInputAutocapitalization(.never)
                .textContentType(.password)
                
                Button(action: {
                    isSecure.toggle()
                }) {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        error == nil ? Color.secondary : Color.red,
                        lineWidth: 2
                    )
            )
            
            if let error = error {
                Text(error)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.red)
            }
        }
    }
}

struct GreenButton: View {
    let title: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .top) {
                if !isDisabled {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 78/255, green: 146/255, blue: 0))
                        .frame(height: 48)
                        .offset(y: 5)
                }

                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isDisabled
                        ? Color(red: 102/255, green: 190/255, blue: 0).opacity(0.5)
                        : Color(red: 102/255, green: 190/255, blue: 0)
                    )
                    .frame(height: 48)
                    .overlay(
                        Text(title)
                            .foregroundColor(.white.opacity(1.0))
                            .bold()
                    )
            }
        }
        .disabled(isDisabled)
    }
}


struct RegView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RegView(onRegSuccess: {})
        }
    }
}
