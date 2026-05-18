import SwiftUI
import FirebaseCore
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        setupFirestore()
        return true
    }
    
    private func setupFirestore() {
        let settings = FirestoreSettings()
        // Постоянный диск-кэш — данные живут между запусками.
        // Без этого при VPN/офлайн Firestore не возвращает кешированные данные.
        settings.cacheSettings = PersistentCacheSettings(
            sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited)
        )
        Firestore.firestore().settings = settings
    }
}

@main
struct KopiCupApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    @StateObject private var userStorage = UserStorage()
    @StateObject private var economy = EconomyStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(userStorage)
                .environmentObject(economy)
                .environmentObject(L10n.shared)
        }
    }
}
