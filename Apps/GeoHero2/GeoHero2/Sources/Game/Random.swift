import Foundation

/// 戦闘や遭遇の乱数。テストで結果を固定できるよう、乱数の出どころを差し替え可能にする。
protocol RandomSource {
    mutating func next(in range: ClosedRange<Int>) -> Int
}

extension RandomSource {
    /// `denominator` 分の1で true。
    mutating func chance(_ denominator: Int) -> Bool {
        next(in: 1...max(1, denominator)) == 1
    }
}

/// 乱数の出どころを実行時に差し替えるための入れ物（本番はシステム乱数、テストは種付き）。
struct AnyRandomSource: RandomSource {
    private var base: any RandomSource

    init(_ base: some RandomSource) {
        self.base = base
    }

    mutating func next(in range: ClosedRange<Int>) -> Int {
        base.next(in: range)
    }
}

struct SystemRandomSource: RandomSource {
    private var generator = SystemRandomNumberGenerator()

    mutating func next(in range: ClosedRange<Int>) -> Int {
        Int.random(in: range, using: &generator)
    }
}

/// 種から決まった列を返す乱数（SplitMix64）。テスト用。
struct SeededRandomSource: RandomSource {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next(in range: ClosedRange<Int>) -> Int {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        let width = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int(z % width)
    }
}

/// 常に同じ位置（0=最小, 1=最大）を返す乱数。ダメージの上下限を確かめるテスト用。
struct FixedRandomSource: RandomSource {
    enum Pick { case min, max }
    var pick: Pick

    mutating func next(in range: ClosedRange<Int>) -> Int {
        pick == .min ? range.lowerBound : range.upperBound
    }
}
