import Foundation
import Testing
@testable import GeoHero2

/// 「ちしき」の 問題。答えは その街で かならず 聞ける。
struct QuizTests {

    private var towns: [MapID] { Array(QuizBank.byTown.keys).sorted { $0.rawValue < $1.rawValue } }

    @Test func everyTownHasQuizzes() {
        for id in MapID.allCases where id.isTown {
            #expect((QuizBank.byTown[id]?.count ?? 0) >= 6, "\(id) の 問題が すくない")
        }
    }

    @Test func everyQuizHasThreeDistinctChoices() {
        for quiz in QuizBank.byTown.values.flatMap({ $0 }) {
            #expect(quiz.choices.count == 3, "\(quiz.question)")
            #expect(Set(quiz.choices).count == 3, "\(quiz.question) の 選択肢が かさなっている")
            #expect(quiz.choices.indices.contains(quiz.answer), "\(quiz.question) の 答えの 番号が おかしい")
        }
    }

    /// 答えの 位置が かたよると 読まずに 当たる。
    @Test func answersAreSpreadAcrossPositions() {
        for (town, quizzes) in QuizBank.byTown {
            #expect(Set(quizzes.map(\.answer)).count == 3, "\(town) の 答えの 位置が かたよっている")
        }
    }

    /// 問題文は ぜんぶ ちがう（てちょうは 問題文で おぼえる）。
    @Test func questionsAreUnique() {
        let questions = QuizBank.byTown.values.flatMap { $0 }.map(\.question)
        #expect(Set(questions).count == questions.count)
    }

    /// 戦いの 枠に 入る 長さ。
    @Test func questionsFitTheBattleBox() {
        for quiz in QuizBank.byTown.values.flatMap({ $0 }) {
            #expect(quiz.question.count <= 30, "\(quiz.question) が 長い")
            for choice in quiz.choices { #expect(choice.count <= 9, "\(choice) が 長い") }
        }
    }

    /// 答えは その街（と 街の 家）の 人・看板・物語の 人から かならず 聞ける。
    @Test func everyAnswerIsTaughtInItsTown() {
        for (town, quizzes) in QuizBank.byTown {
            let maps = World.all.values.filter { $0.id == town || ($0.id.isHouse && $0.quizTown == town) }
            let spoken = maps.flatMap(\.npcs).compactMap { npc -> String? in
                switch npc.role {
                case let .villager(lines): lines.joined()
                case let .resident(resident): resident.everyLine.joined()
                default: nil
                }
            }
            let text = (spoken + maps.flatMap(\.plaques.values).map { $0.lines.joined() }).joined(separator: "\n")
            for quiz in quizzes {
                #expect(text.contains(quiz.correctChoice), "「\(quiz.correctChoice)」（\(quiz.question)）を \(town) の だれも 教えてくれない")
            }
        }
    }

    /// フィールドの 区域・ほらあな・家では ちかくの 街の 問題が 出る。
    @Test func everyBattlePlaceHasAQuizTown() {
        for map in World.all.values {
            switch map.kind {
            case .field:
                for area in map.encounterAreas {
                    #expect(area.quizTown.flatMap { QuizBank.byTown[$0] } != nil, "\(map.id) の \(area.name)")
                    #expect(area.quizTown?.region == map.region, "\(map.id) の \(area.name) が ほかの 県の 問題")
                }
            case .cave:
                #expect(map.quizTown.flatMap { QuizBank.byTown[$0] } != nil, "\(map.id)")
            default: break
            }
        }
        #expect(QuizBank.town(at: .innInside, Point(x: 4, y: 4)) == nil)
    }

    // MARK: - 答え合わせと コンボ

    private func hero(level: Int = 10) -> Hero {
        var hero = Hero()
        _ = hero.gainExp(LevelTable.row(level).exp)
        hero.restoreFully()
        return hero
    }

    @Test func rightAnswerAddsABonusHitAndCountsTheStreak() throws {
        var rng = SeededRandomSource(seed: 1)
        let quizzes = QuizBank.byTown[.aomori]!
        var battle = Battle(hero: hero(), enemies: [Enemy(.yukioni)], quizzes: quizzes, streak: 1)
        let quiz = try #require(battle.nextQuiz)
        let result = battle.take(.quizAttack(answer: quiz.answer), target: 0, rng: &rng)
        #expect(result.lines.filter { $0.enemyDamage != nil }.count == 2)
        #expect(result.messages.contains("ちしき コンボ ×2！"))
        #expect(battle.streak == 2)
        #expect(battle.solved == [quiz])
    }

    @Test func wrongAnswerBreaksTheStreak() throws {
        var rng = SeededRandomSource(seed: 1)
        let quizzes = QuizBank.byTown[.aomori]!
        var battle = Battle(hero: hero(), enemies: [Enemy(.yukioni)], quizzes: quizzes, streak: 3)
        let quiz = try #require(battle.nextQuiz)
        let result = battle.take(.quizAttack(answer: (quiz.answer + 1) % 3), target: 0, rng: &rng)
        #expect(result.messages.contains { $0.contains("こたえは「\(quiz.correctChoice)」") })
        #expect(battle.streak == 0)
        #expect(battle.solved.isEmpty)
    }

    @Test func comboGrowsUpToDouble() {
        #expect(Battle.comboPercent(1) == 100)
        #expect(Battle.comboPercent(2) == 125)
        #expect(Battle.comboPercent(5) == 200)
        #expect(Battle.comboPercent(9) == 200)
    }
}
