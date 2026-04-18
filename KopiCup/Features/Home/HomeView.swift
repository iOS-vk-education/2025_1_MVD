import SwiftUI

enum HomeModal: Identifiable {
    case addGoal
    case goalDetails
    case editGoal
    case challengeDetails

    var id: String { String(describing: self) }
}

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @State private var activeModal: HomeModal?
    @State private var goalSnapshot: Goal?

    // Новый стейт для окна деталей челленджа
    @State private var showChallengeDetails: Bool = false

    // Новый стейт для модалки по кнопке со свиньёй
    @State private var showPigModal: Bool = false

    @EnvironmentObject private var economy: EconomyStore

    private var isGoalDetailsPresented: Binding<Bool> {
        Binding(
            get: { activeModal == .goalDetails },
            set: { newValue in
                if !newValue { activeModal = nil }
            }
        )
    }

    private var nonGoalDetailsModal: Binding<HomeModal?> {
        Binding(
            get: { activeModal == .goalDetails ? nil : activeModal },
            set: { activeModal = $0 }
        )
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Верхняя зелёная панель со счётчиками и подарком
                    topEconomyBar
                        .padding(.horizontal, 0)

                    // Заголовок с круглой зелёной кнопкой слева и приветствием
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .center, spacing: 12) {
                            // Кнопка с копилкой/свиньёй (текущий выбранный наряд)
                            Button {
                                showPigModal = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 102/255, green: 190/255, blue: 0))
                                        .frame(width: 60, height: 60)
                                    Image(economy.selectedOutfitImageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 70, height: 80)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Открыть копилку")

                            // Тексты: приветствие и подзаголовок
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Привет, \(viewModel.userName)!")
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 102/255, green: 190/255, blue: 0))
                                
                                Text("Продолжай в том же духе!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 16) {

                        if let goal = viewModel.goalVM.currentGoal {
                            GoalCardView(goal: goal)
                                .onTapGesture {
                                    goalSnapshot = goal
                                    activeModal = .goalDetails
                                }
                        } else {
                            EmptyGoalCardView {
                                activeModal = .addGoal
                            }
                        }

                        if let seriesVM = viewModel.seriesVM {
                            SeriesCardView(viewModel: seriesVM)
                        }

                        if viewModel.challengeVM.displayedChallenge != nil {
                            ChallengeCardView(
                                viewModel: viewModel.challengeVM,
                                onAccept: { showChallengeDetails = true },
                                onTrackToday: { showChallengeDetails = true }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 12)
            }
            // Модалка по кнопке со свиньёй
            .sheet(isPresented: $showPigModal) {
                PiggyModalView(isPresented: $showPigModal)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            // Первый лист — для всех модалок, КРОМЕ goalDetails
            .sheet(item: nonGoalDetailsModal) { modal in
                switch modal {
                case .addGoal:
                    GoalFormView(
                        isPresented: .constant(true),
                        onSave: { viewModel.goalVM.createGoal($0) }
                    )

                case .editGoal:
                    Group {
                        if let goal = viewModel.goalVM.currentGoal {
                            EditGoalView(
                                isPresented: .constant(true),
                                goal: goal,
                                onSave: { viewModel.goalVM.updateGoal($0) },
                                onDelete: { viewModel.goalVM.deleteGoal() }
                            )
                        } else {
                            EmptyView()
                        }
                    }

                case .challengeDetails:
                    ChallengeDetailView(
                        isPresented: .constant(true),
                        viewModel: viewModel.challengeVM
                    )

                case .goalDetails:
                    EmptyView()
                }
            }
            // Отдельный лист для деталей челленджа, открывается ТОЛЬКО по кнопке "Принимаю" (и "Отмечайте свои успехи сегодня")
            .sheet(isPresented: $showChallengeDetails) {
                ChallengeDetailView(
                    isPresented: $showChallengeDetails,
                    viewModel: viewModel.challengeVM
                )
                .presentationDetents([.height(520)])     // уменьшенная высота
                .presentationDragIndicator(.hidden)         // по желанию, убрать “ползунок”
            }
            // Отдельный лист для деталей цели
            .sheet(isPresented: isGoalDetailsPresented) {
                ZStack {
                    Color(UIColor.systemBackground).ignoresSafeArea()
                    Group {
                        if let goal = goalSnapshot {
                            if let seriesVM = viewModel.seriesVM {
                                AboutGoalView(
                                    goal: goal,
                                    onClose: {
                                        goalSnapshot = nil
                                        activeModal = nil
                                    },
                                    seriesVM: seriesVM,
                                    onAddMoney: {
                                        let goalToUse = goal
                                        goalSnapshot = nil
                                        activeModal = nil
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                            seriesVM.goal = goalToUse
                                            seriesVM.selectedDayIndex = seriesVM.currentDayIndex
                                            seriesVM.showAddMoneyModal = true
                                        }
                                    },
                                    onEdit: {
                                        goalSnapshot = nil
                                        activeModal = nil
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                            activeModal = .editGoal
                                        }
                                    }
                                )
                            } else {
                                VStack(spacing: 12) {
                                    ProgressView()
                                    Text("Готовим стрик…").foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        } else {
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Загружаем цель…").foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
                .interactiveDismissDisabled(false)
                .presentationDetents([.large])
                .modifier(PresentationCornerRadiusCompat(16))
                .onDisappear { goalSnapshot = nil }
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }

    // MARK: - Top bar with counters and gift

    private var topEconomyBar: some View {
        HStack(spacing: 12) {
            counterChip(systemName: "dollarsign.circle.fill", value: economy.coins)
            counterChip(systemName: "trophy.fill", value: economy.trophies)

            Spacer()

            Button {
                let _ = economy.collectDailyGift()
            } label: {
                Image(systemName: "gift.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(economy.isGiftAvailableToday ? 0.2 : 0.1))
                    )
            }
            .disabled(!economy.isGiftAvailableToday)
            .buttonStyle(.plain)
            .accessibilityLabel("Ежедневный подарок")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Color(red: 102/255, green: 190/255, blue: 0)
                .ignoresSafeArea(edges: .horizontal)
        )
    }

    private func counterChip(systemName: String, value: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemName)
                .foregroundColor(.white)
            Text("\(value)")
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.15))
        .clipShape(Capsule())
    }
}

private struct PresentationCornerRadiusCompat: ViewModifier {
    let radius: CGFloat
    init(_ radius: CGFloat) { self.radius = radius }
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationCornerRadius(radius)
        } else {
            content
        }
    }
}

private struct PresentationBackgroundClearCompat: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationBackground(.clear)
        } else {
            content
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(
            viewModel: HomeViewModel(
                userService: MockUserService(),
                goalService: MockGoalService(),
                challengeService: MockChallengeService()
            )
        )
        .environmentObject(EconomyStore())
    }
}
