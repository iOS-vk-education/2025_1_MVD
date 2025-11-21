import SwiftUI

struct HomeView: View {
    @ObservedObject var userStorage = UserStorage()
    @State private var hasGoal = false // ← Состояние наличия цели
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text("Чудесный день, чтобы начать копить!")
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 25) {
                    if hasGoal {
                        // РЕЖИМ С ВЫБРАННОЙ ЦЕЛЬЮ
                        GoalCardView(
                            goalName: "Новый автомобиль",
                            targetAmount: 1_500_000,
                            currentAmount: 450_000,
                            goalImageName: "car"
                        )
                        SeriesCardView(
                            weeklySavings: 7500,
                            remainingAmount: 2500,
                            streakDays: 5,
                            weekProgress: [true, true, true, true, true, false, false]
                        )
                        ChallengeCardView(
                            challengeName: "Без кофе на этой неделе",
                            difficulty: 2
                        )
                    } else {
                        // РЕЖИМ ПЕРВОГО ЗАХОДА (НЕТ ЦЕЛИ)
                        
                        // Карточка цели (серая, без цели)
                        CardView(
                            cardName: "Пустая цель",
                            mainText: "У вас пока нет цели",
                            subtitle: "Самое время ее добавить",
                            content: {
                                // Пустой контент или прогресс 0%
                                ProgressView(value: 0)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .gray))
                                    .frame(maxWidth: 170)
                                    .scaleEffect(y:4)
                                Spacer()
                            },
                            imageContent: {
                                Image(systemName: "trophy")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            },
                            backgroundColor: .gray.opacity(0.1),
                            foregroundColor: .blue
                        )
                        
                        // Карточка серии (нулевая)
                        CardView(
                            cardName: "Начало серии",
                            mainText: "Вот-вот начнем! Выбери цель",
                            subtitle: nil,
                            content: {
                                HStack(spacing: 8) {
                                    ForEach(0..<7, id: \.self) { day in
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Text("\(day + 1)")
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            )
                                    }
                                }
                                .padding(.vertical, 4)
                            },
                            imageContent: {
                                VStack(spacing: 4) {
                                    Image(systemName: "flame")
                                        .font(.title)
                                        .foregroundColor(.white)
                                    
                                    Text("0")
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                            },
                            foregroundColor: .blue,
                            borderColor: .orange,
                            hasBorder: true
                        )
                        
                        // Карточка добавления цели вместо челленджа
                        CardView(
                            cardName: "Добавление цели",
                            mainText: "О чем ты сейчас мечтаешь?",
                            subtitle: "Иди к твоей цели",
                            content: {
                                Button("Начать копить") {
                                    withAnimation {
                                        hasGoal = true // ← Переключаем на режим с целью
                                    }
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(8)
                            },
                            imageContent: {
                                Image(systemName: "banknote")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            },
                            backgroundColor: .white,
                            foregroundColor: .blue,
                            borderColor: .blue,
                            hasBorder: true
                        )
                    }
                }
                .padding()
                .navigationTitle("Привет, \(userStorage.name)!")
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
