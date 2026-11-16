import SwiftData
import SwiftUI

/// きょうタブ：プロフィール・見守り・体重のひと押し記録・きょうの記録・最近の日。
struct TodayTab: View {
    @Query(sort: \Bird.sortIndex) private var birds: [Bird]
    @AppStorage(Picked.key) private var picked = ""
    @State private var editingDay: DayTarget?
    @State private var editingBird: Bird?

    var body: some View {
        NavigationStack {
            ScrollView {
                if let bird = Picked.bird(in: birds, tag: picked) {
                    VStack(spacing: 14) {
                        header(bird)
                        ForEach(Watchlist.items(facts(bird))) { WatchCard(item: $0) }
                        QuickWeigh(bird: bird)
                        todayCard(bird)
                        recent(bird)
                    }
                    .padding(16)
                }
            }
            .background(Hue.ground)
            .navigationTitle("きょう")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { BirdMenu(birds: birds, tag: $picked) } }
            .sheet(item: $editingDay) { t in
                if let bird = Picked.bird(in: birds, tag: picked) { LogSheet(bird: bird, day: t.day) }
            }
            .sheet(item: $editingBird) { BirdForm(bird: $0) }
        }
    }

    private func facts(_ bird: Bird) -> Watchlist.Facts {
        let now = Date()
        let line = bird.timeline
        let latest = line.last
        let young = Warmth.isYoung(hatchedOn: bird.hatchedOn, now: now)
        let recentLogs = line.reversed().filter { Calendar.current.dateComponents([.day], from: $0.day, to: now).day ?? 99 <= 1 }
        return Watchlist.Facts(
            weight: GramWatch.read(line.compactMap { log in log.grams.map { (log.day, $0) } }),
            lastLook: recentLogs.first?.look,
            recentDroppings: recentLogs.map(\.dropping),
            warmth: line.last(where: { $0.roomCelsius != nil && Calendar.current.dateComponents([.day], from: $0.day, to: now).day ?? 99 <= 1 })?.roomCelsius.map { Warmth.verdict(celsius: $0, young: young) },
            eggsIn14Days: Seasons.recentEggs(line.filter(\.laidEgg).map(\.day), now: now),
            isFemale: bird.sex == .female,
            moltDays: latest == nil ? 0 : Seasons.moltDays(line.filter(\.molting).map(\.day), now: now)
        )
    }

    private func header(_ bird: Bird) -> some View {
        Button { editingBird = bird } label: {
            HStack(spacing: 14) {
                BirdBadge(bird: bird, size: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text(bird.name).font(.title2.bold()).foregroundStyle(Hue.ink)
                    HStack(spacing: 6) {
                        if let h = bird.hatchedOn { Chip(text: Warmth.ageText(hatchedOn: h, now: Date()), color: Hue.sky) }
                        Chip(text: bird.plumage.label, color: Hue.leaf)
                        if bird.sex != .unknown { Chip(text: bird.sex.label, color: Hue.blush) }
                    }
                    if let home = bird.cameHomeOn {
                        let days = (Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: home), to: Calendar.current.startOfDay(for: Date())).day ?? 0) + 1
                        Text("お迎えから \(days)日目").font(.caption).foregroundStyle(Hue.soft)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(.tertiary)
            }
            .tile()
        }
        .buttonStyle(.plain)
    }

    private func todayCard(_ bird: Bird) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("きょうの記録").font(.headline).foregroundStyle(Hue.ink)
                Spacer()
                Text(Say.ymd(Date())).font(.caption).foregroundStyle(Hue.soft)
            }
            if let log = bird.log(on: Date()), !log.isEmpty {
                LogSummary(log: log)
            } else {
                Text("様子・フン・放鳥・室温をつけておくと、いつもとの違いに気づけます。").font(.subheadline).foregroundStyle(Hue.soft)
            }
            Button { editingDay = DayTarget(day: Date()) } label: {
                Label("きょうの記録をつける", systemImage: "square.and.pencil").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("open-today")
        }
        .tile()
    }

    @ViewBuilder
    private func recent(_ bird: Bird) -> some View {
        let past = bird.timeline.reversed().filter { !Calendar.current.isDateInToday($0.day) && !$0.isEmpty }.prefix(30)
        if !past.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("さいきんの記録").font(.headline).foregroundStyle(Hue.ink).padding(.top, 4)
                ForEach(Array(past)) { log in
                    Button { editingDay = DayTarget(day: log.day) } label: { DayRow(log: log) }
                        .buttonStyle(.plain)
                }
            }
        }
    }
}

struct DayTarget: Identifiable {
    let id = UUID()
    let day: Date
}

private struct WatchCard: View {
    let item: Watchlist.Item

    private var color: Color {
        switch item.severity {
        case .urgent: Hue.danger
        case .caution: Hue.lemon
        case .note: Hue.sky
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.severity == .note ? "info.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(color)
                .font(.title3)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title).font(.subheadline.weight(.bold)).foregroundStyle(Hue.ink)
                Text(item.detail).font(.caption).foregroundStyle(Hue.soft)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(color.opacity(0.35), lineWidth: 1))
    }
}

/// 体重をその場で1回記録する。
private struct QuickWeigh: View {
    let bird: Bird
    @Environment(\.modelContext) private var context
    @State private var text = ""
    @FocusState private var focused: Bool

    private var value: Double? {
        Double(text.replacingOccurrences(of: ",", with: ".")).flatMap { (10...120).contains($0) ? $0 : nil }
    }

    var body: some View {
        let reading = GramWatch.read(bird.timeline.compactMap { l in l.grams.map { (l.day, $0) } })
        let todays = bird.log(on: Date())?.grams
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("きょうの体重").font(.headline).foregroundStyle(Hue.ink)
                Spacer()
                if let usual = reading?.usual { Text("ふだん \(GramWatch.text(usual))").font(.caption).foregroundStyle(Hue.soft) }
            }
            if let todays, !focused {
                HStack(alignment: .firstTextBaseline) {
                    Text(GramWatch.text(todays)).font(.system(size: 38, weight: .bold, design: .rounded)).foregroundStyle(Hue.sky)
                    if let usual = reading?.usual {
                        let diff = ((todays - usual) * 10).rounded() / 10
                        Text(diff == 0 ? "ふだんどおり" : "ふだんより \(diff > 0 ? "+" : "")\(diff.formatted(.number.precision(.fractionLength(1))))g")
                            .font(.subheadline).foregroundStyle(Hue.soft)
                    }
                    Spacer()
                    Button("はかりなおす") { text = String(format: "%.1f", todays); focused = true }.font(.footnote)
                }
            } else {
                HStack(spacing: 10) {
                    TextField("35.0", text: $text)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .focused($focused)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Hue.ground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityIdentifier("quick-grams")
                    Text("g").font(.title3).foregroundStyle(Hue.soft)
                    Button("記録", action: save)
                        .buttonStyle(.borderedProminent)
                        .disabled(value == nil)
                        .accessibilityIdentifier("save-grams")
                }
                Text("朝ごはんの前、同じ時間にはかると、変化がわかりやすくなります。").font(.caption).foregroundStyle(Hue.soft)
            }
        }
        .tile()
    }

    private func save() {
        guard let value else { return }
        let log = bird.log(on: Date()) ?? {
            let new = DayLog(day: Date(), bird: bird)
            context.insert(new)
            return new
        }()
        log.grams = value
        try? context.save()
        text = ""
        focused = false
    }
}

struct LogSummary: View {
    let log: DayLog

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let data = log.picture, let ui = UIImage(data: data)?.preparingThumbnail(of: CGSize(width: 240, height: 240)) {
                Image(uiImage: ui).resizable().scaledToFill().frame(width: 76, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            VStack(alignment: .leading, spacing: 6) {
                Flow(spacing: 6) {
                    if let look = log.look { Chip(text: look.label, icon: look.symbol, color: look.warning ? Hue.danger : Hue.blush) }
                    if let d = log.dropping { Chip(text: "フン \(d.label)", color: d.worrying ? Hue.danger : Hue.leaf) }
                    if log.outsideMinutes > 0 { Chip(text: "放鳥\(log.outsideMinutes)分", icon: "bird", color: Hue.sky) }
                    if let c = log.roomCelsius { Chip(text: "\(c.formatted(.number.precision(.fractionLength(1))))℃", icon: "thermometer.medium", color: Hue.lemon) }
                    if log.molting { Chip(text: "換羽", icon: "leaf", color: Hue.soft) }
                    if log.laidEgg { Chip(text: "産卵", icon: "oval.portrait", color: Hue.blush) }
                }
                if !log.memo.isEmpty { Text(log.memo).font(.subheadline).lineLimit(3) }
            }
            Spacer(minLength: 0)
        }
    }
}

private struct DayRow: View {
    let log: DayLog

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 1) {
                Text("\(Calendar.current.component(.day, from: log.day))").font(.headline).foregroundStyle(Hue.ink)
                Text(log.day.formatted(.dateTime.month(.defaultDigits).locale(Say.jp)) + "・" + log.day.formatted(.dateTime.weekday(.abbreviated).locale(Say.jp))).font(.caption2).foregroundStyle(Hue.soft)
            }
            .frame(width: 44)
            if let data = log.picture, let ui = UIImage(data: data)?.preparingThumbnail(of: CGSize(width: 150, height: 150)) {
                Image(uiImage: ui).resizable().scaledToFill().frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if let g = log.grams { Text(GramWatch.text(g)).font(.subheadline.weight(.bold)).foregroundStyle(Hue.sky) }
                    if let look = log.look { Image(systemName: look.symbol).foregroundStyle(look.warning ? Hue.danger : Hue.blush).font(.caption) }
                    if log.outsideMinutes > 0 { Text("放鳥\(log.outsideMinutes)分").font(.caption).foregroundStyle(Hue.soft) }
                    if log.molting { Text("換羽").font(.caption).foregroundStyle(Hue.soft) }
                }
                if !log.memo.isEmpty { Text(log.memo).font(.footnote).foregroundStyle(Hue.soft).lineLimit(1) }
            }
            Spacer(minLength: 0)
        }
        .tile(12)
    }
}

/// 札を左から詰め、入りきらなければ折り返す。
struct Flow: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let limit = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, line: CGFloat = 0, widest: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > 0, x + s.width > limit { y += line + spacing; x = 0; line = 0 }
            x += (x > 0 ? spacing : 0) + s.width
            line = max(line, s.height)
            widest = max(widest, x)
        }
        return CGSize(width: proposal.width ?? widest, height: y + line)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, line: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > bounds.minX, x + s.width > bounds.maxX { y += line + spacing; x = bounds.minX; line = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            line = max(line, s.height)
        }
    }
}
