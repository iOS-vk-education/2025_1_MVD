import SwiftUI

private let kopiGreen = Color(red: 102/255, green: 190/255, blue: 0)

struct GoalCardView: View {
    let goal: Goal

    private var hasPhoto: Bool {
        guard let url = goal.imageURL else { return false }
        return !url.isEmpty
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(goal.title)
                    .font(.headline)
                    .foregroundColor(.white)

                if !goal.description.isEmpty {
                    Text(goal.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }

                progressBar
                    .padding(.top, 2)

                HStack {
                    Text("Собрано: \(formatMoney(goal.currentAmount, currency: goal.currency))")
                    Spacer()
                    Text("Цель: \(formatMoney(goal.targetAmount, currency: goal.currency))")
                }
                .font(.footnote)
                .foregroundColor(.white.opacity(0.85))
            }

            if hasPhoto, let urlString = goal.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    default:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 80, height: 80)
                    }
                }
            }
        }
        .padding(16)
        .background(kopiGreen)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 80/255, green: 155/255, blue: 0), lineWidth: 5)
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 80/255, green: 155/255, blue: 0))
                .offset(y: 5)
        )
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.35))
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white)
                    .frame(width: geo.size.width * CGFloat(min(max(goal.progress, 0), 1)), height: 6)
            }
        }
        .frame(height: 6)
    }

    private func formatMoney(_ minorUnits: Int, currency: String) -> String {
        let value = Double(minorUnits) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
