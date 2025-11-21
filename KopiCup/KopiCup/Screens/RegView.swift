import SwiftUI

struct RegView: View {
    let onRegSuccess: () -> Void
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmedPassword: String = ""
    @State private var didTapSubmit: Bool = false
    
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
    
    var confirmedPasswordError: String? {
        if password != confirmedPassword {
            return "х Пароли не совпадают"
        }
        return nil
    }
    
    var isConfirmedPasswordValid: Bool {
        confirmedPasswordError == nil
    }
    
    var isFormFilled: Bool {
        !email.isEmpty && !password.isEmpty && !confirmedPassword.isEmpty
    }

    var isFormValid: Bool {
        isEmailValid && isPasswordValid && isConfirmedPasswordValid
    }
    
    var shouldShowEmailError: Bool {
        didTapSubmit && emailError != nil
    }

    var shouldShowPasswordError: Bool {
        didTapSubmit && passwordError != nil
    }

    var shouldShowConfirmedPasswordError: Bool {
        didTapSubmit && confirmedPasswordError != nil
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
                
                Text("Создайте свою копилку мечты!")
                    .font(.system(size: 18, design: .rounded))
                    .bold()
                Text("Ваша цель ждет - начните копить уже сегодня")
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
    }
    private var formFields: some View {
        VStack(spacing: 16) {
            LabeledTextField(
                title: "Email",
                placeholder: "email@example.com",
                iconName: "at",
                text: $email,
                error: didTapSubmit ? emailError : nil
            )
            
            LabeledSecureField(
                title: "Придумайте пароль",
                placeholder: "Создайте надежный пароль",
                iconName: "lock",
                text: $password,
                error: didTapSubmit ? passwordError : nil
            )
            
            LabeledSecureField(
                title: "Подтверждение пароля",
                placeholder: "Повторите пароль",
                iconName: "checkmark.circle",
                text: $confirmedPassword,
                error: didTapSubmit ? confirmedPasswordError : nil
            )
            
            GreenButton(title: "Старт к мечте!", isDisabled: !isFormFilled) {
                didTapSubmit = true

                if isFormValid {
                    // место для регистрации пользователя
                    print("Можно регистрировать пользователя")
                    onRegSuccess()
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
                    // место для регистрации через Google
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
                    // место для регистрации через VK ID
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
                    // место для регистрации через Apple
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
                Text("Уже есть аккаунт?")
                NavigationLink("Войти") {
                    AuthView()
                }
                
            }
            .font(.system(size: 14, design: .rounded)).bold()
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
