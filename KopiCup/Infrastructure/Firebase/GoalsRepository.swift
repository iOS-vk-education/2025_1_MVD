import Foundation
import FirebaseAuth
import FirebaseFirestore

enum GoalsRepoError: Error, LocalizedError {
    case notSignedIn
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "Пользователь не авторизован"
        case .invalidAmount:
            return "Некорректная сумма"
        }
    }
}

final class GoalsRepository {
    private var uid: String? { Auth.auth().currentUser?.uid }

    func createGoal(_ goal: Goal, setAsActive: Bool = true) async throws -> String {
        guard let uid else { throw GoalsRepoError.notSignedIn }

        let docRef = FirestorePaths.goals(uid: uid).document()
        var newGoal = goal
        newGoal.id = docRef.documentID

        // Ожидаем подтверждения записи goal-документа (хотя бы локального кеша)
        // перед тем, как выставить activeGoalId. Без await была гонка:
        // activeGoalId мог быть прочитан snapshot-листенером раньше, чем
        // goal-документ появлялся в кеше → handler(nil) → цель пропадала.
        try await docRef.setData(from: newGoal)

        if setAsActive {
            try await FirestorePaths.userDoc(uid: uid).setData([
                "activeGoalId": docRef.documentID,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
        }

        return docRef.documentID
    }

    func fetchActiveGoal() async throws -> Goal? {
        guard let uid else { throw GoalsRepoError.notSignedIn }

        let userSnap = try await FirestorePaths.userDoc(uid: uid).getDocument()
        let activeGoalId = userSnap.data()?["activeGoalId"] as? String
        guard let goalId = activeGoalId else { return nil }

        let goalSnap = try await FirestorePaths.goal(uid: uid, goalId: goalId).getDocument()
        return try goalSnap.data(as: Goal.self)
    }

    func addTransaction(
        goalId: String,
        type: String,
        amount: Int,
        note: String? = nil,
        challengeId: String? = nil
    ) async throws {
        guard let uid else { throw GoalsRepoError.notSignedIn }
        guard amount > 0 else { throw GoalsRepoError.invalidAmount }

        let goalRef = FirestorePaths.goal(uid: uid, goalId: goalId)
        let txRef = FirestorePaths.transactions(uid: uid, goalId: goalId).document()

        let delta: Int
        switch type {
        case "deposit":    delta = amount
        case "withdraw":   delta = -amount
        default:           delta = amount
        }

        // Record the transaction document.
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            txRef.setData([
                "type": type,
                "amount": amount,
                "note": note as Any,
                "challengeId": challengeId as Any,
                "createdAt": FieldValue.serverTimestamp()
            ]) { error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }

        // Atomically increment the goal balance.
        // FieldValue.increment writes to the local Firestore cache immediately
        // (as a pending write), which fires the snapshot listener right away —
        // so the UI updates instantly without a server round-trip.
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            goalRef.updateData([
                "currentAmount": FieldValue.increment(Int64(delta)),
                "updatedAt": FieldValue.serverTimestamp()
            ]) { error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }
    }

    func fetchActiveGoalId() async throws -> String? {
        let goal = try await fetchActiveGoal()
        return goal?.id
    }

    /// Возвращает ID всех целей пользователя (не только активной).
    /// Используется в StatsService для агрегации транзакций по всем целям.
    func fetchAllGoalIds() async throws -> [String] {
        guard let uid else { throw GoalsRepoError.notSignedIn }
        let snap = try await FirestorePaths.goals(uid: uid).getDocuments()
        return snap.documents.map { $0.documentID }
    }

    /// Депозиты с `createdAt >= startDate` (только `type == deposit`, положительные суммы).
    func fetchDepositsSince(goalId: String, startDate: Date) async throws -> [(date: Date, amount: Int)] {
        guard let uid else { throw GoalsRepoError.notSignedIn }

        let snapshot = try await FirestorePaths.transactions(uid: uid, goalId: goalId)
            .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .order(by: "createdAt", descending: false)
            .getDocuments()

        var result: [(date: Date, amount: Int)] = []
        result.reserveCapacity(snapshot.documents.count)

        for doc in snapshot.documents {
            let data = doc.data()
            guard (data["type"] as? String) == "deposit" else { continue }

            let amount: Int
            if let v = data["amount"] as? Int {
                amount = v
            } else if let v = data["amount"] as? Int64 {
                amount = Int(v)
            } else if let v = data["amount"] as? NSNumber {
                amount = v.intValue
            } else {
                continue
            }
            guard amount > 0, let ts = data["createdAt"] as? Timestamp else { continue }

            result.append((ts.dateValue(), amount))
        }

        return result
    }
}
