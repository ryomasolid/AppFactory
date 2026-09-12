import Foundation

/// 通知計算に渡すための、ゴミの種類のスナップショット（値型）。
/// SwiftData の `@Model` は Sendable でなく、スケジューラ側でうっかり触ると事故になるため、
/// 通知の計算はすべてこの値型だけを使って行う。
struct KindPlan: Equatable, Sendable, Identifiable {
    var id: UUID
    var name: String
    var note: String
    var sortOrder: Int
    var specs: [RuleSpec]
    var eveningTime: TimeOfDay?
    var morningTime: TimeOfDay?

    init(
        id: UUID = UUID(),
        name: String,
        note: String = "",
        sortOrder: Int = 0,
        specs: [RuleSpec],
        eveningTime: TimeOfDay? = nil,
        morningTime: TimeOfDay? = nil
    ) {
        self.id = id
        self.name = name
        self.note = note
        self.sortOrder = sortOrder
        self.specs = specs
        self.eveningTime = eveningTime
        self.morningTime = morningTime
    }

    /// このタイミングで実際に使う時刻（種類ごとの上書き → 既定値）。
    func time(for timing: NotificationTiming, settings: NotificationSettings) -> TimeOfDay {
        switch timing {
        case .evening: return eveningTime ?? settings.eveningTime
        case .morning: return morningTime ?? settings.morningTime
        }
    }
}

extension KindPlan {
    /// SwiftData モデルからスナップショットを作る。
    @MainActor
    init(_ kind: GarbageKind) {
        self.init(
            id: kind.id,
            name: kind.name,
            note: kind.note,
            sortOrder: kind.sortOrder,
            specs: kind.specs,
            eveningTime: kind.eveningTime,
            morningTime: kind.morningTime
        )
    }
}
