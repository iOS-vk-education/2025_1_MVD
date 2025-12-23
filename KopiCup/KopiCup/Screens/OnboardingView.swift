import SwiftUI
import PhotosUI

struct OnboardingView: View {

    let onSubmit: (
        _ name: String,
        _ goal: String,
        _ amount: Int,
        _ imageData: Data?
    ) async -> Void

    let onFillLater: () -> Void

    @State private var name = ""
    @State private var goal = ""
    @State private var amountText = ""

    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?

    @State private var isLoading = false
    @State private var errorText: String?

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

            ScrollView {
                VStack {
                    card
                }
                .padding(.horizontal, 16)
                .padding(.top, 40)
            }
        }
        .onChange(of: selectedItem) { newValue in
            guard let newValue else { return }
            Task {
                imageData = try? await newValue.loadTransferable(type: Data.self)
            }
        }
        .font(.system(.body, design: .rounded))
        .fontWeight(.bold)

    }

    private var background: some View {
        Image("background")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }

    private var card: some View {
        VStack(spacing: 18) {

            header

            inputField(
                title: "Как вас зовут?",
                placeholder: "Иван Иванов",
                icon: "person",
                text: $name
            )

            inputField(
                title: "Расскажите, о чем ваша мечта!",
                placeholder: "Например, поездка в Сочи…",
                icon: "cloud",
                text: $goal
            )

            inputField(
                title: "Сколько вам нужно накопить?",
                placeholder: "Укажите сумму в рублях",
                icon: "wallet.pass",
                text: $amountText,
                keyboard: .numberPad
            )

            if let errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            buttons
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 10)
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("🎉")
                Text("Поздравляем!")
                Text("🎉")
            }
            .font(.title2)
            .bold()

            Text("Ваша цель уже ждёт!")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Давайте познакомимся чуть ближе!")
                .font(.headline)
                .foregroundStyle(.blue)
                .padding(.top, 8)
        }
        .font(.system(.body, design: .rounded))
        .fontWeight(.bold)
    }

    private func inputField(
        title: String,
        placeholder: String,
        icon: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)

            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.gray)

                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .autocorrectionDisabled()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.gray.opacity(0.4))
            )
        }
    }

    private var buttons: some View {
        VStack(spacing: 10) {

            Button {
                Task { await submit() }
            } label: {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Открыть копилку!")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.7))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(isLoading)

            Button {
                onFillLater()
            } label: {
                Text("Заполнить позже")
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    private func submit() async {
        errorText = nil

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedGoal = goal.trimmingCharacters(in: .whitespaces)
        let trimmedAmount = amountText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorText = "Введите имя"
            return
        }

        guard !trimmedGoal.isEmpty else {
            errorText = "Введите название цели"
            return
        }

        guard !trimmedAmount.isEmpty else {
            errorText = "Введите сумму"
            return
        }

        guard let amount = Int(trimmedAmount) else {
            errorText = "Введите целое число"
            return
        }

        guard amount > 0 else {
            errorText = "Сумма должна быть больше 0"
            return
        }

        isLoading = true
        defer { isLoading = false }

        await onSubmit(trimmedName, trimmedGoal, amount, imageData)
    }
}
