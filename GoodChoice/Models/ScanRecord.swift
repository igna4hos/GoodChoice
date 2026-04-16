import Foundation

struct ScanRecord: Identifiable, Hashable {
    let id: UUID
    let productBarcode: String
    let scannedAt: Date

    init(id: UUID = UUID(), productBarcode: String, scannedAt: Date) {
        self.id = id
        self.productBarcode = productBarcode
        self.scannedAt = scannedAt
    }
}
