import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

// Broadcast: a deposit was successfully written to Firestore.
// GoalViewModel does NOT subscribe (Firestore listener handles UI update).
// StatsView and AchievementsViewModel subscribe to react to deposits.
extension Notification.Name {
    static let didDeposit = Notification.Name("KopiCup.didDeposit")
}

final class FirebaseGoalService: GoalService {

    private let repo = GoalsRepository()
    private let db = Firestore.firestore()

    private var authHandle: AuthStateDidChangeListenerHandle?
    private var userListener: ListenerRegistration?
    private var goalListener: ListenerRegistration?

    private var currentGoalId: String?
    
    private let dailyAmountService = DailyAmountService()

    deinit {
        stopAllListening()
    }

    // MARK: - Observe Goal

    func observeGoal(_ handler: @escaping (Goal?) -> Void) {
        // Сбрасываем предыдущие слушатели
        stopAllListening()

        // Если пользователь уже есть — сразу стартуем
        if let uid = Auth.auth().currentUser?.uid {
            listenUserDoc(uid: uid, handler: handler)
        } else {
            handler(nil)
        }

        // Подпишемся на изменения состояния аутентификации
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            if let uid = user?.uid {
                self.listenUserDoc(uid: uid, handler: handler)
            } else {
                self.stopUserListening()
                self.stopGoalListening()
                self.currentGoalId = nil
                handler(nil)
            }
        }
    }

    private func listenUserDoc(uid: String, handler: @escaping (Goal?) -> Void) {
        stopUserListening()

        userListener = FirestorePaths.userDoc(uid: uid)
            .addSnapshotListener(includeMetadataChanges: false) { [weak self] snapshot, error in
                guard let self else { return }

                // Сетевая ошибка — не сбрасываем цель, показываем последнее состояние
                if let error {
                    print("listenUserDoc network error (goal kept):", error)
                    return
                }

                // Документ существует — обрабатываем данные
                if let snapshot, snapshot.exists, let data = snapshot.data() {
                    if let goalId = data["activeGoalId"] as? String, !goalId.isEmpty {
                        if self.currentGoalId != goalId {
                            self.currentGoalId = goalId
                            self.listenGoal(uid: uid, goalId: goalId, handler: handler)
                        }
                    } else {
                        // activeGoalId отсутствует — попробуем восстановить
                        self.stopGoalListening()
                        self.currentGoalId = nil
                        handler(nil)
                        self.ensureActiveGoalIfPossible(uid: uid, handler: handler)
                    }
                    return
                }

                // Документа нет совсем (новый пользователь или был удалён)
                if let snapshot, !snapshot.exists {
                    self.stopGoalListening()
                    self.currentGoalId = nil
                    handler(nil)
                    self.ensureActiveGoalIfPossible(uid: uid, handler: handler)
                }
                // snapshot == nil и error == nil: промежуточное состояние, ждём следующего события
            }
    }

    private func listenGoal(uid: String, goalId: String, handler: @escaping (Goal?) -> Void) {
        stopGoalListening()

        goalListener = FirestorePaths.goal(uid: uid, goalId: goalId)
            .addSnapshotListener(includeMetadataChanges: false) { snapshot, error in
                // Сетевая ошибка — не сбрасываем цель
                if let error {
                    print("listenGoal network error (goal kept):", error)
                    return
                }
                guard let snapshot else { return }
                guard snapshot.exists else {
                    // Документ цели физически удалён
                    handler(nil)
                    return
                }
                do {
                    let goal = try snapshot.data(as: Goal.self)
                    handler(goal)
                } catch {
                    print("decode Goal error:", error)
                }
            }
    }

    private func ensureActiveGoalIfPossible(uid: String, handler: @escaping (Goal?) -> Void) {
        Task {
            do {
                // Берём последнюю по updatedAt цель и делаем её активной
                let snap = try await FirestorePaths.goals(uid: uid)
                    .order(by: "updatedAt", descending: true)
                    .limit(to: 1)
                    .getDocuments()

                guard let doc = snap.documents.first else {
                    return
                }

                let goal = try doc.data(as: Goal.self)

                try await FirestorePaths.userDoc(uid: uid).setData([
                    "activeGoalId": doc.documentID,
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true)

                await MainActor.run {
                    self.currentGoalId = doc.documentID
                    self.listenGoal(uid: uid, goalId: doc.documentID, handler: handler)
                    handler(goal)
                }
            } catch {
                print("ensureActiveGoalIfPossible error:", error)
            }
        }
    }

    private func stopUserListening() {
        userListener?.remove()
        userListener = nil
    }

    private func stopGoalListening() {
        goalListener?.remove()
        goalListener = nil
    }

    private func stopAllListening() {
        if let authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
        authHandle = nil
        stopUserListening()
        stopGoalListening()
    }

    // MARK: - Mutations

    func createGoal(_ goal: Goal) {
        Task {
            do {
                _ = try await repo.createGoal(goal, setAsActive: true)
            } catch {
                print("createGoal error:", error)
            }
        }
    }

    func updateGoal(_ goal: Goal) {
        guard
            let uid = Auth.auth().currentUser?.uid,
            let goalId = goal.id
        else { return }

        Task {
            do {
                try FirestorePaths.goal(uid: uid, goalId: goalId)
                    .setData(from: goal, merge: true)
            } catch {
                print("updateGoal error:", error)
            }
        }
    }

    func deleteGoal() {
        guard
            let uid = Auth.auth().currentUser?.uid,
            let goalId = currentGoalId
        else { return }

        Task {
            do {
                try await FirestorePaths.goal(uid: uid, goalId: goalId).delete()
                try await FirestorePaths.userDoc(uid: uid).updateData([
                    "activeGoalId": FieldValue.delete()
                ])
            } catch {
                print("deleteGoal error:", error)
            }
        }
    }

    func addMoney(_ amount: Int) {
        guard let goalId = currentGoalId else { return }

        Task {
            do {
                try await repo.addTransaction(
                    goalId: goalId,
                    type: "deposit",
                    amount: amount
                )

                try await dailyAmountService.addToday(amount: amount)

                NotificationCenter.default.post(name: .didDeposit, object: nil)
            } catch {
                print("addMoney error:", error)
            }
        }
    }
    
    enum DayMath {
        static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
            calendar.startOfDay(for: date)
        }

        static func addDays(_ date: Date, days: Int, calendar: Calendar = .current) -> Date {
            calendar.date(byAdding: .day, value: days, to: date) ?? date
        }
    }

    func addMoney(_ amount: Int, for date: Date) {
        guard let goalId = currentGoalId else { return }

        Task {
            do {
                try await repo.addTransaction(
                    goalId: goalId,
                    type: "deposit",
                    amount: amount
                )

                try await dailyAmountService.add(amount: amount, for: date)

                NotificationCenter.default.post(name: .didDeposit, object: nil)
            } catch {
                print("addMoney(for:) error:", error)
            }
        }
    }

    // MARK: - Series stubs

    func observeSeries(_ handler: @escaping (Series) -> Void) {
        handler(
            Series(
                streakDays: 0,
                weekProgress: [false, false, false, false, false, false, false],
                lastAddedDate: nil
            )
        )
    }

    func updateSeries(_ series: Series) {
        // TODO: хранить Series в Firestore
    }
}
