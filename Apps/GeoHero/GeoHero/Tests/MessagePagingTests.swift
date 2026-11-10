import Testing
@testable import GeoHero

/// 会話の ページわけ。名前は べつの 枠、せりふは 文の おわりで だけ 改行する。
struct MessagePagingTests {

    @Test func speakerIsSeparatedAndSentencesAreRejoined() {
        let pages = MessagePaging.pages(from: [
            "ねぶたし「十和田湖へは 弘前の マタギに 案内を たのむんだ。",
            "　弘前は 街の 南西、岩木山の ふもとだ。」",
        ])
        #expect(pages == [MessagePage(speaker: "ねぶたし", lines: [
            "十和田湖へは 弘前の マタギに 案内を たのむんだ。",
            "弘前は 街の 南西、岩木山の ふもとだ。",
        ])])
    }

    /// 書いたときの 改行が 文の とちゅうでも、つなげて 1文に する。
    @Test func midSentenceBreaksAreJoined() {
        let pages = MessagePaging.pages(from: [
            "ちょうろう「十和田湖は 青森の 南東。 湖の 東の ほとりに ほこらが ある。",
            "　弘前の ものの 話を きいておけば ちしきで おいうちが きまるぞ。」",
        ])
        #expect(pages.first?.speaker == "ちょうろう")
        #expect(pages.flatMap(\.lines) == [
            "十和田湖は 青森の 南東。",
            "湖の 東の ほとりに ほこらが ある。",
            "弘前の ものの 話を きいておけば ちしきで おいうちが きまるぞ。",
        ])
    }

    /// 地の文・看板は これまでどおり。せりふの あとの 地の文は 名前なしの ページ。
    @Test func narrationKeepsItsOwnPages() {
        let pages = MessagePaging.pages(from: [
            "ねぶたし「よし、この 金魚ねぶたを もっていけ。」",
            "金魚ねぶたの あかりを てにいれた！",
            "かんばんに こう かいてある。",
            "「ねぶたの家 ワ・ラッセ」",
        ])
        #expect(pages.count == 2)
        #expect(pages[0].speaker == "ねぶたし")
        #expect(pages[1] == MessagePage(speaker: nil, lines: [
            "金魚ねぶたの あかりを てにいれた！", "かんばんに こう かいてある。", "「ねぶたの家 ワ・ラッセ」",
        ]))
    }

    /// 名前に 空白が ある人（ばんやの おやじ）・つづけて 話す 2人（手長・足長）。
    @Test func namesWithSpacesAndTwoSpeakers() {
        let pages = MessagePaging.pages(from: [
            "手長「わしらが 手長足長じゃ。」",
            "足長「わらじは もう はかせんぞ。",
            "　この 山で ふみつぶして くれよう！」",
            "ばんやの おやじ「羅臼の こんぶは だしの 王さまよ。」",
        ])
        #expect(pages.map(\.speaker) == ["手長", "足長", "ばんやの おやじ"])
    }

    /// 長い せりふは 文の 切れ目で ページを わける（文の とちゅうでは わけない）。
    @Test func longSpeechSplitsBetweenSentences() {
        let pages = MessagePaging.pages(from: [
            "ねぶたし「わしは ねぶた師。 紙と 竹で ねぶたを つくる しょくにんだ。",
            "　ねぶたは 大きな 人形の 中に あかりを ともす まつりの だしよ。",
            "　だが ある夜、十和田湖から りゅうが とんできて",
            "　ねぶたの 火を ぜんぶ けしていった。 八郎太郎に ちがいない。",
            "　十和田湖へ いくなら 弘前の マタギに 案内を たのむと いい。」",
        ])
        #expect(pages.count >= 2)
        #expect(pages.allSatisfy { $0.speaker == "ねぶたし" })
        #expect(pages.flatMap(\.lines).contains("だが ある夜、十和田湖から りゅうが とんできて ねぶたの 火を ぜんぶ けしていった。"))
        for page in pages { #expect(page.lines.allSatisfy { "。！？".contains($0.last!) }) }
    }

    /// どの 街の人の せりふも ページに できて、本文から 名前と「」が 消える。
    @Test func everyVillagerLineBecomesReadable() {
        for map in World.all.values {
            for npc in map.npcs {
                guard case let .villager(lines) = npc.role else { continue }
                for page in MessagePaging.pages(from: lines) where page.speaker != nil {
                    for line in page.lines {
                        #expect(!line.hasSuffix("」") || line.contains("「"), "\(map.id): \(line)")
                        #expect(!line.hasPrefix("　"), "\(map.id): \(line)")
                    }
                }
            }
        }
    }
}
