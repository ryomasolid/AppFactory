import Foundation
import SwiftData
import Testing
@testable import HamuhamuDiary

/// 「データを送る / 取り込む」のファイルが旧版と行き来できること、突き合わせの規則が旧版と同じこと。
struct BackupTests {
    /// 旧 React Native 版が書き出したファイルの形そのまま。
    private let legacyBackup = """
    {
      "version": 1,
      "exportedAt": "2026-06-25T10:00:00.000Z",
      "records": [
        {"id":"record-1","date":"2026-06-24","weight":41.2,"food":"ペレット","cleaningTaskIds":[],"memo":"","photoUri":"photos/x.jpg",
         "createdAt":"2026-06-24T12:00:00.000Z","updatedAt":"2026-06-24T12:00:00.000Z","photoData":null}
      ],
      "profile": null,
      "reminders": [{"id":"water_filter","name":"給水フィルター交換","lastDate":null,"cycleDays":7,"category":"equipment","emoji":"💧"}],
      "presetMeals": [], "singleFoods": [], "cleaningOptions": []
    }
    """

    @Test func readsBackupsWrittenByTheOldApp() throws {
        let file = try JSONDecoder().decode(BackupFile.self, from: Data(legacyBackup.utf8))
        #expect(file.version == 1)
        #expect(file.records.first?.weight == 41.2)
        #expect(file.records.first?.photoData == nil)
        #expect(file.profile == nil)
        #expect(file.reminders.first?.lastDate == nil)
    }

    @Test func writesTheSameShapeTheOldAppReads() throws {
        let snapshot = DataSnapshot(records: [record("2026-06-24", photoData: "AAAA")], reminders: Defaults.reminders)
        let data = try JSONEncoder().encode(BackupFile(snapshot: snapshot, exportedAt: Date(timeIntervalSince1970: 0)))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        // 旧版の pickBackupFile が確かめるのは version が数値で records が配列であること。
        #expect(json["version"] as? Int == 1)
        let records = try #require(json["records"] as? [[String: Any]])
        #expect(records.first?["date"] as? String == "2026-06-24")
        #expect(records.first?["cleaningTaskIds"] as? [String] == [])
        #expect(records.first?["photoData"] as? String == "AAAA")
        #expect(json["exportedAt"] as? String == "1970-01-01T00:00:00.000Z")
    }

    @Test func tolerantOfMissingFields() throws {
        let data = Data(#"{"version":1,"records":[{"date":"2026-06-01"}]}"#.utf8)
        let file = try JSONDecoder().decode(BackupFile.self, from: data)
        #expect(file.records.first?.food == "")
        #expect(file.records.first?.cleaningTaskIds == [])
        #expect(file.reminders.isEmpty)
    }

    @Test func rejectsFilesThatAreNotBackups() {
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(BackupFile.self, from: Data(#"{"hello":"world"}"#.utf8))
        }
    }

    // MARK: - 突き合わせ

    @Test func recordsAreMatchedByDateAndNewerWins() {
        let existing = [record("2026-06-01", updatedAt: "2026-06-01T10:00:00.000Z"),
                        record("2026-06-02", updatedAt: "2026-06-02T10:00:00.000Z")]
        let incoming = [record("2026-06-01", updatedAt: "2026-06-01T09:00:00.000Z"), // 古い → 無視
                        record("2026-06-02", updatedAt: "2026-06-03T08:00:00.000Z"), // 新しい → 更新
                        record("2026-06-05")]                                          // 無い日 → 追加
        let plan = BackupMerge.records(existing: existing, incoming: incoming)
        #expect(plan.adds.map(\.date) == ["2026-06-05"])
        #expect(plan.updates.map(\.date) == ["2026-06-02"])
        #expect(plan.skipped == 1)
    }

    @Test func duplicateDaysInOneFileKeepTheNewest() {
        let incoming = [record("2026-06-05", updatedAt: "2026-06-05T08:00:00.000Z"),
                        record("2026-06-05", updatedAt: "2026-06-05T20:00:00.000Z")]
        let plan = BackupMerge.records(existing: [], incoming: incoming)
        #expect(plan.adds.count == 1)
        #expect(plan.adds.first?.updatedAt == "2026-06-05T20:00:00.000Z")
    }

    @Test func reminderTakesTheLaterReplacementDate() {
        let existing = [ReminderDTO(id: "a", name: "", lastDate: "2026-06-01", cycleDays: 7, category: "", emoji: ""),
                        ReminderDTO(id: "b", name: "", lastDate: nil, cycleDays: 7, category: "", emoji: ""),
                        ReminderDTO(id: "c", name: "", lastDate: "2026-06-10", cycleDays: 7, category: "", emoji: "")]
        let incoming = [ReminderDTO(id: "a", name: "", lastDate: "2026-06-05", cycleDays: 7, category: "", emoji: ""),
                        ReminderDTO(id: "b", name: "", lastDate: "2026-06-03", cycleDays: 7, category: "", emoji: ""),
                        ReminderDTO(id: "c", name: "", lastDate: "2026-06-01", cycleDays: 7, category: "", emoji: ""),
                        ReminderDTO(id: "unknown", name: "", lastDate: "2026-06-09", cycleDays: 7, category: "", emoji: "")]
        #expect(BackupMerge.reminderDates(existing: existing, incoming: incoming) == ["a": "2026-06-05", "b": "2026-06-03"])
    }

    @MainActor
    @Test func mergeKeepsLocalPhotoWhenIncomingHasNone() throws {
        let container = try ModelContainer(for: Schema(AppSchema.models), configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        DiaryData.apply(DataSnapshot(), to: context)
        context.insert(DiaryRecord(
            key: "local", date: try #require(DayFormat.date(from: "2026-06-02")), weight: 40, photoPath: "photos/local.jpg",
            createdAt: Date(timeIntervalSince1970: 0), updatedAt: Date(timeIntervalSince1970: 0)
        ))
        try context.save()

        let summary = try DiaryData.merge(DataSnapshot(records: [record("2026-06-02"), record("2026-06-03")]), into: context)
        #expect(summary == DiaryData.ImportSummary(added: 1, updated: 1))

        let records = try context.fetch(FetchDescriptor<DiaryRecord>(sortBy: [SortDescriptor(\.date)]))
        #expect(records.count == 2)
        #expect(records[0].photoPath == "photos/local.jpg")
        #expect(records[0].key == "record-2026-06-02")
    }
}

struct TransferFormatTests {
    @Test func dayStringsRoundTrip() throws {
        let date = try #require(DayFormat.date(from: "2026-02-03"))
        #expect(DayFormat.string(from: date) == "2026-02-03")
        #expect(DayFormat.date(from: "2026-02") == nil)
    }

    @Test func timestampsMatchJavaScriptToISOString() throws {
        let date = try #require(Timestamp.date(from: "2026-06-24T12:34:56.789Z"))
        #expect(Timestamp.string(from: date) == "2026-06-24T12:34:56.789Z")
        #expect(Timestamp.date(from: "2026-06-24T12:34:56Z") != nil)
    }

    @Test func legacyPhotoPathsAreNormalized() {
        #expect(PhotoStore.normalizedPath(fromLegacy: "photos/a.jpg") == "photos/a.jpg")
        #expect(PhotoStore.normalizedPath(fromLegacy: "file:///var/mobile/Containers/Data/Application/X/Documents/photos/a%20b.jpg") == "photos/a b.jpg")
        #expect(PhotoStore.normalizedPath(fromLegacy: "file:///var/mobile/Containers/Data/Application/X/Library/Caches/ImagePicker/c.jpg") == nil)
        #expect(PhotoStore.normalizedPath(fromLegacy: "") == nil)
        #expect(PhotoStore.normalizedPath(fromLegacy: nil) == nil)
    }
}
