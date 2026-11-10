import Foundation

/// 会話の 1ページ。話している人が いれば 名前を 本文と べつの 枠に 出す。
struct MessagePage: Equatable {
    /// 話している人（「ねぶたし」など）。地の文なら nil。
    var speaker: String?
    /// 本文の 行。せりふは 1文ずつ 1行（長い 文は 画面で ことばの 区切りで 折り返す）。
    var lines: [String]
}

/// せりふの 行を ページに わける。
///
/// せりふは `名前「…` で はじまり、つづきの 行は `　`（全角スペース）で はじまる 書きかたに なっている。
/// 書いた ときの 改行は 画面の はばと 関係が ないので、そのまま 出すと 文の 途中で 行が かわって 読みにくい。
/// そこで 1人ぶんの せりふを 1つの 文章に つなげ、文の おわり（。！？）で だけ 改行しなおす。
enum MessagePaging {
    /// 1ページに 入れる 字数の めやす（スペースを ふくむ）。3行 ぐらい。
    static let pageLength = 54
    /// 地の文は これまでどおり 3行ずつ。
    static let narrationLines = 3

    static func pages(from lines: [String]) -> [MessagePage] {
        var pages: [MessagePage] = []
        var narration: [String] = []

        func flushNarration() {
            for start in stride(from: 0, to: narration.count, by: narrationLines) {
                pages.append(MessagePage(lines: Array(narration[start..<min(start + narrationLines, narration.count)])))
            }
            narration = []
        }

        var index = 0
        while index < lines.count {
            let line = lines[index]
            guard let (name, first) = speech(line) else {
                narration.append(line)
                index += 1
                continue
            }
            flushNarration()
            // 「　」で はじまる 行は 同じ人の せりふの つづき。」で おわったら そこまで。
            var parts = [first]
            var closed = line.hasSuffix("」")
            index += 1
            while !closed, index < lines.count, lines[index].hasPrefix("　") {
                let next = String(lines[index].drop { $0 == "　" })
                parts.append(next)
                closed = next.hasSuffix("」")
                index += 1
            }
            var text = parts.joined(separator: " ")
            if text.hasSuffix("」") { text.removeLast() }
            for chunk in pack(sentences(text)) {
                pages.append(MessagePage(speaker: name, lines: chunk))
            }
        }
        flushNarration()
        return pages
    }

    /// `名前「せりふ` なら 名前と「の あとを 返す。看板の 「…」（名前なし）や 地の文は nil。
    static func speech(_ line: String) -> (name: String, rest: String)? {
        guard let open = line.firstIndex(of: "「"), open != line.startIndex else { return nil }
        let name = String(line[..<open])
        // 名前は みじかい ことば（地の文の とちゅうの「」を 名前と まちがえない）。
        guard name.count <= 12, !name.hasPrefix("　"), !name.contains(where: { "。！？、（）".contains($0) }) else { return nil }
        return (name.trimmingCharacters(in: .whitespaces), String(line[line.index(after: open)...]))
    }

    /// 文の おわり（。！？ と そのあとの 」）の あとで 切る。
    static func sentences(_ text: String) -> [String] {
        var result: [String] = []
        var current = ""
        let characters = Array(text)
        for (i, character) in characters.enumerated() {
            current.append(character)
            let ends = "。！？".contains(character)
            let next = i + 1 < characters.count ? characters[i + 1] : nil
            // 「……ですか？」のように 文が つづく ときは 切らない（つぎが 空白か おわりの ときだけ）。
            if ends, next == nil || next == " " {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            }
        }
        let rest = current.trimmingCharacters(in: .whitespaces)
        if !rest.isEmpty { result.append(rest) }
        return result
    }

    /// 文を ページに つめる。1文が 長すぎても 文の 途中では ページを わけない。
    static func pack(_ sentences: [String]) -> [[String]] {
        var pages: [[String]] = []
        var page: [String] = []
        var length = 0
        for sentence in sentences {
            if !page.isEmpty, length + sentence.count > pageLength {
                pages.append(page)
                page = []
                length = 0
            }
            page.append(sentence)
            length += sentence.count
        }
        if !page.isEmpty { pages.append(page) }
        return pages
    }
}
