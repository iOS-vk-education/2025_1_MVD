import SwiftUI

struct ChallengeCardView: View {
    @ObservedObject var viewModel: ChallengeViewModel
    @EnvironmentObject private var l10n: L10n

    var onAccept: (() -> Void)? = nil
    var onTrackToday: (() -> Void)? = nil

    private let maxDifficulty = 3

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(viewModel.displayedChallenge?.localizedName(for: l10n.language) ?? l10n.t(.challengeNone))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.isAccepted ? .white : .primary)

                        let diff = clampDifficulty(viewModel.displayedChallenge?.difficulty ?? 0)
                        HStack(spacing: 2) {
                            ForEach(0..<maxDifficulty, id: \.self) { i in
                                Image(systemName: i < diff ? "bolt.fill" : "bolt")
                                    .font(.headline)
                                    .foregroundColor((viewModel.isAccepted ? Color.white : Color.blue).opacity(i < diff ? 1.0 : 0.35))
                            }
                        }
                        .accessibilityLabel(l10n.t(.challengeDifficulty, diff, maxDifficulty))
                    }

                    Text(viewModel.displayedChallenge?.localizedDescription(for: l10n.language) ?? "")
                        .font(.subheadline)
                        .foregroundColor(viewModel.isAccepted ? Color.white.opacity(0.9) : .secondary)
                }
                Spacer()
            }

            if viewModel.isAccepted {
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { day in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                viewModel.progressColors.indices.contains(day)
                                ? viewModel.progressColors[day]
                                : Color.gray.opacity(0.6)
                            )
                            .frame(height: 8)
                    }
                }

                Button(action: { onTrackToday?() }) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle")
                            .font(.headline)
                        Text(l10n.t(.challengeTrackToday))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.95))
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            } else {
                HStack(spacing: 12) {
                    Button(l10n.t(.challengeAccept)) {
                        onAccept?()
                    }
                    .buttonStyle(ActionButtonStyle(variant: .primary))

                    Button(action: { withAnimation { viewModel.nextChallenge() } }) {
                        HStack(spacing: 4) {
                            Text(l10n.t(.challengeNext))
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .buttonStyle(ActionButtonStyle(variant: .secondary))
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 12)
        .cardStyle(
            viewModel.isAccepted
            ? .default.with(backgroundColor: .blue, foregroundColor: .white)
            : .default.with(foregroundColor: .blue, borderColor: .blue, borderWidth: 5)
        )
    }

    private func clampDifficulty(_ value: Int) -> Int {
        max(0, min(value, maxDifficulty))
    }
}
