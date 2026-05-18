import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var appUserStorage: UserStorage
    @EnvironmentObject private var economy: EconomyStore
    @EnvironmentObject private var l10n: L10n

    private let userService = LocalUserService()
    private let localUser = LocalUserService()
    
    @AppStorage("settings.theme.darkMode") private var isDarkMode: Bool = false
    @AppStorage("settings.currency.code") private var currencyCode: String = "RUB"
    @AppStorage("settings.language.code") private var languageCode: String = "ru"
    
    @AppStorage("profile.name") private var storedName: String = "Гость"
    @AppStorage("profile.avatar.data") private var avatarData: Data = Data()
    @State private var avatarImage: UIImage? = nil

    @StateObject private var achievementsVM = AchievementsViewModel()
    
    @State private var showEditSheet = false
    
    enum PickerSource { case photoLibrary, camera }
    @State private var showImagePicker = false
    @State private var pickerSource: PickerSource = .photoLibrary
    
    @State private var showLogoutConfirm = false
    
    private var achievements: [AchievementItem] {
        let ids = AchievementsViewModel.ID.self
        let isUnlocked = { (id: String) in achievementsVM.unlockedIDs.contains(id) }

        // Порядок по требованию:
        // 1) Молниеносный старт, 2) Первое пополнение, 3) 7 дней подряд,
        // 4) Цель достигнута, 5) 30 дней подряд, 6) Лучший друг
        return [
            AchievementItem(id: ids.lightningStart, title: l10n.t(.achievLightningStart), systemImage: "bolt.fill", achieved: isUnlocked(ids.lightningStart)),
            AchievementItem(id: ids.firstTopup, title: l10n.t(.achievFirstTopup), systemImage: "star.fill", achieved: isUnlocked(ids.firstTopup)),
            AchievementItem(id: ids.sevenDays, title: l10n.t(.achievSevenDays), systemImage: "flame.fill", achieved: isUnlocked(ids.sevenDays)),
            AchievementItem(id: ids.goalReached, title: l10n.t(.achievGoalReached), systemImage: "scope", achieved: isUnlocked(ids.goalReached)),
            AchievementItem(id: ids.thirtyDays, title: l10n.t(.achievThirtyDays), systemImage: "medal.fill", achieved: isUnlocked(ids.thirtyDays)),
            AchievementItem(id: ids.bestFriend, title: l10n.t(.achievBestFriend), systemImage: "crown.fill", achieved: isUnlocked(ids.bestFriend))
        ]
    }
    private var achievedCount: Int { achievements.filter { $0.achieved }.count }

    private var displayName: String {
        let nameFromStore = appUserStorage.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !nameFromStore.isEmpty { return nameFromStore }
        let fromAppStorage = storedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !fromAppStorage.isEmpty { return fromAppStorage }
        return l10n.t(.guest)
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(red: 102/255, green: 190/255, blue: 0)
                    .frame(height: 72)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        headerCard
                        achievementsCard
                        settingsHeader
                        settingsCard
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            let profile = localUser.fetchProfile()

            if let data = profile.avatarData, !data.isEmpty, let img = UIImage(data: data) {
                avatarImage = img
                avatarData = data
            } else {
                avatarImage = nil
                avatarData = Data()
            }

            if appUserStorage.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                appUserStorage.name = profile.name
            }

            // Стартуем расчёт достижений
            achievementsVM.setEconomyStore(economy)
            achievementsVM.setUid(appUserStorage.uid)
        }
        .onChange(of: appUserStorage.uid) { newUid in
            achievementsVM.setUid(newUid)
        }
        .onChange(of: currencyCode) { newCode in
            // Сохраняем выбор валюты в Firestore — синхронизируется на все устройства аккаунта
            appUserStorage.syncCurrencyToFirestore(code: newCode)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .sheet(isPresented: $showEditSheet) {
            EditNameSheet(
                currentName: displayName,
                titleText: l10n.t(.editName),
                placeholderText: l10n.t(.yourName),
                cancelText: l10n.t(.cancel),
                saveText: l10n.t(.save),
                onCancel: { showEditSheet = false },
                onSave: { newName in
                    localUser.updateName(newName)
                    appUserStorage.name = localUser.fetchProfile().name
                    showEditSheet = false
                }
            )
            .presentationDetents([.height(220)])
        }
        .confirmationDialog(
            l10n.t(.logoutConfirm),
            isPresented: $showLogoutConfirm,
            titleVisibility: .visible
        ) {
            Button(l10n.t(.logout), role: .destructive) {
                performLogout()
            }
            Button(l10n.t(.cancel), role: .cancel) {}
        } message: {
            Text(l10n.t(.logoutReturn))
        }
        .sheet(isPresented: $showImagePicker) {
            SystemImagePicker(
                source: pickerSource == .camera ? .camera : .photoLibrary
            ) { image in
                if let image {
                    applyNewAvatar(image)
                }
                showImagePicker = false
            }
        }
    }
    
    private var headerCard: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 250/255, green: 237/255, blue: 210/255))
                    .frame(width: 56, height: 56)
                
                if let avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                } else {
                    Text(initials(from: displayName))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                }
            }
            .contentShape(Circle())
            .contextMenu {
                Button(l10n.t(.chooseFromGallery), systemImage: "photo.on.rectangle") {
                    pickerSource = .photoLibrary
                    showImagePicker = true
                }
                Button(l10n.t(.takePhoto), systemImage: "camera") {
                    pickerSource = .camera
                    showImagePicker = true
                }
                if avatarImage != nil {
                    Button(role: .destructive) {
                        removeAvatar()
                    } label: {
                        Label(l10n.t(.deletePhoto), systemImage: "trash")
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName.isEmpty ? l10n.t(.guest) : displayName)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text("\(l10n.t(.savingSince)) \(sinceText)")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            HStack(spacing: 8) {
                Button {
                    pickerSource = .photoLibrary
                    showImagePicker = true
                } label: {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .semibold))
                        .padding(10)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                        .accessibilityLabel(l10n.t(.editPhoto))
                }
                .buttonStyle(.plain)
                
                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .semibold))
                        .padding(10)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }
    
    private var sinceText: String {
        guard let date = appUserStorage.registrationDate else {
            return ""
        }

        let formatter = Foundation.DateFormatter()
        formatter.locale = l10n.locale
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }

    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.orange)
                    Text(l10n.t(.profileAchievements))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                Spacer()
                Text("\(achievedCount)/\(achievements.count)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 2)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(achievements) { item in
                    AchievementCell(item: item)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }
    
    private var settingsHeader: some View {
        Text(l10n.t(.profileSettings))
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
            .foregroundColor(.primary)
    }
    
    private var settingsCard: some View {
        VStack(spacing: 12) {
            SettingsToggleRow(
                icon: "sun.max.fill",
                iconColor: Color.yellow,
                title: l10n.t(.darkTheme),
                subtitle: nil,
                isOn: $isDarkMode
            )

            SettingsPickerRow(
                icon: "banknote.fill",
                iconColor: Color.green,
                title: l10n.t(.currency),
                valueText: currencyDisplayName(currencyCode)
            ) {
                Button("₽ RUB") { currencyCode = "RUB" }
                Button("$ USD") { currencyCode = "USD" }
                Button("€ EUR") { currencyCode = "EUR" }
                Button("¥ CNY") { currencyCode = "CNY" }
            }

            SettingsPickerRow(
                icon: "globe",
                iconColor: Color.blue,
                title: l10n.t(.language),
                valueText: languageDisplayName(languageCode)
            ) {
                Button(l10n.t(.languageRussian)) { languageCode = "ru" }
                Button(l10n.t(.languageEnglish)) { languageCode = "en" }
            }

            Button(role: .destructive) {
                showLogoutConfirm = true
            } label: {
                HStack {
                    Spacer()
                    Text(l10n.t(.logout))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Spacer()
                }
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }
    
    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let initials = parts.prefix(2).compactMap { $0.first }.map { String($0) }.joined()
        return initials.isEmpty ? "🐷" : initials.uppercased()
    }
    
    private func currencyDisplayName(_ code: String) -> String {
        switch code {
        case "RUB": return "₽ RUB"
        case "USD": return "$ USD"
        case "EUR": return "€ EUR"
        case "CNY": return "¥ CNY"
        default:    return code
        }
    }
    
    private func languageDisplayName(_ code: String) -> String {
        switch code {
        case "ru": return l10n.t(.languageRussian)
        case "en": return l10n.t(.languageEnglish)
        default:   return code
        }
    }
    
    private func applyNewAvatar(_ image: UIImage) {
        let maxSide: CGFloat = 512
        let scaled = image.scaledTo(maxSide: maxSide)
        if let data = scaled.jpegData(compressionQuality: 0.85) {
            self.avatarData = data
            self.avatarImage = UIImage(data: data)
        } else if let data = scaled.pngData() {
            self.avatarData = data
            self.avatarImage = UIImage(data: data)
        } else {
            self.avatarImage = image
        }
        localUser.updateAvatarData(self.avatarData)
    }
    
    private func removeAvatar() {
        self.avatarData = Data()
        self.avatarImage = nil
        localUser.updateAvatarData(nil)
    }
    
    private func performLogout() {
        appUserStorage.logout()
    }
}

private struct AchievementItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let achieved: Bool
}

private struct AchievementCell: View {
    let item: AchievementItem
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(item.achieved ? Color.yellow.opacity(0.16) : Color.gray.opacity(0.12))
                    .frame(height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(item.achieved ? Color.yellow.opacity(0.6) : Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
                
                Image(systemName: item.systemImage)
                    .font(.system(size: 22))
                    .foregroundColor(item.achieved ? .orange : .gray.opacity(0.6))
            }
            
            Text(item.title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(item.achieved ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            iconView
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    @ViewBuilder
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 36, height: 36)
            Image(systemName: icon)
                .foregroundColor(iconColor)
        }
    }
}

private struct SettingsPickerRow<MenuContent: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let valueText: String
    @ViewBuilder var menuContent: () -> MenuContent
    
    var body: some View {
        HStack(spacing: 12) {
            iconView
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text(valueText)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Menu {
                menuContent()
            } label: {
                HStack(spacing: 6) {
                    Text(valueText)
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.down")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    @ViewBuilder
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 36, height: 36)
            Image(systemName: icon)
                .foregroundColor(iconColor)
        }
    }
}

private struct EditNameSheet: View {
    @State private var name: String
    let titleText: String
    let placeholderText: String
    let cancelText: String
    let saveText: String
    let onCancel: () -> Void
    let onSave: (String) -> Void

    init(
        currentName: String,
        titleText: String = "Изменить имя",
        placeholderText: String = "Ваше имя",
        cancelText: String = "Отмена",
        saveText: String = "Сохранить",
        onCancel: @escaping () -> Void,
        onSave: @escaping (String) -> Void
    ) {
        _name = State(initialValue: currentName)
        self.titleText = titleText
        self.placeholderText = placeholderText
        self.cancelText = cancelText
        self.saveText = saveText
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(titleText)
                .font(.headline)
            TextField(placeholderText, text: $name)
                .textInputAutocapitalization(.words)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            HStack {
                Button(cancelText, action: onCancel)
                Spacer()
                Button(saveText) {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { onSave(trimmed) }
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .modifier(PresentationBackgroundCompat())
    }
}

private struct PresentationBackgroundCompat: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationBackground(.regularMaterial)
        } else {
            content
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProfileView()
                .previewDisplayName("Light")
                .environmentObject(UserStorage())
                .environmentObject(EconomyStore())
                .environmentObject(L10n.shared)
            ProfileView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")
                .environmentObject(UserStorage())
                .environmentObject(EconomyStore())
                .environmentObject(L10n.shared)
        }
    }
}

private struct SystemImagePicker: UIViewControllerRepresentable {
    enum Source {
        case photoLibrary
        case camera
        
        var uiKitSourceType: UIImagePickerController.SourceType {
            switch self {
            case .photoLibrary: return .photoLibrary
            case .camera: return .camera
            }
        }
    }
    
    let source: Source
    var onImagePicked: (UIImage?) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let vc = UIImagePickerController()
        let desiredSource = source.uiKitSourceType
        if UIImagePickerController.isSourceTypeAvailable(desiredSource) {
            vc.sourceType = desiredSource
        } else {
            vc.sourceType = .photoLibrary
        }
        vc.delegate = context.coordinator
        vc.allowsEditing = true
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImagePicked: (UIImage?) -> Void
        init(onImagePicked: @escaping (UIImage?) -> Void) { self.onImagePicked = onImagePicked }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            onImagePicked(image)
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImagePicked(nil)
            picker.dismiss(animated: true)
        }
    }
}

private extension UIImage {
    func scaledTo(maxSide: CGFloat) -> UIImage {
        let maxCurrent = max(size.width, size.height)
        guard maxCurrent > maxSide else { return self }
        let scale = maxSide / maxCurrent
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
