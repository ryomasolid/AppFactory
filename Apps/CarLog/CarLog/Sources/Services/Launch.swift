import Foundation
import SwiftData

/// 起動引数（スクリーンショット撮影・デモ用）。
/// すべてローカルの起動引数で制御し、通常のユーザー利用時には一切影響しない。
enum Launch {
    private static var args: [String] { ProcessInfo.processInfo.arguments }

    /// 広告バナーと同意/ATT フローを止める（スクショ撮影用）。
    static var hideAds: Bool { args.contains("-hideAds") }
    /// デモ車両と記録を投入する。
    static var isDemo: Bool { args.contains("-demo") }
    /// 起動時にペイウォールを表示（既存アプリと引数名を揃える）。
    static var showPaywall: Bool { args.contains("-showPaywall") }
    /// オンボーディングを強制表示（スクショ撮影用）。
    static var forceOnboarding: Bool { args.contains("-forceOnboarding") }
    /// 給油入力シートを開いた状態で起動する。
    static var showFuelEntry: Bool { args.contains("-showFuelEntry") }

    /// オンボーディングの開始ページ（"vehicle" / "odometer" / "templates" / "notifications"）。
    static var onboardingStep: String? { value(after: "-onboardingStep") }

    /// 起動時に選択するタブ（"fuel" / "cost" / "maintenance" / "settings"）。
    static var startTab: String? { value(after: "-startTab") }

    private static func value(after flag: String) -> String? {
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    // MARK: - デモデータ

    /// 給油14回ぶん。いつ撮っても「直近の給油が2日前」になるよう、日付は実行日から逆算する。
    /// (何日前, 前回からの走行km, 区間燃費km/L, 単価円/L)
    private static let demoFuel: [(daysAgo: Int, distance: Double, economy: Double, price: Double)] = [
        (183, 0, 0, 172), (169, 486, 21.8, 171), (156, 452, 22.4, 173), (141, 510, 20.9, 174),
        (128, 437, 23.1, 172), (113, 498, 22.0, 170), (99, 471, 21.5, 169), (86, 529, 19.8, 171),
        (71, 455, 22.7, 173), (57, 492, 23.4, 175), (43, 507, 21.2, 176), (30, 446, 22.9, 174),
        (15, 518, 20.6, 173), (2, 473, 22.3, 172),
    ]

    /// クルマが未登録のときだけデモデータを投入する。
    @MainActor
    static func seedIfNeeded(_ context: ModelContext, calendar: Calendar = .current) {
        let count = (try? context.fetchCount(FetchDescriptor<Vehicle>())) ?? 0
        guard count == 0 else { return }

        let today = calendar.startOfDay(for: Date())
        func daysAgo(_ days: Int) -> Date {
            let day = calendar.date(byAdding: .day, value: -days, to: today) ?? today
            // 記録らしく見えるよう、時刻を夕方に寄せる。
            return calendar.date(bySettingHour: 18, minute: 20, second: 0, of: day) ?? day
        }
        func monthsAgo(_ months: Int, plusDays days: Int = 0) -> Date {
            let month = calendar.date(byAdding: .month, value: -months, to: today) ?? today
            return calendar.date(byAdding: .day, value: -days, to: month) ?? month
        }

        let startOdometer: Double = 42150
        let vehicle = Vehicle(
            name: String(localized: "プリウス"),
            makerModel: String(localized: "トヨタ プリウス"),
            fuelType: .regular,
            tankCapacity: 43,
            purchaseOdometer: 42100,
            firstRegistrationDate: monthsAgo(43),
            isDefault: true,
            createdAt: daysAgo(190)
        )
        context.insert(vehicle)

        var odometer = startOdometer
        for entry in demoFuel {
            odometer += entry.distance
            let liters = entry.economy > 0 ? (entry.distance / entry.economy * 100).rounded() / 100 : 34.0
            let record = FuelRecord(
                date: daysAgo(entry.daysAgo),
                odometer: odometer,
                liters: liters,
                totalPrice: Int((liters * entry.price).rounded()),
                stationName: entry.daysAgo % 2 == 0 ? "ENEOS" : ""
            )
            record.vehicle = vehicle
            context.insert(record)
        }
        let currentOdometer = odometer

        // 駐車場は毎月1日。今月ぶんも入れて「今月の出費」が必ず埋まるようにする。
        for monthOffset in 0..<6 {
            let month = calendar.date(byAdding: .month, value: -monthOffset, to: today) ?? today
            let first = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
            addExpense(.parking, 11000, on: first, note: String(localized: "月極"), to: vehicle, in: context)
        }
        addExpense(.tax, 36000, on: daysAgo(106), to: vehicle, in: context)
        addExpense(.insurance, 58400, on: daysAgo(160), note: String(localized: "任意保険"), to: vehicle, in: context)
        addExpense(.wash, 1300, on: daysAgo(40), to: vehicle, in: context)
        addExpense(.wash, 1300, on: daysAgo(12), to: vehicle, in: context)
        addExpense(.toll, 2380, on: daysAgo(25), to: vehicle, in: context)
        addExpense(.toll, 1850, on: daysAgo(64), to: vehicle, in: context)
        addExpense(
            .maintenance, 5980, on: daysAgo(145), odometer: currentOdometer - 4650,
            note: String(localized: "オイル交換"), to: vehicle, in: context
        )

        // メンテ: オイル交換は「残り350km」で .soon、ワイパーは期限切れ、車検と税は余裕あり。
        let items: [(MaintenanceTemplate.ID, Date, Double?)] = [
            ("oil", daysAgo(145), currentOdometer - 4650),
            ("wiper", monthsAgo(12, plusDays: 6), nil),
            ("inspection", monthsAgo(19), nil),
            ("tax", monthsAgo(3, plusDays: 14), nil),
        ]
        for (index, (templateID, lastDate, lastOdometer)) in items.enumerated() {
            guard let template = MaintenanceTemplate.all.first(where: { $0.id == templateID }) else { continue }
            let item = template.makeItem(sortOrder: index, startDate: lastDate, startOdometer: lastOdometer)
            item.vehicle = vehicle
            context.insert(item)
            if templateID == "oil" {
                let log = MaintenanceLog(date: lastDate, odometer: lastOdometer, cost: 5980)
                log.item = item
                context.insert(log)
            }
        }

        try? context.save()
    }

    @MainActor
    private static func addExpense(
        _ category: ExpenseCategory, _ amount: Int, on date: Date, odometer: Double? = nil,
        note: String = "", to vehicle: Vehicle, in context: ModelContext
    ) {
        let expense = ExpenseRecord(date: date, category: category, amount: amount, odometer: odometer, note: note)
        expense.vehicle = vehicle
        context.insert(expense)
    }
}
