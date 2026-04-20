import Foundation

final class MockProfileService {
    func makeAccounts(referenceDate: Date = .now) -> [UserAccount] {
        let calendar = Calendar.current

        func daysAgo(_ offset: Int, hour: Int) -> Date {
            let shifted = calendar.date(byAdding: .day, value: -offset, to: referenceDate) ?? referenceDate
            return calendar.date(bySettingHour: hour, minute: 20, second: 0, of: shifted) ?? shifted
        }

        let annaProfileID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let leoProfileID = UUID(uuidString: "11111111-1111-1111-1111-111111111112")!
        let danielProfileID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let elenaProfileID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

        return [
            UserAccount(
                id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
                firstName: "Anna",
                lastName: "Petrova",
                tier: .free,
                preferredLanguage: .english,
                monthlyScanLimit: 24,
                accountSummaryKey: "account.summary.family",
                profiles: [
                    UserProfile(
                        id: annaProfileID,
                        name: "Anna",
                        relation: .primary,
                        allergies: [.predefined(.peanuts), .predefined(.fragrance)],
                        intolerances: [.predefined(.lactose)],
                        avoidIngredients: [.predefined(.addedSugar), .predefined(.palmOil)],
                        glutenSensitivity: true,
                        sugarTracking: true,
                        scanHistory: [
                            ScanRecord(productBarcode: "460200000008", scannedAt: daysAgo(1, hour: 8)),
                            ScanRecord(productBarcode: "460200000019", scannedAt: daysAgo(1, hour: 18)),
                            ScanRecord(productBarcode: "460200000003", scannedAt: daysAgo(2, hour: 18)),
                            ScanRecord(productBarcode: "460200000010", scannedAt: daysAgo(3, hour: 11)),
                            ScanRecord(productBarcode: "460200000017", scannedAt: daysAgo(4, hour: 19)),
                            ScanRecord(productBarcode: "460200000014", scannedAt: daysAgo(5, hour: 9)),
                            ScanRecord(productBarcode: "460200000005", scannedAt: daysAgo(7, hour: 13)),
                            ScanRecord(productBarcode: "460200000012", scannedAt: daysAgo(9, hour: 17)),
                            ScanRecord(productBarcode: "460200000004", scannedAt: daysAgo(12, hour: 10))
                        ]
                    ),
                    UserProfile(
                        id: leoProfileID,
                        name: "Leo",
                        relation: .child,
                        allergies: [.predefined(.cocoa)],
                        intolerances: [.predefined(.addedSugar)],
                        avoidIngredients: [.predefined(.colorants)],
                        glutenSensitivity: false,
                        sugarTracking: true,
                        scanHistory: [
                            ScanRecord(productBarcode: "460200000001", scannedAt: daysAgo(2, hour: 16)),
                            ScanRecord(productBarcode: "460200000002", scannedAt: daysAgo(4, hour: 12)),
                            ScanRecord(productBarcode: "460200000004", scannedAt: daysAgo(8, hour: 18)),
                            ScanRecord(productBarcode: "460200000007", scannedAt: daysAgo(10, hour: 8))
                        ]
                    )
                ],
                activeProfileID: annaProfileID
            ),
            UserAccount(
                id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
                firstName: "Daniel",
                lastName: "Brooks",
                tier: .free,
                preferredLanguage: .english,
                monthlyScanLimit: 20,
                accountSummaryKey: "account.summary.routine",
                profiles: [
                    UserProfile(
                        id: danielProfileID,
                        name: "Daniel",
                        relation: .primary,
                        allergies: [.predefined(.fragrance)],
                        intolerances: [.predefined(.sulfates)],
                        avoidIngredients: [.predefined(.silicones), .predefined(.alcohol)],
                        glutenSensitivity: false,
                        sugarTracking: false,
                        scanHistory: [
                            ScanRecord(productBarcode: "460200000013", scannedAt: daysAgo(1, hour: 20)),
                            ScanRecord(productBarcode: "460200000020", scannedAt: daysAgo(2, hour: 8)),
                            ScanRecord(productBarcode: "460200000015", scannedAt: daysAgo(3, hour: 7)),
                            ScanRecord(productBarcode: "460200000011", scannedAt: daysAgo(5, hour: 14)),
                            ScanRecord(productBarcode: "460200000018", scannedAt: daysAgo(6, hour: 11)),
                            ScanRecord(productBarcode: "460200000016", scannedAt: daysAgo(7, hour: 19)),
                            ScanRecord(productBarcode: "460200000009", scannedAt: daysAgo(10, hour: 9)),
                            ScanRecord(productBarcode: "460200000010", scannedAt: daysAgo(15, hour: 17))
                        ]
                    )
                ],
                activeProfileID: danielProfileID
            ),
            UserAccount(
                id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
                firstName: "Elena",
                lastName: "Volkova",
                tier: .premium,
                preferredLanguage: .russian,
                monthlyScanLimit: nil,
                accountSummaryKey: "account.summary.premium",
                profiles: [
                    UserProfile(
                        id: elenaProfileID,
                        name: "Elena",
                        relation: .primary,
                        allergies: [.predefined(.fragrance), .predefined(.essentialOils)],
                        intolerances: [.predefined(.alcohol)],
                        avoidIngredients: [.predefined(.parabens), .predefined(.sulfates), .predefined(.silicones)],
                        glutenSensitivity: false,
                        sugarTracking: true,
                        scanHistory: [
                            ScanRecord(productBarcode: "460200000010", scannedAt: daysAgo(1, hour: 10)),
                            ScanRecord(productBarcode: "460200000019", scannedAt: daysAgo(2, hour: 9)),
                            ScanRecord(productBarcode: "460200000012", scannedAt: daysAgo(2, hour: 18)),
                            ScanRecord(productBarcode: "460200000014", scannedAt: daysAgo(4, hour: 12)),
                            ScanRecord(productBarcode: "460200000017", scannedAt: daysAgo(5, hour: 20)),
                            ScanRecord(productBarcode: "460200000016", scannedAt: daysAgo(6, hour: 19)),
                            ScanRecord(productBarcode: "460200000006", scannedAt: daysAgo(8, hour: 8)),
                            ScanRecord(productBarcode: "460200000007", scannedAt: daysAgo(12, hour: 16)),
                            ScanRecord(productBarcode: "460200000005", scannedAt: daysAgo(18, hour: 9))
                        ]
                    )
                ],
                activeProfileID: elenaProfileID
            )
        ]
    }

    func makeAdditionalProfile(for account: UserAccount) -> UserProfile {
        UserProfile(
            id: UUID(),
            name: account.preferredLanguage == .russian ? "Миша" : "Misha",
            relation: .child,
            allergies: [],
            intolerances: [.predefined(.addedSugar)],
            avoidIngredients: [.predefined(.colorants)],
            glutenSensitivity: false,
            sugarTracking: true,
            scanHistory: []
        )
    }
}
