import SwiftUI
import FirebaseAuth

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

    @State private var showChallengeDetails: Bool = false
    @State private var showPigModal: Bool = false

    // Баннеры и достижения — живут на главном экране
    @StateObject private var rewardBannerCenter = RewardBannerCenter()
    @StateObject private var achievementsVM = AchievementsViewModel()

    @EnvironmentObject private var economy: EconomyStore
    @EnvironmentObject private var l10n: L10n

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

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
        ZStack(alignment: .top) {
            NavigationView {
                VStack(spacing: 0) {
                    topEconomyBar
                        .padding(.horizontal, 0)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {

                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .center, spacing: 12) {
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
                                    .accessibilityLabel(l10n.t(.openPiggy))

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(l10n.t(.homeGreeting, viewModel.userName))
                                            .font(.system(size: 30, weight: .bold, design: .rounded))
                                            .foregroundColor(Color(red: 102/255, green: 190/255, blue: 0))

                                        Text(l10n.t(.keepGoing))
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
                        .padding(.bottom, 32)
                    }
                }
                .navigationBarHidden(true)
                // Модалка по кнопке со свиньёй
                .sheet(isPresented: $showPigModal) {
                    PiggyModalView(isPresented: $showPigModal)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.hidden)
                }
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
                .sheet(isPresented: $showChallengeDetails) {
                    ChallengeDetailView(
                        isPresented: $showChallengeDetails,
                        viewModel: viewModel.challengeVM
                    )
                    .presentationDetents([.height(520)])
                    .presentationDragIndicator(.hidden)
                }
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

                // Конфиг достижений для мгновенных баннеров на главном
                achievementsVM.setEconomyStore(economy)
                achievementsVM.setUid(Auth.auth().currentUser?.uid)
            }
            .alert(l10n.t(.challengeFailed), isPresented: Binding(
                get: { viewModel.challengeVM.showFailedChallengeAlert },
                set: { viewModel.challengeVM.showFailedChallengeAlert = $0 }
            )) {
                Button(l10n.t(.tryAgain), role: .cancel) { }
            } message: {
                Text(l10n.t(.challengeFailedMsg, viewModel.challengeVM.failedChallengeName))
            }
            .alert(l10n.t(.challengeCompleted), isPresented: Binding(
                get: { viewModel.challengeVM.showCompletedChallengeAlert },
                set: { viewModel.challengeVM.showCompletedChallengeAlert = $0 }
            )) {
                Button(l10n.t(.ok), role: .cancel) { }
            } message: {
                Text(l10n.t(
                    .challengeCompletedMsg,
                    viewModel.challengeVM.completedChallengeName,
                    viewModel.challengeVM.completedChallengeDays
                ))
            }

            // Баннер наград/достижений
            if let data = rewardBannerCenter.currentBanner {
                RewardToastView(data: data)
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var topEconomyBar: some View {
        HStack(spacing: 12) {
            counterChip(systemName: "dollarsign.circle.fill", value: economy.coins)
            counterChip(systemName: "trophy.fill", value: economy.trophies)

            Spacer()

            Button {
                Task {
                    let _ = await economy.collectDailyGift()
                }
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

    init(_ radius: CGFloat) {
        self.radius = radius
    }

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
