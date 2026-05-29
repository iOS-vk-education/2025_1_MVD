//
//  ChallengeDetailsView.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI

struct ChallengeDetailView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ChallengeViewModel
    @EnvironmentObject private var l10n: L10n
    @State private var showDeclineAlert = false
    @State private var highlightTick = false

    private var challenge: Challenge? { viewModel.displayedChallenge }

    // Максимальное число "болтов" сложности
    private let maxDifficulty = 3
    private var difficultyCount: Int {
        let value = challenge?.difficulty ?? 0
        return Swift.max(0, Swift.min(value, maxDifficulty))
    }

    // Период 7 дней начиная с даты принятия челленджа (или с сегодня, если ещё не принят).
    private var periodText: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d.MM"
        let start = viewModel.activeChallenge?.startDate ?? Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start
        return "\(fmt.string(from: start)) - \(fmt.string(from: end))"
    }

    // Порядковый индекс сегодняшнего дня в челлендже (0 = день принятия, 1 = следующий, …).
    // nil — если челлендж истёк (>6 дней).
    private var currentDayIndex: Int? {
        guard let uc = viewModel.activeChallenge else { return 0 }
        let idx = uc.currentDayIndex
        return (0...6).contains(idx) ? idx : nil
    }

    private var isTodayAlreadyMarked: Bool {
        viewModel.activeChallenge?.isTodayCompleted ?? false
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                // Синий фон на всю область всплывающего окна
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.75)]),
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Шапка на синем фоне
                    headerContent
                        .padding(.top, 30)

                    // Контентная карточка (без minHeight, чтобы не раздувать белый фон)
                    VStack(alignment: .leading, spacing: 12) {
                        // Заголовок секции периода — по центру
                        Text(l10n.t(.challengeDetailPeriod))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 10)

                        // Период в рамке с иконкой — по центру
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundColor(.primary)
                            Text(periodText)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color(UIColor.systemGray6))
                                )
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)

                        // Прогресс
                        VStack(spacing: 8) {
                            Text(l10n.t(.challengeDetailProgress))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)

                            HStack(spacing: 10) {
                                ForEach(0..<7, id: \.self) { i in
                                    ZStack {
                                        Circle()
                                            .fill(circleColor(for: i))
                                            .frame(width: 36, height: 36)
                                        Text("\(i+1)")
                                            .foregroundColor(.white)
                                            .fontWeight(.semibold)
                                    }
                                    .animation(.easeInOut(duration: 0.2), value: highlightTick)
                                }
                            }
                            .padding(.horizontal, 8)
                        }
                        .padding(.bottom, 4)

                        // Кнопка "Отметить сегодня"
                        Button(action: {
                            viewModel.markToday()
                            isPresented = false
                        }) {
                            Text(isTodayAlreadyMarked ? l10n.t(.challengeDetailMarkedToday) : l10n.t(.challengeDetailMarkToday))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isTodayAlreadyMarked ? Color.gray : Color.green)
                                .cornerRadius(12)
                        }
                        .disabled(isTodayAlreadyMarked)
                        .padding(.horizontal, 16)

                        // Кнопка "Отказаться от челленджа"
                        Button(action: { showDeclineAlert = true }) {
                            Text(l10n.t(.challengeDetailDecline))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                    .padding(.vertical, 16)
                    .background(Color(UIColor.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 12)

                    Spacer(minLength: 0)
                }
                // Высота окна ограничена доступной высотой экрана
                .frame(maxHeight: geo.size.height, alignment: .top)

                // Крестик закрытия
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(14)
                }
                .padding(.top, 8)
                .padding(.trailing, 8)
            }
        }
        .onAppear { highlightTick.toggle() }
        .alert(l10n.t(.challengeDetailDeclineConfirm), isPresented: $showDeclineAlert) {
            Button(l10n.t(.challengeDetailDeclineAction), role: .destructive) {
                viewModel.declineActiveChallenge()
                isPresented = false
            }
            Button(l10n.t(.cancel), role: .cancel) { }
        }
    }

    private var headerContent: some View {
        VStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 36))
                .foregroundColor(.white)

            Text(challenge?.localizedName(for: l10n.language) ?? l10n.t(.challengeFallbackName))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // Болты сложности
            HStack(spacing: 6) {
                ForEach(0..<maxDifficulty, id: \.self) { i in
                    Image(systemName: i < difficultyCount ? "bolt.fill" : "bolt")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(i < difficultyCount ? 1.0 : 0.35))
                }
            }
            .padding(.top, 2)

            Text(challenge?.localizedDescription(for: l10n.language) ?? "")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 16)
        }
    }

    private func circleColor(for index: Int) -> Color {
        // выполненный — зеленый; текущий день — синий; иначе — серый
        if let progress = viewModel.activeChallenge?.progress,
           progress.indices.contains(index),
           progress[index] {
            return .green
        }
        if let current = currentDayIndex, current == index {
            return .blue
        }
        return Color.gray.opacity(0.35)
    }
}
