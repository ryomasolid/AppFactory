import SwiftData
import SwiftUI

/// 日記タブ：プロフィール・今日のページ・この1週間・これまでの日記。
struct DiaryScreen: View {
    @Query(sort: \Dog.order) private var dogs: [Dog]
    @AppStorage(CurrentDog.storageKey) private var currentKey = ""
    @State private var writing: DayPick?
    @State private var editingDog: Dog?
    @State private var path: [DayPage] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                if let dog = CurrentDog.pick(dogs, key: currentKey) {
                    VStack(spacing: 16) {
                        ProfileCard(dog: dog) { editingDog = dog }
                        TodayCard(dog: dog) { writing = DayPick(day: Date()) }
                        WeekCard(dog: dog)
                        pastPages(dog)
                    }
                    .padding(16)
                }
            }
            .background(Tone.paper)
            .navigationTitle("日記")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { DogSwitcher(dogs: dogs, currentKey: $currentKey) }
                ToolbarItem(placement: .primaryAction) {
                    Button { writing = DayPick(day: Date()) } label: { Image(systemName: "square.and.pencil") }
                        .accessibilityLabel("日記を書く")
                }
            }
            .navigationDestination(for: DayPage.self) { PageDetail(page: $0) }
            .sheet(item: $writing) { pick in
                if let dog = CurrentDog.pick(dogs, key: currentKey) { PageEditor(dog: dog, day: pick.day) }
            }
            .sheet(item: $editingDog) { DogEditor(dog: $0) }
            .onAppear {
                if Showcase.opensToday, path.isEmpty, let page = CurrentDog.pick(dogs, key: currentKey)?.diary.first {
                    path = [page]
                }
            }
        }
    }

    @ViewBuilder
    private func pastPages(_ dog: Dog) -> some View {
        let pages = dog.diary.filter { !Calendar.current.isDateInToday($0.day) }
        if !pages.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("これまでの日記").font(.headline).foregroundStyle(Tone.cocoa)
                LazyVStack(spacing: 10) {
                    ForEach(pages) { page in
                        NavigationLink(value: page) { PageRow(page: page) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

/// 「この日のページを書く」のシートを開くための包み。
struct DayPick: Identifiable {
    let id = UUID()
    let day: Date
}

private struct ProfileCard: View {
    let dog: Dog
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 14) {
                DogAvatar(dog: dog, size: 68)
                VStack(alignment: .leading, spacing: 4) {
                    Text(dog.name).font(.title2.bold()).foregroundStyle(Tone.cocoa)
                    if let birthday = dog.birthday {
                        let months = DogYears.months(from: birthday, to: Date())
                        Text("\(DogYears.text(months: months))・人でいうと\(DogYears.human(months: months))さい")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            Tag(text: DogYears.stage(months: months).label, tint: Tone.apricot)
                            Tag(text: dog.coat.label, tint: Tone.mute)
                        }
                    } else {
                        Text("お誕生日を入れると年齢が出ます").font(.footnote).foregroundStyle(.secondary)
                    }
                    if let note = anniversaryNote { Text(note).font(.footnote.weight(.semibold)).foregroundStyle(Tone.rose) }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(.tertiary)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("profile-card")
    }

    /// 1週間以内のお誕生日・うちの子記念日。
    private var anniversaryNote: String? {
        let now = Date()
        if let birthday = dog.birthday {
            let days = DogYears.daysUntilNext(anniversaryOf: birthday, from: now)
            if days == 0 { return "🎂 今日はお誕生日！おめでとう" }
            if days <= 7 { return "🎂 お誕生日まで あと\(days)日" }
        }
        if let home = dog.homeDay, !Calendar.current.isDateInToday(home) {
            let days = DogYears.daysUntilNext(anniversaryOf: home, from: now)
            if days == 0 { return "🏠 今日は うちの子記念日" }
            if days <= 7 { return "🏠 うちの子記念日まで あと\(days)日" }
        }
        return nil
    }
}

private struct TodayCard: View {
    let dog: Dog
    let onWrite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日のページ").font(.headline).foregroundStyle(Tone.cocoa)
                Spacer()
                Text(Words.long(Date())).font(.caption).foregroundStyle(.secondary)
            }
            if let page = dog.page(on: Date()) {
                NavigationLink(value: page) { PageSummary(page: page) }
                    .buttonStyle(.plain)
            } else {
                Text("きょうの\(dog.name)は どんな1日だった？").font(.subheadline).foregroundStyle(.secondary)
            }
            Button(action: onWrite) {
                Label(dog.page(on: Date()) == nil ? "きょうの日記を書く" : "きょうのページを書きたす", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("write-today")
        }
        .cardStyle()
    }
}

private struct WeekCard: View {
    let dog: Dog

    var body: some View {
        let now = Date()
        let pages = dog.pages ?? []
        let week = WalkTally.week(pages: pages.map { ($0.day, $0.walkMinutes, $0.walkCount) }, now: now)
        let streak = WalkTally.streak(days: pages.map(\.day), now: now)
        HStack(spacing: 0) {
            stat("figure.walk", "この7日の散歩", "\(week.minutes)分", "\(week.walkedDays)日")
            Divider().frame(height: 44)
            stat("flame.fill", "日記", "\(streak)日", "つづけて")
            Divider().frame(height: 44)
            stat("book.fill", "これまで", "\(pages.count)", "ページ")
        }
        .cardStyle(padding: 12)
    }

    private func stat(_ symbol: String, _ title: String, _ value: String, _ unit: String) -> some View {
        VStack(spacing: 3) {
            Label(title, systemImage: symbol).font(.caption2).foregroundStyle(.secondary).labelStyle(.titleAndIcon)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.title3.bold()).foregroundStyle(Tone.cocoa)
                Text(unit).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// 1ページの中身を短く（今日のカード・詳細の上）。
struct PageSummary: View {
    let page: DayPage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let data = page.photo, let image = UIImage(data: data)?.preparingThumbnail(of: CGSize(width: 240, height: 240)) {
                Image(uiImage: image).resizable().scaledToFill().frame(width: 76, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            VStack(alignment: .leading, spacing: 6) {
                FlowTags(page: page)
                if !page.note.isEmpty {
                    Text(page.note).font(.subheadline).lineLimit(3).foregroundStyle(.primary)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

/// きぶん・散歩・ごはんなどの札をならべる（入りきらなければ次の行へ）。
struct FlowTags: View {
    let page: DayPage

    var body: some View {
        Wrap(spacing: 6) {
            ForEach(tags.indices, id: \.self) { tags[$0] }
        }
    }

    private var tags: [Tag] {
        var list: [Tag] = []
        if let mood = page.mood { list.append(Tag(text: mood.label, symbol: mood.symbol, tint: Tone.rose)) }
        if page.walkCount > 0 || page.walkMinutes > 0 {
            list.append(Tag(text: page.walkMinutes > 0 ? "散歩\(page.walkMinutes)分" : "散歩\(page.walkCount)回", symbol: "figure.walk", tint: Tone.leaf))
        }
        if page.meals > 0 { list.append(Tag(text: "ごはん\(page.meals)回", symbol: "fork.knife", tint: Tone.apricot)) }
        if page.brushed { list.append(Tag(text: "歯みがき", symbol: "sparkle", tint: Tone.cocoa)) }
        if let poop = page.poop, poop.needsEye { list.append(Tag(text: "うんち\(poop.label)", tint: Tone.alert)) }
        if page.tear == .heavy { list.append(Tag(text: "涙やけ多め", tint: Tone.alert)) }
        return list
    }
}

/// 左から詰めて、幅が足りなくなったら折り返す。
struct Wrap: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let width = rows.map { $0.width }.max() ?? 0
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width.map { min($0, width) } ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.items {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var items: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.items.isEmpty ? size.width : current.width + spacing + size.width
            if needed > width, !current.items.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.items.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.items.append(index)
        }
        if !current.items.isEmpty { rows.append(current) }
        return rows
    }
}

private struct PageRow: View {
    let page: DayPage

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(page.day.formatted(.dateTime.day())).font(.title3.bold()).foregroundStyle(Tone.cocoa)
                Text(page.day.formatted(.dateTime.month(.defaultDigits).locale(Locale(identifier: "ja_JP")))).font(.caption2).foregroundStyle(.secondary)
                Text(page.day.formatted(.dateTime.weekday(.abbreviated).locale(Locale(identifier: "ja_JP")))).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(width: 42)
            if let data = page.photo, let image = UIImage(data: data)?.preparingThumbnail(of: CGSize(width: 180, height: 180)) {
                Image(uiImage: image).resizable().scaledToFill().frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if let mood = page.mood {
                        Image(systemName: mood.symbol).foregroundStyle(Tone.rose)
                        Text(mood.label).font(.subheadline.weight(.semibold))
                    }
                    if page.walkMinutes > 0 {
                        Text("散歩\(page.walkMinutes)分").font(.caption).foregroundStyle(Tone.leaf)
                    }
                }
                Text(page.note.isEmpty ? "（メモなし）" : page.note)
                    .font(.footnote)
                    .foregroundStyle(page.note.isEmpty ? .tertiary : .secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .cardStyle(padding: 12)
    }
}
