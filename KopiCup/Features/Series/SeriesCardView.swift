import SwiftUI

struct SeriesCardView: View {
    @ObservedObject var viewModel: SeriesViewModel
    @EnvironmentObject private var l10n: L10n
    @State private var showNoGoalAlert = false

    private var weekDays: [String] {
        [l10n.t(.mon), l10n.t(.tue), l10n.t(.wed),
         l10n.t(.thu), l10n.t(.fri), l10n.t(.sat), l10n.t(.sun)]
    }

    private var isPresentedBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showAddMoneyModal },
            set: { viewModel.showAddMoneyModal = $0 }
        )
    }

    private let cardColor: Color = Color(red: 102/255, green: 190/255, blue: 0)
    private var todayIndex: Int { viewModel.currentDayIndex }

    private func dayTextColor(_ id: Int) -> Color {
        viewModel.isToday(dayIndex: id) ? cardColor : .secondary
    }

    private func dayTextWeight(_ id: Int) -> Font.Weight {
        viewModel.isToday(dayIndex: id) ? .bold : .regular
    }

    private func dayFillColor(_ id: Int) -> Color {
        viewModel.isDayCompleted(id) ? cardColor : Color.gray.opacity(0.3)
    }

    private func dayRingColor(_ id: Int) -> Color {
        viewModel.isToday(dayIndex: id) ? cardColor : .clear
    }

    private func dayOpacity(_ id: Int) -> Double {
        viewModel.dateForDisplayedWeek(dayIndex: id) > Date() ? 0.45 : 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.t(.seriesWeeklySaved, viewModel.formatWithCurrentCurrency(viewModel.totalSavedThisWeek)))
                    Text(viewModel.weekRangeText)
                        .font(.subheadline)
                    Text(l10n.t(.seriesKeepGoing))
                }
                .font(.headline)
                .foregroundColor(cardColor)

                Spacer()

                HStack(spacing: 6) {
                    Button {
                        viewModel.showPreviousWeek()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.showCurrentWeek()
                    } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.showNextWeek()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canShowNextWeek)
                    .opacity(viewModel.canShowNextWeek ? 1 : 0.35)
                }
                .foregroundColor(cardColor)
                .frame(height: 30)
            }
            .padding(.bottom, 2)

            HStack(alignment: .center, spacing: 12) {
                VStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(cardColor)
                        .font(.system(size: 18, weight: .semibold))
                    Text("\(viewModel.savedDaysCount)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(cardColor)
                }
                .frame(width: 36)

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(0..<7, id: \.self) { dayIndex in
                                VStack(spacing: 4) {
                                    Text(weekDays[dayIndex])
                                        .font(.caption2)
                                        .fontWeight(dayTextWeight(dayIndex))
                                        .foregroundColor(dayTextColor(dayIndex))

                                    Circle()
                                        .fill(dayFillColor(dayIndex))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(dayRingColor(dayIndex), lineWidth: 2)
                                        )
                                        .overlay(
                                            Group {
                                                if viewModel.amountForDisplayedWeek(dayIndex: dayIndex) > 0 {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 11, weight: .bold))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                        )
                                        .onTapGesture {
                                            guard viewModel.canAddMoney(dayIndex: dayIndex) else { return }
                                            guard viewModel.goal != nil else {
                                                showNoGoalAlert = true
                                                return
                                            }
                                            viewModel.selectedDate = viewModel.dateForDisplayedWeek(dayIndex: dayIndex)
                                            viewModel.showAddMoneyModal = true
                                        }
                                }
                                .padding(.vertical, 2)
                                .opacity(dayOpacity(dayIndex))
                                .id(dayIndex)
                            }
                        }
                        .padding(.horizontal, 2)
                        .padding(.vertical, 2)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            proxy.scrollTo(todayIndex, anchor: .leading)
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .cardStyle(
            CardAppearance.default
                .with(
                    foregroundColor: cardColor,
                    borderColor: cardColor,
                    borderWidth: 5
                )
        )
        .sheet(isPresented: isPresentedBinding) {
            AddMoneyView(
                isPresented: isPresentedBinding,
                viewModel: viewModel
            )
        }
        .alert(l10n.t(.seriesNoGoal), isPresented: $showNoGoalAlert) {
            Button(l10n.t(.ok), role: .cancel) { }
        }
    }
}
