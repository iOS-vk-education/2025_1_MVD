import Foundation

struct UserProfile: Codable {
    let uid: String
    var name: String
    var goalTitle: String
    var targetAmount: Int
    var goalImageURL: String?
    var onboardingCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
}
