import SwiftData
import SwiftUI

/// ホーム。今日の記録への入口と、いま気にかけること（体重・掃除・交換時期）をまとめる。
struct HomeView: View {
    var onShowDiary: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DiaryRecord.date, order: .reverse) private var records: [DiaryRecord]
    @Query private var profiles: [HamsterProfile]
    @Query(sort: \SupplyReminder.sortOrder) private var reminders: [SupplyReminder]
    @Query(sort: \CleaningOption.sortOrder) private var cleaningOptions: [CleaningOption]

    @State private var editing: RecordSheet?
    @State private var sharing: DiaryRecord?
    @State private var showProfileEditor = false
    /// 思い出フォトに出す記録。開くたびに変わると落ち着かないので、画面ごとに1回だけ選ぶ。
    @State private var memoryKey: String?

    private enum RecordSheet: Identifiable {
        case new
        case edit(DiaryRecord)
        var id: String {
            switch self {
            case .new: "new"
            case .edit(let record): record.key
            }
        }
    }

    private var profile: HamsterProfile? { profiles.first }
    private var todayRecord: DiaryRecord? {
        records.first { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    recordButton
                    if profile == nil { setupCard }
                    statusCard
                    attentionCard
                    memoryCard
                }
                .padding(16)
            }
            .creamBackground()
            .navigationTitle("はむはむ日記")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $editing) { sheet in
            switch sheet {
            case .new: RecordEditorView(record: nil)
            case .edit(let record): RecordEditorView(record: record)
            }
        }
        .sheet(item: $sharing) { ShareCardView(record: $0) }
        .sheet(isPresented: $showProfileEditor) { ProfileEditorView(profile: nil) }
        .onAppear {
            if memoryKey == nil { memoryKey = records.filter { $0.photoPath != nil }.randomElement()?.key }
        }
    }

    // MARK: - 見出し

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Formatting.fullDay(Date()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(profile.map { "\($0.name)の今日のお世話" } ?? String(localized: "今日のお世話"))
                    .font(.title2.bold())
            }
            Spacer()
            if let profile {
                PhotoView(path: profile.photoPath)
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.card, lineWidth: 3))
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            }
        }
        .padding(.top, 4)
    }

    private var recordButton: some View {
        Button {
            editing = todayRecord.map(RecordSheet.edit) ?? .new
        } label: {
            Label(todayRecord == nil ? "記録する" : "今日の記録を編集する",
                  systemImage: todayRecord == nil ? "plus" : "square.and.pencil")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.white)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Theme.accent.opacity(0.35), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact, trigger: editing?.id)
    }

    private var setupCard: some View {
        VStack(spacing: 10) {
            Text("🐾 まずはプロフィールを登録しよう")
                .font(.subheadline.weight(.semibold))
            Text("名前や誕生日を入れると、年齢を自動で計算します")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("プロフィールを登録する") { showProfileEditor = true }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    // MARK: - 最新の状態

    private var statusCard: some View {
        let weights = WeightSeries.points(records.map { ($0.date, $0.weight, $0.createdAt) })
        let latest = weights.last
        let previous = weights.dropLast().last
        let lastCleaning = records.first { !$0.cleaningKeys.isEmpty }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最新ステータス").font(.headline)
                Spacer()
                if !records.isEmpty {
                    Button("日記を見る", action: onShowDiary).font(.subheadline)
                }
            }
            HStack(spacing: 12) {
                statusTile(icon: "scalemass.fill", title: "最新体重") {
                    if let latest {
                        VStack(alignment: .leading, spacing: 2) {
                            WeightText(weight: latest.weight, size: 24)
                            if let previous {
                                Text("前回から \(Formatting.signedWeight(((latest.weight - previous.weight) * 10).rounded() / 10))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text("未記録").font(.title3.bold()).foregroundStyle(.tertiary)
                    }
                }
                statusTile(icon: "sparkles", title: "最後の掃除") {
                    if let lastCleaning {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(relativeDay(lastCleaning.date))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.accent)
                            Text(cleaningNames(lastCleaning))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text("未記録").font(.title3.bold()).foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .card()
    }

    private func statusTile<Content: View>(icon: String, title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        .padding(12)
        .background(Theme.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func relativeDay(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: date), to: Calendar.current.startOfDay(for: Date())).day ?? 0
        switch days {
        case ...0: return String(localized: "今日")
        case 1: return String(localized: "昨日")
        default: return String(localized: "\(days)日前")
        }
    }

    private func cleaningNames(_ record: DiaryRecord) -> String {
        record.cleaningKeys
            .compactMap { key in cleaningOptions.first { $0.key == key }.map { "\($0.emoji)\($0.name)" } }
            .joined(separator: " ")
    }

    // MARK: - 交換時期

    @ViewBuilder
    private var attentionCard: some View {
        let items = reminders
            .map { ($0, ReminderStatus.evaluate(lastDate: $0.lastDate, cycleDays: $0.cycleDays)) }
            .filter { $0.1.state != .ok }
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("🗓️ そろそろ交換").font(.headline)
                ForEach(items, id: \.0.key) { reminder, status in
                    HStack {
                        Text(reminder.emoji).font(.title3)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(reminder.name).font(.subheadline.weight(.semibold))
                            Text(status.state.label)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(status.state.color)
                        }
                        Spacer()
                        Button("交換した") {
                            reminder.lastDate = Calendar.current.startOfDay(for: Date())
                            try? modelContext.save()
                            Task { await NotificationScheduler.shared.rebuild(context: modelContext) }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            .card()
        }
    }

    // MARK: - 思い出フォト

    @ViewBuilder
    private var memoryCard: some View {
        if let record = records.first(where: { $0.key == memoryKey }) {
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle("📸 思い出フォト")
                ZStack(alignment: .bottomLeading) {
                    PhotoView(path: record.photoPath)
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipped()
                    LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Formatting.fullDay(record.date)).font(.caption.weight(.semibold))
                        if !record.memo.isEmpty {
                            Text(record.memo).font(.caption).lineLimit(1).opacity(0.9)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(14)
                }
                .overlay(alignment: .topTrailing) {
                    Button { sharing = record } label: {
                        Label("シェア", systemImage: "square.and.arrow.up")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.white.opacity(0.92), in: Capsule())
                    }
                    .padding(10)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .onTapGesture { editing = .edit(record) }
            }
        }
    }
}
