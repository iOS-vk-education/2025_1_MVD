import SwiftUI

struct ChallengeCardView: View {
    @ObservedObject var viewModel: ChallengeViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(viewModel.displayedChallenge?.name ?? "Нет челленджа").font(.headline).fontWeight(.semibold)
                        if !viewModel.isAccepted, let diff = viewModel.displayedChallenge?.difficulty {
                            HStack(spacing: 2) {
                                ForEach(0..<diff, id: \.self) { _ in Image(systemName: "bolt.fill").font(.headline).foregroundColor(.blue) }
                            }
                        }
                    }
                    Text(viewModel.displayedChallenge?.description ?? "").font(.subheadline)
                }
                Spacer()
            }
            Spacer()
            
            if viewModel.isAccepted {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { day in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(viewModel.progressColors.indices.contains(day) ? viewModel.progressColors[day] : Color.gray.opacity(0.3))
                                .frame(height: 8)
                        }
                    }
                    Button("Подробнее") { viewModel.showDetailModal = true }
                        .font(.caption).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 4)
                        .background(Color.blue.opacity(0.7)).cornerRadius(12).padding(.top, 4)
                }
            } else {
                HStack(spacing: 12) {
                    Button("Принимаю") { viewModel.acceptChallenge() }
                        .buttonStyle(ActionButtonStyle(variant: .primary))
                    Button(action: { withAnimation { viewModel.nextChallenge() } }) {
                        HStack(spacing: 4) { Text("Другой"); Image(systemName: "arrow.clockwise") }
                    }
                    .buttonStyle(ActionButtonStyle(variant: .secondary))
                }
            }
        }
        .cardStyle(viewModel.isAccepted ? .default.with(backgroundColor: .blue, foregroundColor: .white) : .default.with(foregroundColor: .blue, borderColor: .blue, borderWidth: 5))
    }
}


