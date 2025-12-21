//
//  ChallengeService.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 16.12.2025.
//

import FirebaseFirestore

struct Challenge {
    let id: String
    let name: String
    let difficulty: Int
}

class ChallengeManager: ObservableObject {
    @Published var currentChallenge: Challenge?
    
    private let db = Firestore.firestore()
    private var challenges: [Challenge] = []
    private var currentIndex = 0
    
    func loadChallenges() {
        db.collection("challenges").getDocuments { snapshot, error in
            if let error = error {
                print("Ошибка загрузки: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("Нет челленджей")
                return
            }
            
            self.challenges = documents.compactMap { doc in
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let difficulty = data["difficult"] as? Int else {
                    return nil
                }
                return Challenge(id: doc.documentID, name: name, difficulty: difficulty)
            }
            
            print("Загружено \(self.challenges.count) челленджей")
            
            if !self.challenges.isEmpty {
                self.currentChallenge = self.challenges[0]
            }
        }
    }
    
    func nextChallenge() {
        guard !challenges.isEmpty else { return }
        
        currentIndex = (currentIndex + 1) % challenges.count
        currentChallenge = challenges[currentIndex]
        
        print("Переключено на: \(currentChallenge?.name ?? "нет")")
    }
}
