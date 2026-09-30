import Foundation
import SwiftData
import Testing
@testable import HamuhamuDiary

/// 旧 React Native 版の日記を引き継げること。ここが壊れると、アップデートした人の日記が消えて見える。
struct LegacyMigrationTests {
    /// 旧版が実際に書く形（manifest.json に Zustand の JSON 文字列、1024文字超は MD5 名の別ファイル）。
    private func writeLegacyStore(records: [String], extraManifest: [String: Any] = [:]) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appending(path: "legacy-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let recordsValue = #"{"state":{"records":["# + records.joined(separator: ",") + #"],"_hasHydrated":true},"version":0}"#
        let profileValue = #"{"state":{"profile":{"id":"p1","name":"もち","species":"ジャンガリアンハムスター","birthDate":"2025-12-14","welcomeDate":null,"photoUri":"photos/avatar.jpg"},"#
            + #""presetMeals":[{"id":"pellets","name":"いつもの","text":"ペレット 4g"}],"singleFoods":[{"id":"corn","name":"コーン"}],"#
            + #""cleaningOptions":[{"id":"partial","name":"部分掃除","emoji":"🧹"},{"id":"custom-1","name":"砂浴び場","emoji":"🏖️"}]},"version":0}"#
        let remindersValue = #"{"state":{"reminders":[{"id":"bedding_change","name":"床材全面交換","lastDate":"2026-06-20","cycleDays":14,"category":"bedding","emoji":"🌿"}]},"version":0}"#

        var manifest: [String: Any] = [
            "hamu-profile": profileValue,
            "hamu-reminders": remindersValue,
            "hamu-tasks": #"{"state":{},"version":0}"#,
        ]
        if recordsValue.count > 1024 {
            // 大きな値は manifest では null、中身は MD5 名のファイル。
            manifest["hamu-records"] = NSNull()
            try recordsValue.write(to: dir.appending(path: LegacyStore.md5("hamu-records")), atomically: true, encoding: .utf8)
        } else {
            manifest["hamu-records"] = recordsValue
        }
        manifest.merge(extraManifest) { _, new in new }
        try JSONSerialization.data(withJSONObject: manifest).write(to: dir.appending(path: "manifest.json"))
        return dir
    }

    @Test func md5MatchesAsyncStorageFileNames() {
        #expect(LegacyStore.md5("hamu-records") == "ec7c7db8b84792321f8f14db5296bd21")
    }

    @Test func readsInlineValues() throws {
        let dir = try writeLegacyStore(records: [legacyRecordJSON(id: "record-1", date: "2026-06-01", weight: "39.6")])
        let snapshot = try #require(LegacyStore.load(from: [dir]))

        #expect(snapshot.records.count == 1)
        #expect(snapshot.records[0].weight == 39.6)
        #expect(snapshot.records[0].cleaningTaskIds == ["partial"])
        #expect(snapshot.profile?.name == "もち")
        #expect(snapshot.profile?.welcomeDate == nil)
        #expect(snapshot.cleaningOptions?.map(\.id) == ["partial", "custom-1"])
        #expect(snapshot.reminders?.first?.lastDate == "2026-06-20")
    }

    @Test func readsLargeValuesFromTheirOwnFile() throws {
        let records = (1...30).map { legacyRecordJSON(id: "record-\($0)", date: String(format: "2026-05-%02d", $0), weight: "40") }
        let dir = try writeLegacyStore(records: records)
        let snapshot = try #require(LegacyStore.load(from: [dir]))
        #expect(snapshot.records.count == 30)
    }

    @Test func oneBrokenRecordDoesNotLoseTheRest() throws {
        let dir = try writeLegacyStore(records: [
            legacyRecordJSON(id: "record-1", date: "2026-06-01"),
            #"{"id":"broken"}"#,
            #""not an object""#,
            legacyRecordJSON(id: "record-3", date: "2026-06-03"),
        ])
        let snapshot = try #require(LegacyStore.load(from: [dir]))
        #expect(snapshot.records.map(\.id) == ["record-1", "record-3"])
    }

    @Test func missingDirectoryMeansNoLegacyData() {
        let dir = FileManager.default.temporaryDirectory.appending(path: "none-\(UUID().uuidString)")
        #expect(LegacyStore.load(from: [dir]) == nil)
    }

    @MainActor
    @Test func migratedDataLandsInSwiftData() throws {
        let dir = try writeLegacyStore(records: [
            legacyRecordJSON(id: "record-1", date: "2026-06-01", weight: "39.6", photo: #""photos/a.jpg""#),
            legacyRecordJSON(id: "record-2", date: "2026-06-02", photo: #""file:///var/mobile/Containers/Data/Application/OLD/Documents/photos/b.jpg""#),
        ])
        let snapshot = try #require(LegacyStore.load(from: [dir]))
        let container = try ModelContainer(for: Schema(AppSchema.models), configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        DiaryData.apply(snapshot, to: context)
        try context.save()

        let records = try context.fetch(FetchDescriptor<DiaryRecord>(sortBy: [SortDescriptor(\.date)]))
        #expect(records.map(\.key) == ["record-1", "record-2"])
        #expect(records[0].weight == 39.6)
        #expect(DayFormat.string(from: records[0].date) == "2026-06-01")
        // 相対パスはそのまま、旧形式の絶対パスは Documents からの相対に直る。
        #expect(records[0].photoPath == "photos/a.jpg")
        #expect(records[1].photoPath == "photos/b.jpg")

        let profile = try #require(try context.fetch(FetchDescriptor<HamsterProfile>()).first)
        #expect(profile.name == "もち")
        #expect(profile.birthDate.map { DayFormat.string(from: $0) } == "2025-12-14")

        // 旧版にあった項目はそのまま、旧版に無かった項目（ここでは無し）だけ既定値。
        let cleaning = try context.fetch(FetchDescriptor<CleaningOption>(sortBy: [SortDescriptor(\.sortOrder)]))
        #expect(cleaning.map(\.key) == ["partial", "custom-1"])
        let reminders = try context.fetch(FetchDescriptor<SupplyReminder>())
        #expect(reminders.map(\.key) == ["bedding_change"])
    }

    @MainActor
    @Test func freshInstallGetsDefaults() throws {
        let container = try ModelContainer(for: Schema(AppSchema.models), configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        DiaryData.apply(DataSnapshot(), to: context)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<CleaningOption>()) == Defaults.cleaningOptions.count)
        #expect(try context.fetchCount(FetchDescriptor<PresetMeal>()) == Defaults.presetMeals.count)
        #expect(try context.fetchCount(FetchDescriptor<SingleFood>()) == Defaults.singleFoods.count)
        #expect(try context.fetchCount(FetchDescriptor<SupplyReminder>()) == Defaults.reminders.count)
        #expect(try context.fetchCount(FetchDescriptor<DiaryRecord>()) == 0)
    }
}
