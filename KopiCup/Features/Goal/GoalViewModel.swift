import SwiftUI

final class GoalViewModel: ObservableObject {
    @Published var currentGoal: Goal?
    @Published var showAddModal = false
    @Published var showDetailsModal = false
    @Published var showEditModal = false

    private let goalService: GoalService

    init(goalService: GoalService) {
        self.goalService = goalService

        // The Firestore snapshot listener in FirebaseGoalService fires immediately
        // from the local cache when FieldValue.increment writes a pending update —
        // so no optimistic notification is needed here.
        goalService.observeGoal { [weak self] goal in
            Task { @MainActor in self?.currentGoal = goal }
        }
    }

    func createGoal(_ goal: Goal) {
        currentGoal = goal
        goalService.createGoal(goal)
    }

    func updateGoal(_ goal: Goal) {
        currentGoal = goal
        goalService.updateGoal(goal)
    }

    func deleteGoal() {
        currentGoal = nil
        goalService.deleteGoal()
    }

    var progress: Double {
        currentGoal?.progress ?? 0
    }

    var remaining: Int {
        guard let goal = currentGoal else { return 0 }
        return max(goal.targetAmount - goal.currentAmount, 0)
    }
}
