import Foundation

final class MockProfileService {
    func makeProfiles(referenceDate: Date = .now) -> [UserProfile] {
        let calendar = Calendar.current

        func daysAgo(_ offset: Int, hour: Int) -> Date {
            let shifted = calendar.date(byAdding: .day, value: -offset, to: referenceDate) ?? referenceDate
            return calendar.date(bySettingHour: hour, minute: 15, second: 0, of: shifted) ?? shifted
        }

        return [
            UserProfile(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                nameKey: "user.emma.name",
                subtitleKey: "user.emma.subtitle",
                tier: .free,
                allergies: [.peanuts],
                intolerances: [.lactose],
                avoidedIngredients: [.addedSugar, .fragrance],
                avoidedCategories: [],
                preferredLanguage: .english,
                monthlyScanLimit: 20,
                scanHistory: [
                    ScanRecord(productBarcode: "460100000002", scannedAt: daysAgo(1, hour: 8)),
                    ScanRecord(productBarcode: "460100000003", scannedAt: daysAgo(2, hour: 17)),
                    ScanRecord(productBarcode: "460100000010", scannedAt: daysAgo(3, hour: 9)),
                    ScanRecord(productBarcode: "460100000005", scannedAt: daysAgo(4, hour: 13)),
                    ScanRecord(productBarcode: "460100000008", scannedAt: daysAgo(5, hour: 19)),
                    ScanRecord(productBarcode: "460100000014", scannedAt: daysAgo(7, hour: 8)),
                    ScanRecord(productBarcode: "460100000006", scannedAt: daysAgo(10, hour: 14)),
                    ScanRecord(productBarcode: "460100000019", scannedAt: daysAgo(13, hour: 11))
                ]
            ),
            UserProfile(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                nameKey: "user.daniel.name",
                subtitleKey: "user.daniel.subtitle",
                tier: .free,
                allergies: [.shellfish],
                intolerances: [.gluten],
                avoidedIngredients: [.parabens, .sulfates],
                avoidedCategories: [.cosmetics],
                preferredLanguage: .english,
                monthlyScanLimit: 20,
                scanHistory: [
                    ScanRecord(productBarcode: "460100000011", scannedAt: daysAgo(1, hour: 21)),
                    ScanRecord(productBarcode: "460100000009", scannedAt: daysAgo(3, hour: 10)),
                    ScanRecord(productBarcode: "460100000008", scannedAt: daysAgo(4, hour: 18)),
                    ScanRecord(productBarcode: "460100000016", scannedAt: daysAgo(6, hour: 12)),
                    ScanRecord(productBarcode: "460100000020", scannedAt: daysAgo(9, hour: 8)),
                    ScanRecord(productBarcode: "460100000005", scannedAt: daysAgo(12, hour: 16)),
                    ScanRecord(productBarcode: "460100000018", scannedAt: daysAgo(18, hour: 9))
                ]
            ),
            UserProfile(
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                nameKey: "user.elena.name",
                subtitleKey: "user.elena.subtitle",
                tier: .premium,
                allergies: [.fragrance],
                intolerances: [.lactose],
                avoidedIngredients: [.parabens, .alcohol],
                avoidedCategories: [],
                preferredLanguage: .russian,
                monthlyScanLimit: nil,
                scanHistory: [
                    ScanRecord(productBarcode: "460100000009", scannedAt: daysAgo(1, hour: 9)),
                    ScanRecord(productBarcode: "460100000019", scannedAt: daysAgo(2, hour: 18)),
                    ScanRecord(productBarcode: "460100000010", scannedAt: daysAgo(5, hour: 11)),
                    ScanRecord(productBarcode: "460100000012", scannedAt: daysAgo(6, hour: 20)),
                    ScanRecord(productBarcode: "460100000011", scannedAt: daysAgo(9, hour: 14)),
                    ScanRecord(productBarcode: "460100000020", scannedAt: daysAgo(11, hour: 10)),
                    ScanRecord(productBarcode: "460100000006", scannedAt: daysAgo(14, hour: 17)),
                    ScanRecord(productBarcode: "460100000016", scannedAt: daysAgo(21, hour: 12))
                ]
            ),
            UserProfile(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                nameKey: "user.maksim.name",
                subtitleKey: "user.maksim.subtitle",
                tier: .premium,
                allergies: [.soy],
                intolerances: [],
                avoidedIngredients: [.ammonia, .bleach, .addedSugar],
                avoidedCategories: [],
                preferredLanguage: .russian,
                monthlyScanLimit: nil,
                scanHistory: [
                    ScanRecord(productBarcode: "460100000007", scannedAt: daysAgo(1, hour: 15)),
                    ScanRecord(productBarcode: "460100000016", scannedAt: daysAgo(2, hour: 12)),
                    ScanRecord(productBarcode: "460100000003", scannedAt: daysAgo(4, hour: 8)),
                    ScanRecord(productBarcode: "460100000015", scannedAt: daysAgo(5, hour: 18)),
                    ScanRecord(productBarcode: "460100000018", scannedAt: daysAgo(7, hour: 11)),
                    ScanRecord(productBarcode: "460100000001", scannedAt: daysAgo(8, hour: 9)),
                    ScanRecord(productBarcode: "460100000005", scannedAt: daysAgo(15, hour: 19)),
                    ScanRecord(productBarcode: "460100000017", scannedAt: daysAgo(22, hour: 16))
                ]
            )
        ]
    }
}
