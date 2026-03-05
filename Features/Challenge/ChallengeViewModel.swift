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
    
    func acceptChallenge() {
        guard let c = displayedChallenge else { return }
        challengeService.startChallenge(c)
        showDetailModal = true
    }
    
    func declineActiveChallenge() {
        challengeService.declineChallenge()
        showDetailModal = false
    }
    
    func markToday() {
        challengeService.markDayComplete()
    }
    
    var progressColors: [Color] {
        guard let uc = activeChallenge else { return [] }
        return uc.progress.map { $0 ? Color.green : Color.gray.opacity(0.3) }
    }
}



