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
                VStack(alignment: .leading, spacing: 24) {
                    Text("Чудесный день, чтобы начать копить!")
                        .font(.title3)
                        .fontWeight(.medium)
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
                            // ВАЖНО: убираем onTapGesture с карточки челленджа,
                            // и используем колбэки из ChallengeCardView
                            ChallengeCardView(
                                viewModel: viewModel.challengeVM,
                                onAccept: { showChallengeDetails = true },
                                onTrackToday: { showChallengeDetails = true }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Привет, \(viewModel.userName)!")
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
                    // Больше не используем через activeModal — управляем отдельным стейтом showChallengeDetails
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
    }
}
