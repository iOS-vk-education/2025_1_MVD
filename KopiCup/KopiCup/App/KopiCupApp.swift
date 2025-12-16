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
        let db = Firestore.firestore()
        let settings = Firestore.firestore().settings
        
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        
        db.settings = settings
        
    }
}

@main
struct KopiCupApp: App {
    @StateObject private var userStorage = UserStorage()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                AppRootView()
            }
            .environmentObject(userStorage)
        }
    }
}
