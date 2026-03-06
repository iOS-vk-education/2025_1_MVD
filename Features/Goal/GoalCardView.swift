import SwiftUI

struct GoalCardView: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(goal.title)
                .font(.headline)

            if !goal.description.isEmpty {
                Text(goal.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: goal.progress)
                .padding(.top, 4)

            HStack {
                Text("Собрано: \(formatMoney(goal.currentAmount, currency: goal.currency))")
                Spacer()
                Text("Цель: \(formatMoney(goal.targetAmount, currency: goal.currency))")
            }
            .font(.footnote)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
