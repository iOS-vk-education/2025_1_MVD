import SwiftUI

final class GoalViewModel: ObservableObject {
    @Published var currentGoal: Goal?
    @Published var showAddModal = false
    @Published var showDetailsModal = false
    @Published var showEditModal = false

    private let goalService: GoalService

    init(goalService: GoalService) {
        self.goalService = goalService
        goalService.observeGoal { [weak self] goal in
            DispatchQueue.main.async { self?.currentGoal = goal }
        }
    }

    func createGoal(_ goal: Goal) { goalService.createGoal(goal) }
    func updateGoal(_ goal: Goal) { goalService.updateGoal(goal) }
    func deleteGoal() { goalService.deleteGoal() }

    var progress: Double {
        currentGoal?.progress ?? 0
    }

    var remaining: Int {
        guard let goal = currentGoal else { return 0 }
        return max(goal.targetAmount - goal.currentAmount, 0)
    }
}
