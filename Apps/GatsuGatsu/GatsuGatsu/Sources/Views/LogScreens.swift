import Charts
import StoreKit
import SwiftUI

struct LogScreen: View {
    @Environment(BiteLog.self) private var log
    @State private var addingBite = false
    private let library = Library.shared

    private var grouped: [(day: Date, bites: [Bite])] {
        let calendar = Calendar.current
        return Dictionary(grouping: log.bites) { calendar.startOfDay(for: $0.eatenAt) }
            .map { ($0.key, $0.value) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                today
                week
                NavigationLink(value: Route.monthReport) {
                    HStack {
                        Label("今月のまとめ", systemImage: "calendar").font(.subheadline.weight(.black))
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .sticker(fill: .softOrange)
                }
                .buttonStyle(.plain)
                SponsoredCard(slot: "log")
                history
            }
            .padding(16)
        }
        .paperBackground()
        .navigationTitle("ガツログ")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { addingBite = true } label: { Image(systemName: "plus") }.accessibilityLabel("記録する")
            }
        }
        .sheet(isPresented: $addingBite) { AddBiteSheet() }
    }

    private var today: some View {
        let sum = log.stats.summary(of: log.stats.onDay(.now))
        return VStack(alignment: .leading, spacing: 10) {
            Text("きょう").font(.subheadline.weight(.black))
            BigNumber(value: sum.kcal.whole, unit: "kcal", size: 46)
            HStack(spacing: 14) {
                macro("P", sum.protein)
                macro("F", sum.fat)
                macro("C", sum.carbs)
                Spacer()
                Text("茶碗 \(sum.riceBowls.oneDecimal)杯ぶん").font(.caption.weight(.bold)).foregroundStyle(.secondary)
            }
            Button { addingBite = true } label: { PrimaryButtonLabel(text: "食べたものを記録", systemImage: "plus") }
                .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sticker()
    }

    private func macro(_ letter: String, _ grams: Double) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(letter).font(.caption.weight(.black)).foregroundStyle(.tint)
            Text("\(grams.whole)g").font(.footnote.weight(.bold)).monospacedDigit()
        }
    }

    private var week: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("この7日").font(.subheadline.weight(.black))
            Chart(log.stats.lastWeek()) { total in
                BarMark(x: .value("日", total.day, unit: .day), y: .value("kcal", total.kcal))
                    .foregroundStyle(Color.accentColor)
                    .cornerRadius(4)
                RuleMark(y: .value("目安", library.daily.calories))
                    .foregroundStyle(Color.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.day(.defaultDigits))
                }
            }
            .frame(height: 150)
            Text("点線は1日の目安 \(library.daily.calories.whole)kcal（成人の一般的な目安）").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(14)
        .sticker()
    }

    @ViewBuilder private var history: some View {
        if grouped.isEmpty {
            Text("まだ記録がありません。チェーンのメニューを選ぶだけで、公式のカロリーとPFCが入ります。")
                .font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
        }
        ForEach(grouped, id: \.day) { group in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(group.day.formatted(.dateTime.month().day().weekday().locale(Locale(identifier: "ja_JP")))).font(.subheadline.weight(.black))
                    Spacer()
                    Text("\(log.stats.summary(of: group.bites).kcal.whole)kcal").font(.subheadline.weight(.black)).monospacedDigit()
                }
                ForEach(group.bites) { bite in
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(bite.name).font(.footnote.weight(.semibold))
                            if let place = bite.place { Text(place).font(.caption2).foregroundStyle(.secondary) }
                        }
                        Spacer()
                        Text("\(bite.kcal.whole)").font(.footnote).monospacedDigit().foregroundStyle(.secondary)
                        Menu {
                            Button("この記録を削除", systemImage: "trash", role: .destructive) { log.remove(bite) }
                        } label: {
                            Image(systemName: "ellipsis").frame(width: 30, height: 30).contentShape(.rect)
                        }
                        .accessibilityLabel("\(bite.name)の操作")
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.card, in: .rect(cornerRadius: 12))
        }
    }
}

struct AddBiteSheet: View {
    private enum Mode: String, CaseIterable { case menu = "チェーンから", manual = "手で入力" }

    @Environment(BiteLog.self) private var log
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var mode: Mode = .menu
    @State private var eatenAt = Date.now
    @State private var chainID = Library.shared.chains.first?.id ?? ""
    @State private var lastAdded: String?
    @State private var name = ""
    @State private var place = ""
    @State private var kcalText = ""
    private let library = Library.shared

    private var chain: Chain? { library.chains.first { $0.id == chainID } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Picker("入れ方", selection: $mode) {
                        ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    DatePicker("食べた日時", selection: $eatenAt, in: ...Date.now)
                        .font(.subheadline.weight(.bold))
                    if mode == .menu { menuPane } else { manualPane }
                }
                .padding(16)
            }
            .paperBackground()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("記録する")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("完了") { dismiss() } }
            }
        }
    }

    private var menuPane: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(library.chains) { c in
                        Chip(label: "\(c.emoji) \(c.name)", selected: c.id == chainID) { chainID = c.id }
                    }
                }
                .padding(.vertical, 2).padding(.horizontal, 1)
            }
            if let lastAdded {
                Label("「\(lastAdded)」を記録しました", systemImage: "checkmark.circle.fill")
                    .font(.footnote.weight(.bold)).foregroundStyle(.green)
            }
            if let chain {
                ForEach(chain.menu) { item in
                    Button { record(item, from: chain) } label: {
                        HStack {
                            Text(item.name).font(.footnote.weight(.semibold)).multilineTextAlignment(.leading)
                            Spacer()
                            Text("\(item.calories.whole)kcal").font(.footnote).monospacedDigit().foregroundStyle(.secondary)
                            Image(systemName: "plus.circle.fill").foregroundStyle(.tint)
                        }
                        .padding(10)
                        .background(Color.card, in: .rect(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                Text("数値は\(chain.source.label)より（\(DateText.japanese(library.nutritionCheckedAt))確認）")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private var manualPane: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("食べたもの（例: 豚山 小ラーメン）", text: $name).textFieldStyle(.roundedBorder)
            TextField("お店や駅（なくてもOK）", text: $place).textFieldStyle(.roundedBorder)
            TextField("カロリー（kcal）", text: $kcalText).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
            Text("公表されていない店は、早見表の麺やご飯の量から見当をつけられます。").font(.caption).foregroundStyle(.secondary)
            Button(action: recordManual) { PrimaryButtonLabel(text: "記録する") }
                .buttonStyle(.plain)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || Double(kcalText) == nil)
                .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty || Double(kcalText) == nil ? 0.45 : 1)
        }
    }

    private func record(_ item: Chain.Item, from chain: Chain) {
        log.add(Bite(eatenAt: eatenAt, name: item.name, place: chain.name, kcal: item.calories,
                     protein: item.protein, fat: item.fat, carbs: item.carbs))
        lastAdded = item.name
        askForReviewIfDue()
    }

    private func recordManual() {
        guard let kcal = Double(kcalText) else { return }
        let trimmedPlace = place.trimmingCharacters(in: .whitespaces)
        log.add(Bite(eatenAt: eatenAt, name: name.trimmingCharacters(in: .whitespaces),
                     place: trimmedPlace.isEmpty ? nil : trimmedPlace, kcal: kcal))
        askForReviewIfDue()
        dismiss()
    }

    /// 記録が習慣になりかけた5件目と30件目にだけ頼む。
    private func askForReviewIfDue() {
        if log.bites.count == 5 || log.bites.count == 30 { requestReview() }
    }
}

/// 今月のまとめ。リワード広告で開く。
struct MonthReportScreen: View {
    @Environment(AdDirector.self) private var ads
    @Environment(BiteLog.self) private var log
    @State private var watching = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if ads.monthReportOpen { report } else { locked }
            }
            .padding(16)
        }
        .paperBackground()
        .navigationTitle("今月のまとめ")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var locked: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill").font(.largeTitle).foregroundStyle(.tint)
            Text("短い動画広告を1本見ると、24時間ひらけます").font(.headline.weight(.black)).multilineTextAlignment(.center)
            Text("今月の合計カロリー、茶碗に換算した量、いちばん食べた日、よく行ったお店が分かります。記録やツールは広告を見なくても使えます。")
                .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
            RewardButton(reward: .monthReport, title: "広告を見てひらく")
        }
        .padding(18)
        .sticker()
    }

    private var report: some View {
        let month = log.stats.monthReport()
        return VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Date.now.formatted(.dateTime.year().month().locale(Locale(identifier: "ja_JP")))).font(.subheadline.weight(.black))
                BigNumber(value: month.summary.kcal.whole, unit: "kcal", size: 42)
                Text("ご飯にすると茶碗 \(month.summary.riceBowls.whole)杯ぶん").font(.subheadline.weight(.heavy))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(Color(red: 0.11, green: 0.1, blue: 0.09))
            .sticker(fill: .mustard)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                tile("記録した日", "\(month.activeDays)日")
                tile("記録した数", "\(month.summary.count)品")
                tile("1日の平均", "\(month.kcalPerActiveDay.whole)kcal")
                tile("たんぱく質", "\(month.summary.protein.whole)g")
                tile("いちばん食べた日", month.biggestDay.map { $0.day.formatted(.dateTime.month().day().locale(Locale(identifier: "ja_JP"))) } ?? "—")
                tile("よく行った店", month.favoritePlace ?? "—")
            }
        }
    }

    private func tile(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption.weight(.bold)).foregroundStyle(.secondary)
            Text(value).font(.headline.weight(.black)).lineLimit(1).minimumScaleFactor(0.6)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sticker()
    }
}

/// リワード広告を流すボタン。押した人だけが見る。
struct RewardButton: View {
    let reward: AdDirector.Reward
    let title: String
    @Environment(AdDirector.self) private var ads
    @State private var message: String?

    var body: some View {
        VStack(spacing: 6) {
            Button {
                Task {
                    let earned = await ads.watch(for: reward)
                    message = earned ? nil : "最後まで見ると受け取れます"
                }
            } label: {
                PrimaryButtonLabel(text: ads.rewardedReady ? title : "広告を準備中…", systemImage: ads.rewardedReady ? "play.fill" : nil)
            }
            .buttonStyle(.plain)
            .disabled(!ads.rewardedReady)
            .opacity(ads.rewardedReady ? 1 : 0.5)
            if let message { Text(message).font(.caption).foregroundStyle(.secondary) }
        }
    }
}

/// 撮影用のサンプル（-demoLog）。保存はしない。数値はアプリに入っている公式値をそのまま使う。
enum DemoBites {
    static func make(now: Date = .now) -> [Bite] {
        let calendar = Calendar.current
        let items = Library.shared.chains.flatMap { chain in
            chain.menu.prefix(3).map { (chain.name, $0) }
        }
        guard !items.isEmpty else { return [] }
        return [0, 0, 1, 2, 2, 3, 3, 5, 6].enumerated().compactMap { index, back in
            let (place, item) = items[index * 2 % items.count]
            return calendar.date(byAdding: .day, value: -back, to: now).map {
                Bite(eatenAt: $0, name: item.name, place: place, kcal: item.calories,
                     protein: item.protein, fat: item.fat, carbs: item.carbs)
            }
        }
    }
}
