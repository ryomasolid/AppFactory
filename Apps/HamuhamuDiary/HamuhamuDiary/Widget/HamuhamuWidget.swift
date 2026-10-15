import SwiftUI
import UIKit
import WidgetKit

/// ホーム画面のウィジェット。うちの子の写真と「今日の記録」が済んだかを出し、押すと今日の記録を開く。
@main
struct HamuhamuWidgetBundle: WidgetBundle {
    var body: some Widget {
        HamuhamuWidget()
    }
}

struct HamuhamuWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSnapshot.widgetKind, provider: Provider()) { entry in
            HamuhamuWidgetView(entry: entry)
                .containerBackground(WidgetColors.cream, for: .widget)
                .widgetURL(WidgetSnapshot.recordURL)
        }
        .configurationDisplayName("今日のお世話")
        .description("今日の記録が済んだかと、最新の体重をひと目で。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct Entry: TimelineEntry {
    var date: Date
    var snapshot: WidgetSnapshot?
    var avatar: UIImage?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        Entry(date: Date(), snapshot: WidgetSnapshot(name: "もち", lastRecordDate: Date(), latestWeight: 39.6, weightChange: -0.2))
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(context.isPreview && WidgetSnapshot.load() == nil ? placeholder(in: context) : current(at: Date()))
    }

    /// アプリを開かなくても日付が変われば「まだ」に戻るよう、今と、この先2日ぶんの 0:00 に並べる。
    /// データが変わったときはアプリが作り直しを頼む（`WidgetSync`）。
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let midnights = (1...2).compactMap { calendar.date(byAdding: .day, value: $0, to: calendar.startOfDay(for: now)) }
        let entries = [current(at: now)] + midnights.map { current(at: $0) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func current(at date: Date) -> Entry {
        let avatar = WidgetSnapshot.avatarURL.flatMap { UIImage(contentsOfFile: $0.path(percentEncoded: false)) }
        return Entry(date: date, snapshot: WidgetSnapshot.load(), avatar: avatar)
    }
}

/// アプリの配色と合わせる（ウィジェットからはアプリのアセットを引けないので値で持つ）。
enum WidgetColors {
    static let cream = Color(red: 1, green: 0.965, blue: 0.93)
    static let orange = Color(red: 0.91, green: 0.50, blue: 0.29)
    static let ink = Color(red: 0.23, green: 0.16, blue: 0.13)
    static let sub = Color(red: 0.48, green: 0.40, blue: 0.34)
    static let ok = Color(red: 0.20, green: 0.62, blue: 0.36)
    static let due = Color(red: 0.86, green: 0.30, blue: 0.27)
}

struct HamuhamuWidgetView: View {
    var entry: Entry
    @Environment(\.widgetFamily) private var family

    private var snapshot: WidgetSnapshot? { entry.snapshot }
    private var name: String { snapshot?.name.flatMap { $0.isEmpty ? nil : $0 } ?? String(localized: "ハムちゃん") }
    private var recorded: Bool { snapshot?.recorded(on: entry.date) ?? false }
    private var anniversaries: [Anniversary] {
        Anniversaries.on(entry.date, birthDate: snapshot?.birthDate, welcomeDate: snapshot?.welcomeDate)
    }

    var body: some View {
        switch family {
        case .systemMedium: medium
        default: small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                avatar(size: 46)
                Spacer(minLength: 0)
                weightText(size: 20)
            }
            Spacer(minLength: 0)
            Text(name)
                .font(.headline)
                .foregroundStyle(WidgetColors.ink)
                .lineLimit(1)
            headline
        }
    }

    private var medium: some View {
        HStack(spacing: 14) {
            avatar(size: 96)
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.title3.bold())
                    .foregroundStyle(WidgetColors.ink)
                    .lineLimit(1)
                headline
                Spacer(minLength: 0)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    weightText(size: 24)
                    if let change = snapshot?.weightChange {
                        Text("前回から \(change == 0 ? "±0" : (change > 0 ? "+" : "−") + format(abs(change)))g")
                            .font(.caption2)
                            .foregroundStyle(WidgetColors.sub)
                    }
                }
                if let welcome = snapshot?.welcomeDate {
                    let days = (Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: welcome), to: entry.date).day ?? 0) + 1
                    Text("一緒に過ごして \(days)日目")
                        .font(.caption2)
                        .foregroundStyle(WidgetColors.sub)
                }
            }
            Spacer(minLength: 0)
        }
    }

    /// 記念日 → 体重の減り → 今日の記録、の順に大事なものを1行で。
    @ViewBuilder
    private var headline: some View {
        if let first = anniversaries.first {
            status("\(first.emoji) \(Anniversaries.label(anniversaries))", color: WidgetColors.orange)
        } else if snapshot?.weightDropping == true {
            status("⚠️ 体重が減っています", color: WidgetColors.due)
        } else if recorded {
            status("✓ 今日の記録ずみ", color: WidgetColors.ok)
        } else {
            status("今日の記録はまだ", color: WidgetColors.orange)
        }
    }

    private func status(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    @ViewBuilder
    private func weightText(size: CGFloat) -> some View {
        if let weight = snapshot?.latestWeight {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(format(weight))
                    .font(.system(size: size, weight: .heavy, design: .rounded))
                    .foregroundStyle(WidgetColors.orange)
                Text("g").font(.caption.bold()).foregroundStyle(WidgetColors.sub)
            }
        }
    }

    private func avatar(size: CGFloat) -> some View {
        Group {
            if let image = entry.avatar {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Text("🐹").font(.system(size: size * 0.55))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(WidgetColors.orange.opacity(0.15))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}
