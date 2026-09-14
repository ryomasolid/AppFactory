import Foundation

extension Item {
    func periods(calendar: Calendar = .current) -> [WarrantyPeriod] {
        WarrantyTerm.periods(
            purchaseDate: purchaseDate,
            warrantyMonths: warrantyMonths,
            extendedMonths: extendedWarrantyMonths,
            calendar: calendar
        )
    }

    func overallStatus(now: Date = Date(), calendar: Calendar = .current) -> WarrantyStatus {
        WarrantyTerm.overall(periods(calendar: calendar), now: now, calendar: calendar)
    }

    func period(_ kind: WarrantyKind) -> WarrantyPeriod? {
        periods().first { $0.kind == kind }
    }

    var sortedAttachments: [Attachment] {
        attachments.sorted { ($0.sortOrder, $0.createdAt) < ($1.sortOrder, $1.createdAt) }
    }

    /// 一覧の2行目 "メーカー 型番"
    var subtitle: String {
        [maker, modelNumber].filter { !$0.isEmpty }.joined(separator: " ")
    }

    func matches(_ query: String) -> Bool {
        ItemSearch.matches(
            query: query,
            fields: [name, maker, modelNumber, serialNumber, storeName, note, category.label]
        )
    }

    var notificationInput: ItemNotificationInput {
        ItemNotificationInput(
            id: id,
            name: name,
            purchaseDate: purchaseDate,
            warrantyMonths: warrantyMonths,
            extendedMonths: extendedWarrantyMonths,
            extendedProvider: extendedWarrantyProvider,
            isArchived: isArchived
        )
    }

    var exportRow: ItemExportRow {
        ItemExportRow(
            name: name,
            category: category.label,
            maker: maker,
            modelNumber: modelNumber,
            serialNumber: serialNumber,
            purchaseDate: purchaseDate,
            price: price,
            storeName: storeName,
            warrantyLastDay: period(.manufacturer)?.lastDay,
            extendedLastDay: period(.extended)?.lastDay,
            extendedProvider: extendedWarrantyProvider,
            isArchived: isArchived,
            note: note
        )
    }
}
