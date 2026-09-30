import Foundation
import SwiftData

/// バックアップ取り込みの突き合わせ規則（旧版と同じ）。モデルに触れない純粋関数にしてテストする。
enum BackupMerge {
    struct RecordPlan: Equatable {
        var adds: [RecordDTO] = []
        /// 既存の記録（日付が同じもの）を置き換える記録。
        var updates: [RecordDTO] = []
        var skipped = 0
    }

    /// 記録は**日付**で突き合わせる。同じ日があれば updatedAt が新しいほうを残す。
    static func records(existing: [RecordDTO], incoming: [RecordDTO]) -> RecordPlan {
        var latest: [String: Date] = [:]
        for record in existing {
            let updated = Timestamp.date(from: record.updatedAt) ?? .distantPast
            latest[record.date] = max(latest[record.date] ?? .distantPast, updated)
        }
        var plan = RecordPlan()
        // 同じファイルの中で同じ日が重なっていても、新しいほう1件だけを採る。
        let newestIncoming = Dictionary(grouping: incoming, by: \.date).compactMap { _, group in
            group.max { (Timestamp.date(from: $0.updatedAt) ?? .distantPast) < (Timestamp.date(from: $1.updatedAt) ?? .distantPast) }
        }
        for record in newestIncoming.sorted(by: { $0.date < $1.date }) {
            let updated = Timestamp.date(from: record.updatedAt) ?? .distantPast
            if let local = latest[record.date] {
                if updated > local { plan.updates.append(record) } else { plan.skipped += 1 }
            } else {
                plan.adds.append(record)
            }
        }
        return plan
    }

    /// リマインダーは同じキーどうしで、交換日が新しいほうを採る。返り値は「キー → 新しい交換日」。
    static func reminderDates(existing: [ReminderDTO], incoming: [ReminderDTO]) -> [String: String] {
        let local = Dictionary(existing.map { ($0.id, $0.lastDate) }, uniquingKeysWith: { a, _ in a })
        var result: [String: String] = [:]
        for reminder in incoming {
            guard let date = reminder.lastDate, let current = local[reminder.id] else { continue }
            if current == nil || date > current! { result[reminder.id] = date }
        }
        return result
    }
}

/// SwiftData と `DataSnapshot`（旧版・バックアップの形）の橋渡し。
@MainActor
enum DiaryData {
    private static let bootstrapKey = "hd.didBootstrap"

    struct ImportSummary: Equatable {
        var added = 0
        var updated = 0
        var total: Int { added + updated }
    }

    // MARK: - 初回起動

    /// 初回起動だけ行う。旧版の日記が端末にあれば引き継ぎ、なければ既定の項目を入れる。
    /// 引き継ぎに失敗したら印を付けず、次回の起動でもう一度試す。
    static func bootstrapIfNeeded(_ context: ModelContext, defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: bootstrapKey) else { return }
        let hasData = ((try? context.fetchCount(FetchDescriptor<CleaningOption>())) ?? 0) > 0
            || ((try? context.fetchCount(FetchDescriptor<DiaryRecord>())) ?? 0) > 0
        if !hasData {
            apply(LegacyStore.load() ?? DataSnapshot(), to: context)
        }
        do {
            try context.save()
            defaults.set(true, forKey: bootstrapKey)
        } catch {
            context.rollback()
        }
    }

    /// 空のデータベースに中身を入れる。旧版で保存されていなかった項目は既定値にする。
    static func apply(_ snapshot: DataSnapshot, to context: ModelContext) {
        for record in snapshot.records {
            if let model = makeRecord(record) { context.insert(model) }
        }
        if let profile = snapshot.profile, !profile.name.isEmpty {
            context.insert(makeProfile(profile))
        }
        for (i, r) in (snapshot.reminders ?? Defaults.reminders).enumerated() {
            context.insert(SupplyReminder(
                key: r.id, name: r.name, emoji: r.emoji, cycleDays: r.cycleDays,
                lastDate: r.lastDate.flatMap { DayFormat.date(from: $0) }, category: r.category, sortOrder: i
            ))
        }
        for (i, m) in (snapshot.presetMeals ?? Defaults.presetMeals).enumerated() {
            context.insert(PresetMeal(key: m.id, name: m.name, text: m.text, sortOrder: i))
        }
        for (i, f) in (snapshot.singleFoods ?? Defaults.singleFoods).enumerated() {
            context.insert(SingleFood(key: f.id, name: f.name, sortOrder: i))
        }
        for (i, c) in (snapshot.cleaningOptions ?? Defaults.cleaningOptions).enumerated() {
            context.insert(CleaningOption(key: c.id, name: c.name, emoji: c.emoji, sortOrder: i))
        }
    }

    // MARK: - 書き出し

    /// 端末内の全データ。`includingPhotos` なら写真の中身も base64 で添える（バックアップ用）。
    static func snapshot(_ context: ModelContext, includingPhotos: Bool) -> DataSnapshot {
        let records = (try? context.fetch(FetchDescriptor<DiaryRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
        let profile = (try? context.fetch(FetchDescriptor<HamsterProfile>()))?.first
        return DataSnapshot(
            records: records.map { record in
                var dto = dto(record)
                if includingPhotos { dto.photoData = PhotoStore.base64(at: record.photoPath) }
                return dto
            },
            profile: profile.map { p in
                ProfileDTO(
                    name: p.name, species: p.species,
                    birthDate: p.birthDate.map { DayFormat.string(from: $0) },
                    welcomeDate: p.welcomeDate.map { DayFormat.string(from: $0) },
                    photoUri: p.photoPath
                )
            },
            reminders: fetchSorted(SupplyReminder.self, context).map {
                ReminderDTO(
                    id: $0.key, name: $0.name, lastDate: $0.lastDate.map { DayFormat.string(from: $0) },
                    cycleDays: $0.cycleDays, category: $0.category, emoji: $0.emoji
                )
            },
            presetMeals: fetchSorted(PresetMeal.self, context).map { PresetMealDTO(id: $0.key, name: $0.name, text: $0.text) },
            singleFoods: fetchSorted(SingleFood.self, context).map { SingleFoodDTO(id: $0.key, name: $0.name) },
            cleaningOptions: fetchSorted(CleaningOption.self, context).map {
                CleaningOptionDTO(id: $0.key, name: $0.name, emoji: $0.emoji)
            }
        )
    }

    // MARK: - 取り込み

    /// 取り込んだときに何件増える／変わるか（確認ダイアログ用。まだ書き込まない）。
    static func preview(_ incoming: DataSnapshot, into context: ModelContext) -> ImportSummary {
        let existing = snapshot(context, includingPhotos: false)
        let plan = BackupMerge.records(existing: existing.records, incoming: incoming.records)
        return ImportSummary(added: plan.adds.count, updated: plan.updates.count)
    }

    /// バックアップを今のデータに合体させる（旧版と同じ規則。献立などの設定は上書きしない）。
    @discardableResult
    static func merge(_ incoming: DataSnapshot, into context: ModelContext) throws -> ImportSummary {
        let existing = snapshot(context, includingPhotos: false)
        let plan = BackupMerge.records(existing: existing.records, incoming: incoming.records)

        let records = (try? context.fetch(FetchDescriptor<DiaryRecord>())) ?? []
        // 置き換える日の写真。受け取った記録に写真が無ければ、手元の写真を残す。
        var keptPhotos: [String: String] = [:]
        for dto in plan.updates {
            let day = dto.date
            for old in records where DayFormat.string(from: old.date) == day {
                if let path = old.photoPath {
                    if dto.photoData == nil { keptPhotos[day] = path } else { PhotoStore.delete(path) }
                }
                context.delete(old)
            }
        }
        for dto in plan.adds + plan.updates {
            var restored = dto
            restored.photoUri = dto.photoData.flatMap { PhotoStore.saveRestored(base64: $0, key: dto.id) }
                ?? keptPhotos[dto.date]
            if let model = makeRecord(restored) { context.insert(model) }
        }

        let dates = BackupMerge.reminderDates(existing: existing.reminders ?? [], incoming: incoming.reminders ?? [])
        for reminder in fetchSorted(SupplyReminder.self, context) {
            if let date = dates[reminder.key] { reminder.lastDate = DayFormat.date(from: date) }
        }

        // プロフィールが未登録のときだけ、受け取ったものを使う（同居人の端末で始めるとき用）。
        if existing.profile == nil, let profile = incoming.profile, !profile.name.isEmpty {
            var p = profile
            p.photoUri = nil
            context.insert(makeProfile(p))
        }

        try context.save()
        return ImportSummary(added: plan.adds.count, updated: plan.updates.count)
    }

    // MARK: - 変換

    static func dto(_ record: DiaryRecord) -> RecordDTO {
        RecordDTO(
            id: record.key, date: DayFormat.string(from: record.date), weight: record.weight,
            food: record.food, cleaningTaskIds: record.cleaningKeys, memo: record.memo,
            photoUri: record.photoPath,
            createdAt: Timestamp.string(from: record.createdAt), updatedAt: Timestamp.string(from: record.updatedAt)
        )
    }

    private static func makeRecord(_ dto: RecordDTO) -> DiaryRecord? {
        guard let date = DayFormat.date(from: dto.date) else { return nil }
        let created = Timestamp.date(from: dto.createdAt) ?? date
        return DiaryRecord(
            key: dto.id, date: date, weight: dto.weight, food: dto.food, cleaningKeys: dto.cleaningTaskIds,
            memo: dto.memo, photoPath: PhotoStore.normalizedPath(fromLegacy: dto.photoUri),
            createdAt: created, updatedAt: Timestamp.date(from: dto.updatedAt) ?? created
        )
    }

    private static func makeProfile(_ dto: ProfileDTO) -> HamsterProfile {
        HamsterProfile(
            name: dto.name, species: dto.species,
            birthDate: dto.birthDate.flatMap { DayFormat.date(from: $0) },
            welcomeDate: dto.welcomeDate.flatMap { DayFormat.date(from: $0) },
            photoPath: PhotoStore.normalizedPath(fromLegacy: dto.photoUri)
        )
    }

    private static func fetchSorted<T: PersistentModel>(_ type: T.Type, _ context: ModelContext) -> [T] where T: Sortable {
        ((try? context.fetch(FetchDescriptor<T>())) ?? []).sorted { $0.sortOrder < $1.sortOrder }
    }
}

/// 並べ替えできる設定項目。
protocol Sortable: AnyObject {
    var sortOrder: Int { get set }
}

extension SupplyReminder: Sortable {}
extension PresetMeal: Sortable {}
extension SingleFood: Sortable {}
extension CleaningOption: Sortable {}
