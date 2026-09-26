import SwiftUI
import Testing
@testable import GeoHero

/// 戦闘の下2枚の枠は 高さを変えない（行や選択肢が増えるたびに枠が伸びると、
/// 敵の絵が上下にずれて 当たったときの揺れがわかりにくくなる）。
/// そのぶん 中身がその高さを超えると 下が切れて読めなくなるので、
/// 実際に出る文・選択肢を並べて はみ出さないことを確かめる。
@MainActor
struct LayoutTests {

    /// いちばん狭い端末（iPhone SE）の横幅。ここでいちばん折り返しが増える。
    private static let narrowest: CGFloat = 375

    @Test func battleMessagesFitTheirBox() {
        let worst = Self.worstLog()
        let height = Self.height(of: MessageBox(lines: worst, showsCursor: true), width: Self.narrowest)
        #expect(
            height <= BattleView.messageHeight,
            """
            メッセージ枠から はみ出す: \(Int(height)) > \(Int(BattleView.messageHeight))
            \(worst.joined(separator: "\n"))
            """
        )
    }

    @Test func battleCommandsFitTheirBox() {
        // いちばん背が高くなるのは じゅもん（2列 + もどる）と 相手えらび（2列 + もどる）。
        let hero = Hero.atMaxLevel()
        let spells = RetroWindow {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(hero.spells.prefix((hero.spells.count + 1) / 2)) { row($0.name, "MP \($0.mpCost)") }
                }
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(hero.spells.dropFirst((hero.spells.count + 1) / 2)) { row($0.name, "MP \($0.mpCost)") }
                }
            }
            row("もどる", nil)
        }
        let height = Self.height(of: spells, width: Self.narrowest)
        #expect(
            height <= BattleView.commandHeight,
            "コマンド枠から はみ出す: \(Int(height)) > \(Int(BattleView.commandHeight))"
        )
    }

    /// 「ちしき」の答え（2列 + もどる）も枠に収まる。答えが長いと 列の中で折り返す。
    @Test func quizChoicesFitTheirBox() {
        for quiz in QuizRegion.allCases.flatMap(\.quizzes) {
            let half = (quiz.choices.count + 1) / 2
            let answers = RetroWindow {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(quiz.choices.prefix(half), id: \.self) { row($0, nil) }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(quiz.choices.dropFirst(half), id: \.self) { row($0, nil) }
                    }
                }
                row("もどる", nil)
            }
            let height = Self.height(of: answers, width: Self.narrowest)
            #expect(
                height <= BattleView.commandHeight,
                "答えが コマンド枠から はみ出す: \(Int(height)) > \(Int(BattleView.commandHeight)) \(quiz.choices)"
            )
        }
    }

    /// RetroChoice は GameState を環境から読むので、測るだけの版を置く。
    private func row(_ title: String, _ detail: String?) -> some View {
        HStack {
            Text(title)
            Spacer()
            if let detail { Text(detail) }
        }
        .padding(.vertical, 4)
    }

    // MARK: - はかる

    private static func height(of view: some View, width: CGFloat) -> CGFloat {
        let renderer = ImageRenderer(content: view.frame(width: width))
        return renderer.uiImage?.size.height ?? 0
    }

    /// 戦闘を何度も回して、枠に残る3行のうち いちばん背が高くなる組み合わせを見つける。
    private static func worstLog() -> [String] {
        var lineHeights: [String: CGFloat] = [:]
        func lineHeight(_ text: String) -> CGFloat {
            if let known = lineHeights[text] { return known }
            // 枠の内側の幅（外の余白6×2 と 内の余白14×2 を引く）。
            let measured = height(
                of: Text(text).font(Retro.font()).fixedSize(horizontal: false, vertical: true),
                width: narrowest - 12 - 28
            )
            lineHeights[text] = measured
            return measured
        }

        var worst: [String] = []
        var worstHeight: CGFloat = 0
        for log in allLogs() {
            var shown: [String] = []
            for line in log {
                shown.append(line)
                if shown.count > GameState.battleLogLines { shown.removeFirst() }
                let total = shown.reduce(0) { $0 + lineHeight($1) }
                if total > worstHeight {
                    worstHeight = total
                    worst = shown
                }
            }
        }
        return worst
    }

    /// 実際に起きうる戦闘の記録。長い名前の敵ほど行が長くなるので そこを厚めに回す。
    private static func allLogs() -> [[String]] {
        let crowds: [[EnemyKind]] = [
            [.iceGolem, .iceGolem, .iceGolem],
            [.snowman, .iceGolem, .cod],
            [.kelpSlime, .scallop, .fox],
            [.potato, .potato, .kelpSlime],
            [.guardian],
            [.squidLord],
            [.bearLord],
        ]
        var logs: [[String]] = []
        for (index, kinds) in crowds.enumerated() {
            for level in [1, 6, 12] {
                var rng = SeededRandomSource(seed: UInt64(index * 100 + level))
                var hero = Hero.atMaxLevel()
                hero.name = String(repeating: "あ", count: Hero.maxNameLength)
                if level < hero.level { hero = scaled(hero, to: level) }
                let group = EnemyGroup.numbered(kinds)
                // 答えが いちばん長い 土地の問題で回す（まちがいの行に 答えが出る）。
                let longest = QuizRegion.allCases.max {
                    $0.quizzes.map(\.correctChoice.count).max() ?? 0 < $1.quizzes.map(\.correctChoice.count).max() ?? 0
                }
                var battle = Battle(hero: hero, enemies: group, quizzes: longest?.quizzes ?? [])
                var log = [EnemyGroup.encounterText(group)]
                for turn in 0..<40 where battle.end == nil {
                    // こうげき・じゅもん・どうぐ・ちしきの チャンス（正解と まちがい）を混ぜて、出る行の種類をひととおり出す。
                    let command: BattleCommand = switch turn % 4 {
                    case 0: .attack
                    case 1: battle.hero.spells.last.map { BattleCommand.spell($0) } ?? .attack
                    case 2: .item(.herb)
                    default: .quizAttack(answer: (turn / 4) % 3)
                    }
                    log += battle.take(command, target: battle.defaultTarget, rng: &rng).messages
                }
                logs.append(log)
            }
        }
        // 「ちしき」を選んだときに出す問題。
        for region in QuizRegion.allCases {
            logs += region.quizzes.map { ["もんだい！", $0.question] }
        }
        return logs
    }

    private static func scaled(_ hero: Hero, to level: Int) -> Hero {
        var scaled = Hero()
        scaled.name = hero.name
        _ = scaled.gainExp(LevelTable.row(level).exp)
        return scaled
    }
}

private extension Hero {
    /// いちばん行が長くなる条件（名前も呪文も最大）で測るための勇者。
    static func atMaxLevel() -> Hero {
        var hero = Hero()
        _ = hero.gainExp(LevelTable.row(LevelTable.maxLevel).exp)
        hero.receive(.steelSword)
        hero.receive(.chainMail)
        return hero
    }
}
