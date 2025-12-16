//
//  GoalCardView.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 20.11.2025.
//

import SwiftUI

struct GoalCardView: View {
    let goalName: String
    let targetAmount: Double
    let currentAmount: Double
    let goalImageName: String
    
    private var progress: Double {
        return currentAmount / targetAmount
    }
    
    private var remainingAmount: Double {
        return targetAmount - currentAmount
    }
    
    var body: some View {
        CardView(
            viewModel: CardViewModel(
                cardName: "Карточка цели",
                mainText: goalName,
                subtitle: "Осталось: \(remainingAmount.formatted(.rub()))",
                backgroundColor: .green,
                foregroundColor: .white
            ),
            content: {
                VStack(alignment: .leading, spacing: 16) {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(maxWidth: 170)
                        .scaleEffect(y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.blue, lineWidth: 0.3)
                                .scaleEffect(y: 4)
                        )
                }
                Spacer()
            },
            imageContent: {
                Image(systemName: goalImageName)
                    .font(.title)
                    .foregroundColor(.white)
            }
        )
    }
}
