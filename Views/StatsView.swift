//
//  StatsView.swift
//  KopiCup
//

import SwiftUI

struct StatsView: View {
    @State private var selectedChartPage: Int = 0

    // Данные для экрана (заглушкиё позже подключить GoalService/DailyAmountService)
    private let weekTotal: Int = 2000
    private let monthTotal: Int = 8000
    private let avgPerDay: Int = 210
    private let weekValues: [Double] = [130, 220, 280, 80, 200, 190, 190]
    private let monthValues: [Double] = [4000, 5200, 4800, 6100, 7200, 8000]
    private let monthLabels: [String] = ["Окт", "Нояб", "Дек", "Янв", "Фев", "Март"]
    private let radarValues: [Double] = [67, 85, 45, 72, 90] // Дисциплина, Планирование, Дружба, Активность, Мотивация

    private let chartsCarouselHeight: CGFloat = 300

    private var cardAppearance: CardAppearance {
        CardAppearance.default
            .with(
                foregroundColor: .primary,
                borderColor: .green,
                borderWidth: 2
            )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                summaryCardsSection
                chartsCarouselSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Статистика")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text("Отслеживайте свои накопления")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var summaryCardsSection: some View {
        HStack(spacing: 12) {
            SummaryCard(title: "Эта неделя", value: weekTotal)
            SummaryCard(title: "Этот месяц", value: monthTotal)
            SummaryCard(title: "Ср. / день", value: avgPerDay)
        }
    }

    private var chartsCarouselSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            TabView(selection: $selectedChartPage) {
                chartPage(
                    title: "Накопления за неделю",
                    content: WeeklySavingsBarChart(values: weekValues)
                )
                .tag(0)
                chartPage(
                    title: "Динамика по месяцам",
                    content: MonthlyDynamicsLineChart(values: monthValues, monthLabels: monthLabels)
                )
                .tag(1)
                chartPage(
                    title: "Сильные и слабые стороны",
                    content: StatsRadarChart(values: radarValues)
                )
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: chartsCarouselHeight)

            pageIndicator
                .padding(.top, 12)
                .padding(.bottom, 4)
        }
        .cardStyle(cardAppearance)
    }

    private func chartPage<Content: View>(title: String, content: Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index == selectedChartPage ? Color.primary : Color.primary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(CurrencyFormatter.format(Double(value)))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green, lineWidth: 2)
        )
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
