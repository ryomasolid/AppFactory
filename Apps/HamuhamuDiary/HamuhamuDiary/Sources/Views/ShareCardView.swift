import SwiftData
import SwiftUI

/// SNS に投稿する記録カードのプレビューと共有。
struct ShareCardView: View {
    let record: DiaryRecord

    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [HamsterProfile]

    static let hashtags = "#はむはむ日記 #ハムスター #ハムスターのいる生活"

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer(minLength: 0)
                RecordShareCard(record: record, profile: profiles.first)
                    .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
                    .padding(.horizontal, 24)
                Spacer(minLength: 0)
                VStack(spacing: 8) {
                    Button(action: share) {
                        Label("画像をシェアする", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 14))
                    Text("Instagram・X・LINE などに投稿できます")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
            .creamBackground()
            .navigationTitle("シェアカード")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("閉じる") { dismiss() } }
            }
        }
    }

    private func share() {
        // 投稿先で見栄えがそろうよう、端末がダークモードでも明るい配色で書き出す。
        let renderer = ImageRenderer(
            content: RecordShareCard(record: record, profile: profiles.first)
                .frame(width: 360)
                .environment(\.colorScheme, .light)
        )
        renderer.scale = 3
        var items: [Any] = [Self.hashtags]
        if let image = renderer.uiImage { items.insert(image, at: 0) }
        ActivitySheet.present(items)
    }
}

/// 画像にするカード本体（4:5 の縦長。Instagram のフィードでそのまま映える比率）。
struct RecordShareCard: View {
    let record: DiaryRecord
    let profile: HamsterProfile?

    // カードはテーマに関係なく固定の明るい配色にする。
    private let cream = Color(red: 1, green: 0.973, blue: 0.941)
    private let ink = Color(red: 0.18, green: 0.14, blue: 0.13)
    private let sub = Color(red: 0.42, green: 0.36, blue: 0.31)
    private let orange = Color(red: 0.91, green: 0.50, blue: 0.29)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 写真の縦横比にカードの大きさを引っぱられないよう、枠（Color.clear）を先に決めてから重ねる。
            Color.clear
                .overlay { PhotoView(path: record.photoPath) }
                .clipped()
                .overlay(alignment: .topLeading) {
                    Text(record.date.formatted(.dateTime.year().month(.defaultDigits).day().weekday(.abbreviated)))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.9), in: Capsule())
                        .padding(10)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(profile?.name ?? String(localized: "うちのハムちゃん"))
                    .font(.title2.bold())
                    .foregroundStyle(ink)
                    .lineLimit(1)
                if let birth = profile?.birthDate {
                    Text(HamsterAge.text(birthDate: birth, at: record.date))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(orange.opacity(0.15), in: Capsule())
                }
                Spacer(minLength: 4)
                if let weight = record.weight {
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(Formatting.weight(weight))
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(orange)
                        Text("g").font(.subheadline.bold()).foregroundStyle(sub)
                    }
                }
            }
            .padding(.horizontal, 4)

            if !record.memo.isEmpty {
                Text(record.memo)
                    .font(.subheadline)
                    .foregroundStyle(sub)
                    .lineLimit(3)
                    .padding(.horizontal, 4)
            }

            HStack(spacing: 6) {
                Image("AppLogo")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                Text("はむはむ日記").font(.caption.bold()).foregroundStyle(sub)
                Spacer()
                Text("#ハムスターのいる生活").font(.caption).foregroundStyle(sub.opacity(0.7))
            }
            .padding(.horizontal, 4)
        }
        .padding(14)
        .aspectRatio(4 / 5, contentMode: .fit)
        .background(cream, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
