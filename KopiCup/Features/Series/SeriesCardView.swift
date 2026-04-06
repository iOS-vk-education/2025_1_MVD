import SwiftUI

struct DayItem: Identifiable {
    let id: Int
    let name: String
}

struct SeriesCardView: View {
    @ObservedObject var viewModel: SeriesViewModel
    @State private var showNoGoalAlert = false

    private let weekDays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    private var days: [DayItem] {
        weekDays.enumerated().map { DayItem(id: $0.offset, name: $0.element) }
    }

    private var isPresentedBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showAddMoneyModal },
            set: { viewModel.showAddMoneyModal = $0 }
        )
    }
    
    private let cardColor: Color = .green

    private var todayIndex: Int { viewModel.currentDayIndex }

    private func dayTextColor(_ id: Int) -> Color {
        id == todayIndex ? cardColor : .secondary
    }

    private func dayTextWeight(_ id: Int) -> Font.Weight {
        id == todayIndex ? .bold : .regular
    }

    private func dayFillColor(_ id: Int) -> Color {
        viewModel.isDayCompleted(id) ? cardColor : Color.gray.opacity(0.3)
    }

    private func dayRingColor(_ id: Int) -> Color {
        id == todayIndex ? cardColor : .clear
    }
    

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("На этой неделе накоплено:\n \(viewModel.formatWithCurrentCurrency(viewModel.totalSavedThisWeek))")
                Text("Так держать!")
            }
            .font(.headline)
            .foregroundColor(.green)
            .padding(.bottom, 2)

            HStack(alignment: .center, spacing: 12) {
                VStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 18, weight: .semibold))
                    Text("\(viewModel.savedDaysCount)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.green)
                }
                .frame(width: 36)

                HStack(spacing: 8) {
                    ForEach(days) { item in
                        VStack(spacing: 4) {
                            Text(item.name)
                                .font(.caption2)
                                .fontWeight(dayTextWeight(item.id))
                                .foregroundColor(dayTextColor(item.id))
                                .brightness(item.id == todayIndex ? -0.1 : 0)

                            Circle()
                                .fill(dayFillColor(item.id))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(dayRingColor(item.id), lineWidth: 2)
                                        .brightness(item.id == todayIndex ? -0.1 : 0)
                                )
                                .onTapGesture {
                                    if viewModel.goal == nil {
                                        showNoGoalAlert = true
                                    } else {
                                        viewModel.selectedDayIndex = nil
                                        viewModel.showAddMoneyModal = true
                                    }
                                }
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
                    foregroundColor: .green,
                    borderColor: .green,
                    borderWidth: 5
                )
        )
        .sheet(isPresented: isPresentedBinding) {
            AddMoneyView(
                isPresented: isPresentedBinding,
                viewModel: viewModel
            )
        }
        .alert("Сначала добавьте цель!", isPresented: $showNoGoalAlert) {
            Button("Ок", role: .cancel) { }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        (startIndex..<endIndex).contains(index) ? self[index] : nil
    }
}
