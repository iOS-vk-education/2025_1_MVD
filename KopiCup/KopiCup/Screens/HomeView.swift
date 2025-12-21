import SwiftUI

struct HomeView: View {
    @ObservedObject var userStorage = UserStorage()
    @StateObject private var challengeManager = ChallengeManager()
    @State private var hasGoal = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text("Чудесный день, чтобы начать копить!")
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 25) {
                    if hasGoal {
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
                        
                        if let challenge = challengeManager.currentChallenge {
                            ChallengeCardView(
                                challenge: challenge,
                                onDecline: {
                                    challengeManager.nextChallenge()
                                }
                            )
                        }
                    } else {
                        CardView(
                            viewModel: CardViewModel(
                                cardName: "Пустая цель",
                                mainText: "У вас пока нет цели",
                                subtitle: "Самое время ее добавить",
                                backgroundColor: Color.gray.opacity(0.1),
                                foregroundColor: .blue
                            ),
                            content: {
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
                            }
                        )
                        
                        CardView(
                            viewModel: CardViewModel(
                                cardName: "Начало серии",
                                mainText: "Вот-вот начнем! Выбери цель",
                                subtitle: nil,
                                foregroundColor: .blue,
                                borderColor: .orange,
                                hasBorder: true
                            ),
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
                            }
                        )
                        
                        CardView(
                            viewModel: CardViewModel(
                                cardName: "Добавление цели",
                                mainText: "О чем ты сейчас мечтаешь?",
                                subtitle: "Иди к твоей цели",
                                backgroundColor: .white,
                                foregroundColor: .blue,
                                borderColor: .blue,
                                hasBorder: true
                            ),
                            content: {
                                Button("Начать копить") {
                                    withAnimation {
                                        hasGoal = true
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
                            }
                        )
                    }
                }
                .padding()
                .navigationTitle("Привет, \(userStorage.name)!")
            }
        }
        .onAppear {
                    if hasGoal {
                        challengeManager.loadChallenges()
                    }
                }
                .onChange(of: hasGoal) { newValue in
                    if newValue {
                        challengeManager.loadChallenges()
                    } else {
                        challengeManager.currentChallenge = nil
                    }
                }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
