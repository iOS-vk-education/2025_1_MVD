//
//  SeriesCardView.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 20.11.2025.
//

import SwiftUI

struct SeriesCardView: View {
    let weeklySavings: Double
    let remainingAmount: Double
    let streakDays: Int
    let weekProgress: [Bool]
    
    var body: some View {
        CardView(
            viewModel: CardViewModel(
                cardName: "Карточка серии",
                mainText: "На этой неделе накопили \(weeklySavings.formatted(.rub()))",
                subtitle: "Осталось всего \(remainingAmount.formatted(.rub()))",
                borderColor: .orange,
                hasBorder: true
            ),
            content: {
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { day in
                        Circle()
                            .fill(weekProgress[day] ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text("\(day + 1)")
                                    .font(.caption2)
                                    .foregroundColor(weekProgress[day] ? .white : .gray)
                            )
                    }
                }
                .padding(.vertical, 4)
            },
            imageContent: {
                VStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                    
                    Text("\(streakDays)")
                        .font(.title)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
            }
        )
    }
}
