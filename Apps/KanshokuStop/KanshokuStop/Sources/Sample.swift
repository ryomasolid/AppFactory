import Foundation

/// ストアのスクショ用の見本（起動引数 `-sample`）。端末の記録には触らない。
/// `-tab 1` でカレンダーから開く。
enum Sample {
    static var isOn: Bool { ProcessInfo.processInfo.arguments.contains("-sample") }

    static var firstTab: Int {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-tab"), i + 1 < args.count else { return 0 }
        return Int(args[i + 1]) ?? 0
    }

    /// 見本では日付を 2026-11-20 に固定する（スクショの見た目をそろえるため）。
    static var now: Date {
        guard isOn else { return .now }
        return Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 20, hour: 21)) ?? .now
    }

    @MainActor
    static func book() -> SnackBook {
        let calendar = Calendar.current
        var seed: [String: DayEntry] = [:]
        // 11月：はじめは ときどき食べて、後半は 12日つづけて我慢できている。
        let snackedDays: Set<Int> = [2, 3, 6, 8]
        for day in 1...19 {
            guard let date = calendar.date(from: DateComponents(year: 2026, month: 11, day: day)) else { continue }
            var entry = DayEntry(status: snackedDays.contains(day) ? .snacked : .skipped)
            if day % 3 == 1 { entry.weight = String(format: "%.1f", 56.4 - Double(day) * 0.06) }
            if day == 6 { entry.memo = "会議のおやつのクッキー" }
            seed[DayKey.of(date, calendar: calendar)] = entry
        }
        // 10月の後半も少し。
        for day in 18...31 {
            guard let date = calendar.date(from: DateComponents(year: 2026, month: 10, day: day)) else { continue }
            seed[DayKey.of(date, calendar: calendar)] = DayEntry(status: day % 4 == 0 ? .snacked : .skipped)
        }
        if let today = calendar.date(from: DateComponents(year: 2026, month: 11, day: 20)) {
            seed[DayKey.of(today, calendar: calendar)] = DayEntry(status: .skipped, weight: "55.2", memo: "")
        }
        return SnackBook(fileURL: nil, seed: seed)
    }
}
