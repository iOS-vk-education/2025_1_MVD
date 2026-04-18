//
//  ChallengeViewModel.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI

final class ChallengeViewModel: ObservableObject {
    @Published var activeChallenge: UserChallenge?
    @Published var displayedChallenge: Challenge?
    @Published var showDetailModal = false
    
    private let challengeService: ChallengeService
    private var availableChallenges: [Challenge] = []
    private var currentIndex = 0
    
    init(challengeService: ChallengeService) {
        self.challengeService = challengeService

        challengeService.loadChallenges { [weak self] challenges in
            guard let self else { return }
            self.availableChallenges = challenges

            if self.activeChallenge == nil {
                self.displayedChallenge = challenges.first
            }

            self.challengeService.observeUserChallenge { [weak self] userChallenge in
                DispatchQueue.main.async {
                    self?.activeChallenge = userChallenge
                    if let uc = userChallenge {
                        self?.displayedChallenge = uc.challenge
                    } else {
                        self?.displayedChallenge = self?.availableChallenges.first
                    }
                }
            }
        }
    }
    
    var isAccepted: Bool { activeChallenge != nil }
    
    func nextChallenge() {
        guard !availableChallenges.isEmpty && activeChallenge == nil else { return }
        currentIndex = (currentIndex + 1) % availableChallenges.count
        displayedChallenge = availableChallenges[currentIndex]
    }
    
    // Не стартуем челлендж здесь — только сигнализируем, что нужно открыть окно деталей (если используется).
    func acceptChallenge() {
        showDetailModal = true
    }
    
    func declineActiveChallenge() {
        challengeService.declineChallenge()
        showDetailModal = false
    }
    
    // Если челлендж еще не начат — сначала стартуем его, затем отмечаем сегодняшний день.
    func markToday() {
        if activeChallenge == nil, let c = displayedChallenge {
            challengeService.startChallenge(c)
        }
        challengeService.markDayComplete()
    }
    
    // Ярче «серый» для незавершенных дней
    var progressColors: [Color] {
        guard let uc = activeChallenge else { return [] }
        return uc.progress.map { $0 ? Color.green : Color.gray.opacity(0.6) }
    }
}

