import SwiftUI

struct AuthView: View {
    let onAuthSuccess: () -> Void
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var didTapSubmit: Bool = false
    @State private var rememberMe: Bool = false
    
    var emailError: String? {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        let error = "х Пожалуйста, введите корректный Email"
        guard !trimmed.contains(" ") else { return error }
        
        let parts = trimmed.split(separator: "@")
        guard parts.count == 2 else { return error }
        
        guard !parts[0].isEmpty, !parts[1].isEmpty else { return error }
        guard parts[0].first != ".", parts[1].first != "." else { return error }
        guard parts[0].last != ".", parts[1].last != "." else { return error }
        
        return nil
    }
    
    var isEmailValid: Bool {
        emailError == nil
    }
    
    var passwordError: String? {
        let has_upper_case = password.contains(where: { $0.isUppercase })
        let has_digit = password.contains(where: { $0.isNumber })
        if password.count < 8 || !has_upper_case || !has_digit {
            return "х Пароль должен быть не менее 8 символов, содержать цифру и заглавную букву"
        }
        return nil
    }
    
    var isPasswordValid: Bool {
        passwordError == nil
    }
    
    var isFormFilled: Bool {
        !email.isEmpty && !password.isEmpty
    }

    var isFormValid: Bool {
        isEmailValid && isPasswordValid
    }
    
    var body: some View {
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

                Text("С возвращением к твоей цели!")
                    .font(.system(size: 18, design: .rounded))
                    .bold()
                Text("Подтверди твои намерения")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 13, design: .rounded))
                    .bold()
                    .foregroundColor(Color.secondary)
                formFields
                    
            }
            
            .padding()
            .background(.white)
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
            .padding(.horizontal, 36)
            .padding(.vertical, 16)
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var formFields: some View {
        VStack(spacing: 20) {
            LabeledTextField(
                title: "Email",
                placeholder: "email@example.com",
                iconName: "at",
                text: $email,
                error: didTapSubmit ? emailError : nil
            )
            
            LabeledSecureField(
                title: "Пароль",
                placeholder: "Введите пароль",
                iconName: "lock",
                text: $password,
                error: didTapSubmit ? passwordError : nil
            )
            
            HStack {

                Checkbox(isOn: $rememberMe, label: "Запомнить меня")
                Spacer()
                NavigationLink("Забыли пароль?") {
                    // логика для восстановления пароля
                }
                    .font(.system(size: 14, design: .rounded)).bold()
                
            }
            
            GreenButton(title: "Начать копить", isDisabled: !isFormFilled) {
                didTapSubmit = true

                if isFormValid {
                    // место для авторизации пользователя
                    print("Можно авторизовать пользователя")
                    onAuthSuccess()
                }
            }
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
                    // место для авторизации через Google
                    print("Регистрация через Google")
                }) {
                    HStack(spacing: 8) {
                        Image("Google")
                            .resizable()
                            .scaledToFit()
                            .frame(width:20, height: 20)
                        Text("Google")
                    }
                    .foregroundColor(.black)
                    .font(.system(size: 14, design: .rounded))
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
                    // место для авторизации через VK ID
                    print("Регистрация через VK ID")
                }) {
                    HStack(spacing: 8) {
                        Image("VK")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("VK ID")
                    }
                    .font(.system(size: 14, design: .rounded))
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
                
                Button(action: {
                    // место для авторизации через Apple
                    print("Регистрация через Apple")
                }) {
                    HStack(spacing: 8) {
                        Image("Apple")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("Apple")
                    }
                    .font(.system(size: 14, design: .rounded))
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
            }
            HStack {
                Text("Нет аккаунта?")
                NavigationLink("Зарегистрироваться") {
                    RegView(onRegSuccess: {})
                }
                
            }
            .font(.system(size: 14, design: .rounded)).bold()
            .padding(.top, 12)
        }
    }

}

struct Checkbox: View {
    @Binding var isOn: Bool
    var label: String

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)

                Text(label)
                    .foregroundColor(.primary)
                    .font(.system(size: 14, design: .rounded)).bold()
            }
        }
        .buttonStyle(.plain)
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AuthView(onAuthSuccess: {})
        }
    }
}
