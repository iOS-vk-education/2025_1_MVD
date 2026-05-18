import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AppActivityService {
    private let store = AppActivityStore.shared

    func markAppOpen() {
        guard let uid = LocalUserStore.shared.activeUID else { return }

        Task {
            await store.markAppOpen(uid: uid)
            // Записываем ключ дня в Firestore — чтобы активность синхронизировалась
            // между устройствами. arrayUnion идемпотентен: повторный вызов не дублирует.
            await syncDayKeyToFirestore(uid: uid)
        }
    }

    private func syncDayKeyToFirestore(uid: String) async {
        guard Auth.auth().currentUser?.uid == uid else { return }
        let key = DayKey.make(from: Date())
        do {
            try await FirestorePaths.userDoc(uid: uid).setData([
                "activeDayKeys": FieldValue.arrayUnion([key])
            ], merge: true)
        } catch {
            // Не критично — данные уже сохранены локально
            print("AppActivityService: Firestore sync error:", error)
        }
    }
}
