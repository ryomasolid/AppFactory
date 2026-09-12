import Foundation

/// 「出した」の連続回数。ホームの下に出して、続けられている実感につなげる。
enum StreakCalculator {

    /// 「どの種類を・いつ出したか」の記録キー。
    struct DoneKey: Hashable, Sendable {
        var kindID: UUID
        var date: Date

        init(kindID: UUID, date: Date, calendar: Calendar = .current) {
            self.kindID = kindID
            self.date = calendar.startOfDay(for: date)
        }
    }

    /// 直近の収集日から過去へさかのぼって、連続で「出した」が付いている収集日の数。
    ///
    /// その日の種類を**すべて**出していれば1回とカウントする。
    /// 今日ぶんはこれから出すので、まだ未チェックでも連続は途切れさせない。
    static func streak(
        days: [CollectionDay],
        done: Set<DoneKey>,
        today: Date,
        calendar: Calendar = .current
    ) -> Int {
        let today = calendar.startOfDay(for: today)
        let past = days.filter { $0.date <= today }.sorted { $0.date > $1.date }

        var count = 0
        for day in past {
            let isDone = !day.kindIDs.isEmpty && day.kindIDs.allSatisfy {
                done.contains(DoneKey(kindID: $0, date: day.date, calendar: calendar))
            }
            if isDone {
                count += 1
            } else if day.date == today {
                // 今日はまだこれから。途切れ扱いにしない。
                continue
            } else {
                break
            }
        }
        return count
    }
}
