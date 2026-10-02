import Foundation

/// オリジナルの曲。どれも 4/4 拍子・8小節のループで、`|` は小節の区切り（1小節 = 8分音符8つ）。
/// パートごとの長さがそろっていることはテストで確かめる。
extension MusicTrack {
    var score: Score {
        switch self {
        case .title:
            // タイトル。民謡の 五音で にぎやかに。
            Score(tempo: 120, voices: [
                lead("o4 d8 e8 g8 a8 b4 a4 | g8 a8 g8 e8 d4 e4 | g8 a8 b8 >d8 e4 d4< | b8 a8 g8 e8 a2 | >d8 e8 d8< b8 a4 g4 | e8 g8 a8 b8 >d4< b4 | a8 g8 e8 d8 e4 g4 | d2 r2"),
                bass("o3 g8 >g8< g8 >g8< g8 >g8< g8 >g8< | e8 >e8< e8 >e8< e8 >e8< e8 >e8< | g8 >g8< g8 >g8< g8 >g8< g8 >g8< | a8 >a8< a8 >a8< a8 >a8< a8 >a8< | b8 >b8< b8 >b8< b8 >b8< b8 >b8< | e8 >e8< e8 >e8< e8 >e8< e8 >e8< | a8 >a8< a8 >a8< a8 >a8< a8 >a8< | d4 a4 d2"),
                drums("c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8"),
            ])
        case .fieldAomori:
            // 青森の 野原。ねぶた囃子のような はねる リズム。
            Score(tempo: 138, voices: [
                lead("o4 a8 a8 >c8 d8 e4 d4< | >c8 d8 c8< a8 g4 a4 | e8 g8 a8 >c8 d4 c8< a8 | g8 a8 g8 e8 d4 r4 | a8 >c8 d8 e8 g4 e4 | d8 e8 d8 c8< a4 g4 | e8 g8 a8 >c8< a8 g8 e8 g8 | a2 r4 e4"),
                bass("o2 a8 >a8< a8 >a8< a8 >a8< a8 >a8< | a8 >a8< a8 >a8< a8 >a8< a8 >a8< | e8 >e8< e8 >e8< e8 >e8< e8 >e8< | d8 >d8< d8 >d8< d8 >d8< d8 >d8< | a8 >a8< a8 >a8< a8 >a8< a8 >a8< | d8 >d8< d8 >d8< d8 >d8< d8 >d8< | e8 >e8< e8 >e8< e8 >e8< e8 >e8< | a4 >e4< a2"),
                drums("c8 c8 r8 c8 c8 r8 c8 r8 c8 c8 r8 c8 c8 r8 c8 r8 c8 c8 r8 c8 c8 r8 c8 r8 c8 c8 r8 c8 c8 r8 c8 r8 c8 c8 r8 c8 c8 r8 c8 r8 c8 c8 r8 c8 c8 r8 c8 r8 c8 c8 r8 c8 c8 r8 c8 r8 c8 c8 r8 c8 c8 r8 c8 r8"),
            ])
        case .fieldAkita:
            // 秋田の 野原。ゆったりした 民謡ふう。
            Score(tempo: 116, voices: [
                lead("o4 e4. g8 a4 >c4< | b8 a8 g8 e8 a2 | >c4. d8 e4 d4 | c8< b8 a8 g8 e2 | g4. a8 b4 >d4 | e8 d8 c8< b8 a4 g4 | e8 g8 a8 b8 g4 e4 | a2. r4", duty: 0.5, volume: 0.10),
                bass("o2 a2 e2 | a2 a2 | f2 c2 | e2 e2 | g2 d2 | c2 e2 | a2 e2 | a2 a2"),
                drums("c4 r4 c8 c8 r4 c4 r4 c8 c8 r4 c4 r4 c8 c8 r4 c4 r4 c8 c8 r4 c4 r4 c8 c8 r4 c4 r4 c8 c8 r4 c4 r4 c8 c8 r4 c4 r4 c8 c8 r4"),
            ])
        case .fieldIwate:
            // 岩手の 野原。ひろい 大地を 大きく。
            Score(tempo: 110, voices: [
                lead("o4 g4. a8 b4 >d4 | e4 d8 c8< b2 | a4. b8 >c4 e4 | d4 c8< b8 a2 | g4. b8 >d4 g4 | f+4 e8 d8 e2 | c8 d8 e8 f+8 g4 d4 | g2. r4", duty: 0.5, volume: 0.10),
                bass("o2 g2 d2 | c2 g2 | a2 e2 | d2 d2 | g2 b2 | c2 c2 | a2 d2 | g2 g2"),
                drums("c4 r4 r4 c8 c8 c4 r4 r4 c8 c8 c4 r4 r4 c8 c8 c4 r4 r4 c8 c8 c4 r4 r4 c8 c8 c4 r4 r4 c8 c8 c4 r4 r4 c8 c8 c4 r4 r4 c8 c8"),
            ])
        case .fieldMiyagi:
            // 宮城の 野原。明るい 行進曲。
            Score(tempo: 128, voices: [
                lead("o4 c8 e8 g8 >c8< b4 g4 | a8 g8 f8 a8 g2 | e8 g8 >c8 e8 d4 c4< | b8 >c8 d8< b8 >c2< | f8 a8 >c8< a8 g4 e4 | f8 g8 a8 b8 >c4< g4 | a8 b8 >c8 d8 e4 d4 | c2 r4 g4"),
                bass("o2 c8 >c8< c8 >c8< c8 >c8< c8 >c8< | f8 >f8< f8 >f8< f8 >f8< f8 >f8< | c8 >c8< c8 >c8< c8 >c8< c8 >c8< | g8 >g8< g8 >g8< g8 >g8< g8 >g8< | f8 >f8< f8 >f8< f8 >f8< f8 >f8< | f8 >f8< f8 >f8< f8 >f8< f8 >f8< | g8 >g8< g8 >g8< g8 >g8< g8 >g8< | c4 g4 c2"),
                drums("c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8"),
            ])
        case .fieldFukushima:
            // 福島の 野原。
            Score(tempo: 122, voices: [
                lead("o4 d8 f8 a8 >d8< c4 a4 | b-8 a8 g8 f8 g2 | f8 a8 >c8 f8 e4 d4< | >c8< b-8 a8 g8 a2 | b-8 >d8 f8 d8< >c4< a4 | g8 a8 b-8 >c8 d4< a4 | b-8 a8 g8 e8 f4 e4 | d2 r4 a4"),
                bass("o2 d8 >d8< d8 >d8< d8 >d8< d8 >d8< | g8 >g8< g8 >g8< g8 >g8< g8 >g8< | f8 >f8< f8 >f8< f8 >f8< f8 >f8< | a8 >a8< a8 >a8< a8 >a8< a8 >a8< | b-8 >b-8< b-8 >b-8< b-8 >b-8< b-8 >b-8< | g8 >g8< g8 >g8< g8 >g8< g8 >g8< | a8 >a8< a8 >a8< a8 >a8< a8 >a8< | d4 a4 d2"),
                drums("c8 r8 c8 r8 c8 c8 r8 c8 c8 r8 c8 r8 c8 c8 r8 c8 c8 r8 c8 r8 c8 c8 r8 c8 c8 r8 c8 r8 c8 c8 r8 c8 c8 r8 c8 r8 c8 c8 r8 c8 c8 r8 c8 r8 c8 c8 r8 c8 c8 r8 c8 r8 c8 c8 r8 c8 c8 r8 c8 r8 c8 c8 r8 c8"),
            ])
        case .fieldYamagata:
            // 山形の 野原。花笠音頭のような 手びょうし。
            Score(tempo: 136, voices: [
                lead("o4 e8 e8 g8 a8 >c4< a4 | g8 a8 g8 e8 d4 e4 | g8 a8 >c8 d8 e4 d8 c8< | a8 >c8< a8 g8 e2 | a8 >c8 d8 e8 g4 e4 | d8 e8 d8 c8< a4 g4 | e8 g8 a8 >c8 d8 c8< a8 g8 | a2 r4 e4"),
                bass("o2 a8 >a8< a8 >a8< a8 >a8< a8 >a8< | e8 >e8< e8 >e8< e8 >e8< e8 >e8< | a8 >a8< a8 >a8< a8 >a8< a8 >a8< | e8 >e8< e8 >e8< e8 >e8< e8 >e8< | a8 >a8< a8 >a8< a8 >a8< a8 >a8< | d8 >d8< d8 >d8< d8 >d8< d8 >d8< | e8 >e8< e8 >e8< e8 >e8< e8 >e8< | a4 e4 a2"),
                drums("c8 c8 c8 r8 c8 r8 c8 r8 c8 c8 c8 r8 c8 r8 c8 r8 c8 c8 c8 r8 c8 r8 c8 r8 c8 c8 c8 r8 c8 r8 c8 r8 c8 c8 c8 r8 c8 r8 c8 r8 c8 c8 c8 r8 c8 r8 c8 r8 c8 c8 c8 r8 c8 r8 c8 r8 c8 c8 c8 r8 c8 r8 c8 r8"),
            ])
        case .villageNorth:
            // 青森・秋田の 街。
            Score(tempo: 90, voices: [
                lead("o4 a4 >c8 d8 e4 d4 | c8< a8 g8 a8 e2 | g4 a8 >c8 d4 e4 | d8 c8< a8 g8 a2 | >e4 d8 c8< a4 g4 | e8 g8 a8 >c8< b-2 | a4 g8 e8 d4 e4 | a2. r4", duty: 0.5, volume: 0.10),
                bass("o3 a2 e2 | a2 a2 | c2 g2 | d2 a2 | c2 a2 | e2 g2 | d2 e2 | a2 a2"),
            ])
        case .villageMiddle:
            // 岩手・宮城の 街。
            Score(tempo: 96, voices: [
                lead("o4 g4 b8 >d8 e4 d4< | b8 a8 g8 a8 b2 | >c4 e8 d8 c4< b4 | a8 g8 e8 g8 a2 | b4 >d8 e8 g4 e4 | d8 c8< b8 a8 g4 e4 | d8 e8 g8 a8 b4 a4 | g2. r4", duty: 0.5, volume: 0.10),
                bass("o3 g2 d2 | e2 g2 | c2 g2 | d2 d2 | g2 e2 | c2 g2 | c2 d2 | g2 g2"),
            ])
        case .villageSouth:
            // 福島・山形の 街。
            Score(tempo: 100, voices: [
                lead("o4 f4 a8 >c8 d4 c4< | a8 g8 f8 g8 a2 | b-4 >d8 c8< b-4 a4 | g8 f8 d8 f8 g2 | a4 >c8 d8 f4 d4 | c8< a8 g8 f8 d4 f4 | g8 a8 >c8< b-8 a4 g4 | f2. r4", duty: 0.5, volume: 0.10),
                bass("o3 f2 c2 | d2 c2 | b-2 f2 | g2 c2 | f2 d2 | a2 d2 | b-2 c2 | f2 f2"),
                drums("c8 r8 r8 c8 c8 r8 r8 c8 c8 r8 r8 c8 c8 r8 r8 c8 c8 r8 r8 c8 c8 r8 r8 c8 c8 r8 r8 c8 c8 r8 r8 c8 c8 r8 r8 c8 c8 r8 r8 c8 c8 r8 r8 c8 c8 r8 r8 c8 c8 r8 r8 c8 c8 r8 r8 c8 c8 r8 r8 c8 c8 r8 r8 c8"),
            ])
        case .battleNorth:
            // 青森・秋田の 戦い。
            Score(tempo: 152, voices: [
                lead("o4 e8 e8 a8 e8 b8 e8 >c8< b8 | a8 g8 e8 d8 e4 r4 | e8 e8 a8 e8 >d8< e8 >c8< b8 | >c8 d8 e8 d8 c4< r4 | >e8 d8 c8< a8 >c8< a8 g8 e8 | g8 a8 >c8 d8 e4 d4 | c8< b8 a8 g8 e8 g8 a8 b8 | a4 r4 a4 r4"),
                bass("o2 a8 >a8< a8 >a8< a8 >a8< a8 >a8< | e8 >e8< e8 >e8< e8 >e8< e8 >e8< | a8 >a8< a8 >a8< a8 >a8< a8 >a8< | a8 >a8< a8 >a8< a8 >a8< a8 >a8< | c8 >c8< c8 >c8< c8 >c8< c8 >c8< | c8 >c8< c8 >c8< c8 >c8< c8 >c8< | e8 >e8< e8 >e8< e8 >e8< e8 >e8< | a8 >a8< a8 >a8< a4 r4"),
                drums("c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8"),
            ])
        case .battleMiddle:
            // 岩手・宮城の 戦い。
            Score(tempo: 156, voices: [
                lead("o4 d8 d8 g8 d8 a8 d8 b8 a8 | g8 f+8 e8 d8 e4 r4 | d8 d8 g8 d8 >c8< d8 b8 a8 | b8 >c8 d8 c8< b4 r4 | >d8 c8< b8 a8 g8 f+8 e8 d8 | e8 f+8 g8 a8 b4 a4 | g8 f+8 e8 d8 c+8 d8 e8 c+8 | d4 r4 d4 r4"),
                bass("o2 g8 >g8< g8 >g8< g8 >g8< g8 >g8< | d8 >d8< d8 >d8< d8 >d8< d8 >d8< | g8 >g8< g8 >g8< g8 >g8< g8 >g8< | g8 >g8< g8 >g8< g8 >g8< g8 >g8< | e8 >e8< e8 >e8< e8 >e8< e8 >e8< | c8 >c8< c8 >c8< c8 >c8< c8 >c8< | a8 >a8< a8 >a8< a8 >a8< a8 >a8< | d8 >d8< d8 >d8< d4 r4"),
                drums("c8 c8 r8 c8 r8 c8 r8 c8 c8 c8 r8 c8 r8 c8 r8 c8 c8 c8 r8 c8 r8 c8 r8 c8 c8 c8 r8 c8 r8 c8 r8 c8 c8 c8 r8 c8 r8 c8 r8 c8 c8 c8 r8 c8 r8 c8 r8 c8 c8 c8 r8 c8 r8 c8 r8 c8 c8 c8 r8 c8 r8 c8 r8 c8"),
            ])
        case .battleSouth:
            // 福島・山形の 戦い。
            Score(tempo: 160, voices: [
                lead("o4 c8 c8 f8 c8 g8 c8 a-8 g8 | f8 e-8 d8 c8 d4 r4 | c8 c8 f8 c8 b-8 c8 a-8 g8 | a-8 b-8 >c8< b-8 a-4 r4 | >c8< b-8 a-8 g8 f8 e-8 d8 c8 | d8 e-8 f8 g8 a-4 g4 | f8 e-8 d8 c8 b8 c8 d8 b8 | >c4< r4 c4 r4", duty: 0.125, volume: 0.10),
                bass("o2 f8 >f8< f8 >f8< f8 >f8< f8 >f8< | c8 >c8< c8 >c8< c8 >c8< c8 >c8< | f8 >f8< f8 >f8< f8 >f8< f8 >f8< | a-8 >a-8< a-8 >a-8< a-8 >a-8< a-8 >a-8< | f8 >f8< f8 >f8< f8 >f8< f8 >f8< | d8 >d8< d8 >d8< d8 >d8< d8 >d8< | g8 >g8< g8 >g8< g8 >g8< g8 >g8< | c8 >c8< c8 >c8< c4 r4"),
                drums("c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8"),
            ])
        case .cave:
            // 青森・秋田の ほらあな。
            Score(tempo: 84, voices: [
                lead("o4 a4 r4 b-4 a4 | g+4 a8 r8 r2 | >c4 r4 d4 c4< | b4 >c8< r8 r2 | e4 r8 f8 e4 d4 | c4 d4 e2 | f4 e8 d8 c4< b4 | a2 r2", duty: 0.125, volume: 0.10),
                bass("o2 a4 r4 a4 r4 | a4 r4 a4 r4 | f4 r4 f4 r4 | e4 r4 e4 r4 | a4 r4 a4 r4 | f4 r4 f4 r4 | d4 r4 e4 r4 | a4 r4 a4 r4"),
            ])
        case .caveDeep:
            // 岩手から 先の ほらあな。奥ふかく 冷たい。
            Score(tempo: 74, voices: [
                lead("o4 e4 r4 f4 r4 | e4 d+8 r8 r2 | g4 r4 f+4 r4 | f4 e8 r8 r2 | b4 r8 a+8 a4 g4 | f+4 g4 e2 | e4 f+8 g8 a+4 b4 | e2 r2", duty: 0.125, volume: 0.10),
                bass("o2 e4 r4 e4 r4 | e4 r4 e4 r4 | d+4 r4 d+4 r4 | d+4 r4 d+4 r4 | e4 r4 e4 r4 | b4 r4 b4 r4 | a+4 r4 a+4 r4 | e4 r4 e4 r4"),
            ])
        case .boss:
            // ぬしとの 戦い。
            Score(tempo: 164, voices: [
                lead("o4 e8 e8 r8 e8 g8 e8 a+8 b8 | b8 b8 r8 b8 >c8< b8 a8 g8 | e8 e8 r8 e8 g8 a8 b8 >d8< | >e4 d+4 e4< r4 | g8 a8 b8 >c8< b8 a8 g8 f+8 | e8 f+8 g8 a8 b4 g4 | a8 b8 >c8 d8 e8 d8 c8< a8 | b4 d+4 e2", duty: 0.25, volume: 0.10),
                bass("o2 e8 >e8< e8 >e8< e8 >e8< e8 >e8< | b8 >b8< b8 >b8< b8 >b8< b8 >b8< | e8 >e8< e8 >e8< e8 >e8< e8 >e8< | e8 e8 d+8 d+8 e4 r4 | c8 >c8< c8 >c8< c8 >c8< c8 >c8< | e8 >e8< e8 >e8< e8 >e8< e8 >e8< | a8 >a8< a8 >a8< a8 >a8< a8 >a8< | b8 b8 b8 b8 e4 r4"),
                drums("c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8"),
            ])
        case .finalBoss:
            // 守護神・まおうの かげとの 戦い。
            Score(tempo: 170, voices: [
                lead("o4 d8 d8 >d8< d8 c+8 d8 a8 d8 | b-8 d8 a8 d8 g8 d8 f8 e8 | d8 d8 >d8< d8 c+8 d8 >e8 f8< | >g4 f4 e4 d4< | a8 b-8 a8 g8 f8 g8 a8 >d8< | c+8 d8 e8 f8 g4 e4 | f8 g8 a8 b-8 >c+8< a8 >e8< c+8 | d4 a4 >d4< r4", duty: 0.125, volume: 0.10),
                bass("o2 d8 >d8< d8 >d8< d8 >d8< d8 >d8< | b-8 >b-8< b-8 >b-8< b-8 >b-8< b-8 >b-8< | d8 >d8< d8 >d8< d8 >d8< d8 >d8< | g8 >g8< g8 >g8< g8 >g8< g8 >g8< | d8 >d8< d8 >d8< d8 >d8< d8 >d8< | a8 >a8< a8 >a8< a8 >a8< a8 >a8< | a8 >a8< a8 >a8< a8 >a8< a8 >a8< | d8 >d8< d8 >d8< d4 r4"),
                drums("c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8 c8 c8 c8 r8"),
            ])
        case .ending:
            // エンディング。
            Score(tempo: 86, voices: [
                lead("o4 d4 e4 g4 a4 | b4 a8 g8 e2 | g4 a4 b4 >d4 | e2 d4 b4< | a4 b4 >d4 e4 | d4< b4 a4 g4 | e4 g4 a4 b4 | >d2.< r4", duty: 0.5, volume: 0.10),
                bass("o3 g2 d2 | e2 c2 | g2 g2 | c2 g2 | d2 c2 | g2 d2 | c2 d2 | g2 g2"),
            ])
        }
    }
}

/// ジングル（1回だけ鳴らす短い曲）。
enum Jingles {
    static let victory = Score(tempo: 150, voices: [
        lead("o4 c8 e8 g8 >c4< g8 >c2<", duty: 0.5),
        bass("o3 c2 r4 c2"),
    ])
    static let levelUp = Score(tempo: 170, voices: [
        lead("o5 c8 d8 e8 g8 e8 g8 >c4<"),
        bass("o3 c4 e4 g4 c4"),
    ])
    static let inn = Score(tempo: 96, voices: [
        lead("o4 e4 g4 >c4< r8 g8 >c2<", duty: 0.5, volume: 0.10),
        bass("o3 c2 g2 c2"),
    ])
    static let gameOver = Score(tempo: 72, voices: [
        lead("o4 e4 d+4 d4 c+4 c2", duty: 0.5, volume: 0.10),
        bass("o2 a2 a2 a2"),
    ])
}

extension SoundCue {
    func render() -> [Float] {
        switch self {
        case .victory: Synth.render(Jingles.victory)
        case .levelUp: Synth.render(Jingles.levelUp)
        case .inn: Synth.render(Jingles.inn)
        case .gameOver: Synth.render(Jingles.gameOver)
        default: Synth.render(segments)
        }
    }

    var segments: [Segment] {
        switch self {
        case .cursor: [sq(1320, 1320, 0.03, 0.10)]
        case .confirm: [sq(880, 880, 0.04), sq(1320, 1320, 0.06)]
        case .bump: [sq(140, 70, 0.07, 0.22)]
        case .stairs: [784, 659, 523, 392, 262].map { sq($0, $0, 0.05, 0.13, duty: 0.25) }
        case .encounter: [440, 880, 494, 988, 554, 1109, 659].map { sq($0, $0, 0.04, 0.15, duty: 0.25) }
        case .attack: [noise(0.07, 0.30)]
        case .critical: [sq(1600, 400, 0.10, 0.18), noise(0.10, 0.35)]
        case .hit: [noise(0.12, 0.35), sq(220, 110, 0.05, 0.15)]
        case .damage: [sq(400, 80, 0.15, 0.25), noise(0.08, 0.25)]
        case .miss: [sq(1000, 1500, 0.06, 0.10)]
        case .spell: [523, 659, 784, 1047, 1319].map { sq($0, $0, 0.04, 0.13, duty: 0.25) }
        case .heal: [784, 988, 1175, 1568].map { Segment(wave: .triangle, from: $0, to: $0, duration: 0.07, volume: 0.35) }
        case .fire: [noise(0.35, 0.35)]
        case .run: [sq(600, 600, 0.04), rest(0.02), sq(500, 500, 0.04), rest(0.02), sq(400, 400, 0.06)]
        case .chest: [523, 659, 784, 1047].map { sq($0, $0, 0.05, 0.13, duty: 0.25) } + [sq(1319, 1319, 0.12, 0.13, duty: 0.25)]
        case .coin: [sq(988, 988, 0.05), sq(1319, 1319, 0.15)]
        case .victory, .levelUp, .inn, .gameOver: []
        }
    }
}

// MARK: - 書きやすくするための部品

private func lead(_ notes: String, duty: Double = 0.25, volume: Float = 0.11) -> Voice {
    Voice(wave: .square(duty: duty), volume: volume, notes: "l8 " + notes)
}

private func bass(_ notes: String) -> Voice {
    Voice(wave: .triangle, volume: 0.28, notes: "l8 " + notes)
}

private func drums(_ notes: String) -> Voice {
    Voice(wave: .noise, volume: 0.05, notes: "l8 " + notes)
}

private func sq(_ from: Double, _ to: Double, _ duration: Double, _ volume: Float = 0.15, duty: Double = 0.5) -> Segment {
    Segment(wave: .square(duty: duty), from: from, to: to, duration: duration, volume: volume)
}

private func noise(_ duration: Double, _ volume: Float) -> Segment {
    Segment(wave: .noise, from: 0, to: 0, duration: duration, volume: volume)
}

private func rest(_ duration: Double) -> Segment {
    Segment(wave: .square(duty: 0.5), from: 0, to: 0, duration: duration, volume: 0)
}
