import SwiftUI

/// 1日のページを読む。ここから編集とシェア。
struct PageDetail: View {
    let page: DayPage
    @State private var editing = false
    @State private var shareImage: Image?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let data = page.photo, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text(Words.long(page.day)).font(.caption).foregroundStyle(.secondary)
                    if let mood = page.mood {
                        Label(mood.label, systemImage: mood.symbol).font(.title3.bold()).foregroundStyle(Tone.rose)
                    }
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                        row("figure.walk", "おさんぽ", walkText)
                        row("fork.knife", "ごはん", page.meals > 0 ? "\(page.meals)回" : "―")
                        row("sparkle", "歯みがき", page.brushed ? "した" : "―")
                        row("leaf", "うんち", page.poop?.label ?? "―")
                        row("drop", "涙やけ", page.tear?.label ?? "―")
                    }
                    .font(.subheadline)
                    if !page.note.isEmpty {
                        Divider()
                        Text(page.note).font(.body)
                    }
                }
                .cardStyle()
            }
            .padding(16)
        }
        .background(Tone.paper)
        .navigationTitle(Words.day(page.day))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if let shareImage {
                    ShareLink(item: shareImage, preview: SharePreview("\(page.dog?.name ?? "")の日記", image: shareImage)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("share-page")
                }
                Button("編集") { editing = true }
            }
        }
        .sheet(isPresented: $editing, onDismiss: render) {
            if let dog = page.dog { PageEditor(dog: dog, day: page.day) }
        }
        .onAppear(perform: render)
    }

    private var walkText: String {
        switch (page.walkCount, page.walkMinutes) {
        case (0, 0): "―"
        case (let n, 0): "\(n)回"
        case (0, let m): "\(m)分"
        case (let n, let m): "\(n)回・\(m)分"
        }
    }

    private func row(_ symbol: String, _ title: String, _ value: String) -> some View {
        GridRow {
            Label(title, systemImage: symbol).foregroundStyle(.secondary)
            Text(value)
        }
    }

    @MainActor
    private func render() {
        guard page.modelContext != nil else { return }
        let renderer = ImageRenderer(content: ShareCard(page: page).environment(\.colorScheme, .light))
        renderer.scale = 3
        if let ui = renderer.uiImage { shareImage = Image(uiImage: ui) }
    }
}

/// SNS に貼る1枚（4:5）。
struct ShareCard: View {
    let page: DayPage

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Color(UIColor(hex: 0xF6E6D6))
                if let data = page.photo, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    PoodleFace(coat: page.dog?.coat ?? .apricot, size: 170)
                }
            }
            .frame(width: 328, height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            HStack(alignment: .firstTextBaseline) {
                Text(page.dog?.name ?? "").font(.system(size: 22, weight: .bold, design: .rounded))
                Text(Words.long(page.day)).font(.system(size: 12)).foregroundStyle(Color(UIColor(hex: 0x8E8077)))
                Spacer()
                if let mood = page.mood {
                    Label(mood.label, systemImage: mood.symbol).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color(UIColor(hex: 0xD46F7C)))
                }
            }
            if !page.note.isEmpty {
                Text(page.note).font(.system(size: 14)).lineLimit(3)
            }
            Spacer(minLength: 0)
            HStack(spacing: 5) {
                PoodleFace(coat: .apricot, size: 16)
                Text("といぷー日記").font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Color(UIColor(hex: 0x8B5A3C)))
        }
        .foregroundStyle(Color(UIColor(hex: 0x3B2A22)))
        .padding(16)
        .frame(width: 360, height: 450)
        .background(Color(UIColor(hex: 0xFFFBF6)))
    }
}
