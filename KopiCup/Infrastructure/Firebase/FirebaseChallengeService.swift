import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseChallengeService: ChallengeService, @unchecked Sendable {
    private let localStore: LocalChallengeStore
    private let defaults: UserDefaults
    private let migrationKeyPrefix = "challenge.migrated.v1."
    private let fallbackChallenges: [Challenge] = [
        Challenge(
            id: "1",
            name: "Не покупать кофе",
            description: "Попробуй день без кофе",
            nameEn: "Skip buying coffee",
            descriptionEn: "Try a day without buying coffee",
            difficulty: 1
        ),
        Challenge(
            id: "2",
            name: "Прогулка 5км",
            description: "Ходи пешком",
            nameEn: "5 km walk",
            descriptionEn: "Walk instead of taking transport",
            difficulty: 2
        ),
        Challenge(
            id: "3",
            name: "Без сахара",
            description: "Никаких сладостей",
            nameEn: "No sugar",
            descriptionEn: "Skip sweets for the day",
            difficulty: 3
        )
    ]

    private var challenges: [Challenge] = []
    private var activeState: UserChallengeState?
    private var listener: ListenerRegistration?
    private var handlers: [(UserChallenge?) -> Void] = []

    private var authHandle: AuthStateDidChangeListenerHandle?
    /// UID for which the Firestore listener is currently active. Used to avoid
    /// restarting the listener unnecessarily on repeated auth state callbacks.
    private var listenerUid: String?

    init(
        localStore: LocalChallengeStore = .shared,
        defaults: UserDefaults = .standard
    ) {
        self.localStore = localStore
        self.defaults = defaults

        // Restore locally-cached state so the challenge UI is never blank
        // while the Firestore listener re-establishes after app restart.
        self.activeState = localStore.loadActive()

        // React to logout/login cycles without requiring ChallengeViewModel.init
        // to be called again (the VM persists as @StateObject).
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            if let uid = user?.uid {
                // Skip if we already have an active listener for this user.
                guard self.listenerUid != uid else { return }
                Task {
                    let loaded = await self.loadChallengesCatalog()
                    DispatchQueue.main.async {
                        self.challenges = loaded
                        self.startListening(uid: uid)
                        // Re-publish so the UI reflects the restored state
                        // with the freshly-loaded challenge catalog.
                        self.publishCurrentState()
                    }
                }
            } else {
                // Logged out — stop Firestore listener but keep in-memory state
                // so the challenge isn't wiped mid-session or on re-login.
                self.listener?.remove()
                self.listener = nil
                self.listenerUid = nil
            }
        }
    }

    deinit {
        listener?.remove()
        if let authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
    }

    func loadChallenges(completion: @escaping ([Challenge]) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            let local = fallbackChallenges
            challenges = local
            completion(local)
            publishCurrentState()
            return
        }

        Task {
            let loaded = await loadChallengesCatalog()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.challenges = loaded
                completion(loaded)
                self.startListening(uid: uid)
            }
        }
    }

    func observeUserChallenge(_ handler: @escaping (UserChallenge?) -> Void) {
        handlers.append(handler)
        handler(makeUserChallenge(from: activeState))
    }

    func startChallenge(_ challenge: Challenge) {
        guard let uid = Auth.auth().currentUser?.uid else {
            let state = UserChallengeState(
                challengeId: challenge.id,
                startDate: Date(),
                completedDayKeys: []
            )
            localStore.saveActive(state)
            activeState = state
            publishCurrentState()
            return
        }

        let state = UserChallengeState(
            challengeId: challenge.id,
            startDate: Date(),
            completedDayKeys: []
        )
        activeState = state
        publishCurrentState()

        let payload: [String: Any] = [
            "challengeId": state.challengeId,
            "startDate": Timestamp(date: state.startDate),
            "completedDayKeys": Array(state.completedDayKeys),
            "updatedAt": FieldValue.serverTimestamp(),
            "version": 1
        ]

        FirestorePaths.activeChallengeState(uid: uid).setData(payload, merge: true) { [weak self] error in
            if let error {
                print("startChallenge error:", error)
                self?.localStore.saveActive(state)
            }
        }
    }

    func declineChallenge() {
        guard let uid = Auth.auth().currentUser?.uid else {
            localStore.saveActive(nil)
            activeState = nil
            publishCurrentState()
            return
        }

        localStore.saveActive(nil)
        activeState = nil
        publishCurrentState()

        FirestorePaths.activeChallengeState(uid: uid).delete { error in
            if let error {
                print("declineChallenge error:", error)
            }
        }
    }

    func markDayComplete() {
        guard let state = activeState else { return }
        let dayIndex = DayKey.daysBetween(state.startDate, Date())
        guard (0...6).contains(dayIndex) else { return }

        let todayKey = DayKey.make(from: Date())
        guard !state.completedDayKeys.contains(todayKey) else { return }

        guard let uid = Auth.auth().currentUser?.uid else {
            var updated = state
            updated.completedDayKeys.insert(todayKey)
            localStore.saveActive(updated)
            activeState = updated
            publishCurrentState()
            return
        }

        let doc = FirestorePaths.activeChallengeState(uid: uid)
        doc.updateData([
            "completedDayKeys": FieldValue.arrayUnion([todayKey]),
            "updatedAt": FieldValue.serverTimestamp()
        ]) { [weak self] error in
            if let error {
                print("markDayComplete error:", error)
                guard let self else { return }
                var updated = state
                updated.completedDayKeys.insert(todayKey)
                self.localStore.saveActive(updated)
                self.activeState = updated
                self.publishCurrentState()
            }
        }
    }

    private func loadChallengesCatalog() async -> [Challenge] {
        do {
            let snapshot = try await FirestorePaths.challengesCatalog().getDocuments()
            let parsed = snapshot.documents.compactMap { parseChallenge($0) }
            return parsed.isEmpty ? fallbackChallenges : parsed
        } catch {
            print("loadChallengesCatalog error:", error)
            return fallbackChallenges
        }
    }

    private func parseChallenge(_ doc: QueryDocumentSnapshot) -> Challenge? {
        let data = doc.data()
        let name = data["name"] as? String ?? data["title"] as? String
        let description = data["description"] as? String ?? data["desc"] as? String
        let nameEn = data["nameEn"] as? String ?? data["titleEn"] as? String ?? data["name_en"] as? String ?? data["title_en"] as? String
        let descriptionEn = data["descriptionEn"] as? String ?? data["descEn"] as? String ?? data["description_en"] as? String ?? data["desc_en"] as? String
        let rawDifficulty = data["difficulty"]

        guard let name, let description else { return nil }

        let difficulty: Int
        if let value = rawDifficulty as? Int {
            difficulty = value
        } else if let value = rawDifficulty as? NSNumber {
            difficulty = value.intValue
        } else {
            difficulty = 1
        }

        return Challenge(
            id: doc.documentID,
            name: name,
            description: description,
            nameEn: nameEn,
            descriptionEn: descriptionEn,
            difficulty: max(1, difficulty)
        )
    }

    private func startListening(uid: String) {
        listener?.remove()
        listenerUid = uid

        listener = FirestorePaths.activeChallengeState(uid: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("observeUserChallenge error:", error)
                    self.activeState = self.localStore.loadActive()
                    self.publishCurrentState()
                    return
                }

                guard let snapshot, snapshot.exists, let data = snapshot.data() else {
                    // If the user just logged out, the listener may fire with a
                    // "document doesn't exist" event due to revoked credentials.
                    // Don't wipe state in that case — the logout handler already
                    // stopped the listener for the next auth cycle.
                    guard Auth.auth().currentUser != nil else { return }
                    self.activeState = nil
                    self.localStore.saveActive(nil)
                    self.publishCurrentState()
                    return
                }

                let state = self.parseState(data)
                self.activeState = state
                self.localStore.saveActive(state)
                self.publishCurrentState()
            }

        Task {
            await migrateFromLocalIfNeeded(uid: uid)
        }
    }

    private func parseState(_ data: [String: Any]) -> UserChallengeState? {
        guard
            let challengeId = data["challengeId"] as? String,
            let timestamp = data["startDate"] as? Timestamp
        else {
            return nil
        }

        let completedArray = data["completedDayKeys"] as? [String] ?? []
        return UserChallengeState(
            challengeId: challengeId,
            startDate: timestamp.dateValue(),
            completedDayKeys: Set(completedArray)
        )
    }

    private func migrateFromLocalIfNeeded(uid: String) async {
        let migrationKey = migrationKeyPrefix + uid
        guard !defaults.bool(forKey: migrationKey) else { return }
        guard let localState = localStore.load(uid: uid) else {
            defaults.set(true, forKey: migrationKey)
            return
        }

        do {
            let remoteDoc = FirestorePaths.activeChallengeState(uid: uid)
            let snapshot = try await remoteDoc.getDocument()
            guard !snapshot.exists else {
                defaults.set(true, forKey: migrationKey)
                return
            }

            try await remoteDoc.setData([
                "challengeId": localState.challengeId,
                "startDate": Timestamp(date: localState.startDate),
                "completedDayKeys": Array(localState.completedDayKeys),
                "updatedAt": FieldValue.serverTimestamp(),
                "version": 1
            ], merge: true)

            defaults.set(true, forKey: migrationKey)
        } catch {
            print("challenge migration error:", error)
        }
    }

    private func publishCurrentState() {
        let mapped = makeUserChallenge(from: activeState)
        DispatchQueue.main.async {
            self.handlers.forEach { $0(mapped) }
        }
    }

    private func makeUserChallenge(from state: UserChallengeState?) -> UserChallenge? {
        guard let state else { return nil }
        guard let challenge = challenges.first(where: { $0.id == state.challengeId }) else { return nil }

        // progress[0] = startDate, progress[1] = startDate+1, …, progress[6] = startDate+6.
        // Independent of calendar week — day 0 is always the day the challenge was accepted.
        let progress = (0..<7).map { offset -> Bool in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: state.startDate) ?? state.startDate
            let key = DayKey.make(from: date)
            return state.completedDayKeys.contains(key)
        }

        return UserChallenge(challenge: challenge, startDate: state.startDate, progress: progress)
    }
}
