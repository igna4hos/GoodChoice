import Foundation

struct UserAccount: Identifiable, Hashable {
    let id: UUID
    var firstName: String
    var lastName: String
    var tier: SubscriptionTier
    var preferredLanguage: AppLanguage
    var monthlyScanLimit: Int?
    var accountSummaryKey: String
    var profiles: [UserProfile]
    var activeProfileID: UUID
}
