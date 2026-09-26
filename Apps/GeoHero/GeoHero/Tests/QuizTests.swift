import Foundation
import Testing
@testable import GeoHero

/// 戦闘の「ちしき」（地理の問題）。
struct QuizTests {

    private let quizzes = QuizRegion.hakodate.quizzes

    private func hero(level: Int = 5) -> Hero {
        var hero = Hero()
        _ = hero.gainExp(LevelTable.row(level).exp)
        hero.restoreFully()
        return hero
    }

    private func wrongAnswer(_ quiz: Quiz) -> Int { (quiz.answer + 1) % quiz.choices.count }

    // MARK: - 問題の中身

    @Test func everyQuizHasThreeDistinctChoices() {
        for quiz in QuizRegion.allCases.flatMap(\.quizzes) {
            #expect(quiz.choices.count == 3, "\(quiz.question)")
            #expect(Set(quiz.choices).count == quiz.choices.count, "\(quiz.question) の選択肢が重なっている")
            #expect(quiz.choices.indices.contains(quiz.answer), "\(quiz.question) の答えの番号が選択肢の外")
        }
    }

    /// 答えの位置が かたよっていると、読まずに同じ位置を押すだけで当たる。
    @Test(arguments: QuizRegion.allCases)
    func answersAreSpreadAcrossPositions(region: QuizRegion) {
        let answers = region.quizzes.map(\.answer)
        #expect(Set(answers).count == 3, "\(region) の答えの位置がかたよっている: \(answers)")
    }

    /// 同じ問題が 2つの土地に出ると、山が まざって 見分けにくい。
    @Test func questionsAreNotSharedBetweenRegions() {
        let questions = QuizRegion.allCases.flatMap(\.quizzes).map(\.question)
        #expect(Set(questions).count == questions.count)
    }

    /// 答えは その土地の街の人から かならず聞ける（知らないと解けない問題は出さない）。
    @Test(arguments: QuizRegion.allCases)
    func everyAnswerIsTaughtInItsTown(region: QuizRegion) {
        let maps = region.towns.map(World.map)
        let spoken = maps.flatMap(\.npcs).compactMap { npc -> String? in
            switch npc.role {
            case let .villager(lines): lines.joined()
            case let .resident(resident): resident.everyLine.joined()
            default: nil
            }
        }
        let text = (spoken + maps.flatMap(\.plaques.values).map { $0.lines.joined() }).joined(separator: "\n")
        for quiz in region.quizzes {
            #expect(text.contains(quiz.correctChoice), "「\(quiz.correctChoice)」を \(region.towns) の だれも 教えてくれない")
        }
    }

    // MARK: - どこで出るか

    @Test func eachPlaceAsksItsOwnQuizzes() {
        #expect(QuizRegion.at(.hakodate, Point(x: 7, y: 9)) == .hakodate)
        #expect(QuizRegion.at(.hakodateyama, Point(x: 7, y: 2)) == .hakodate)
        #expect(QuizRegion.at(.hakodateArea, Point(x: 46, y: 28)) == .hakodate, "函館の外")
        #expect(QuizRegion.at(.hakodateArea, Point(x: 38, y: 34)) == .hakodate, "函館山の前")
        #expect(QuizRegion.at(.hakodateArea, Point(x: 13, y: 35)) == .matsumae, "松前の外")
        #expect(QuizRegion.at(.matsumae, Point(x: 13, y: 20)) == .matsumae)
        #expect(QuizRegion.at(.hakodateArea, Point(x: 30, y: 18)) == .onuma, "大沼の外")
        #expect(QuizRegion.at(.hakodateArea, Point(x: 40, y: 11)) == .onuma, "駒ヶ岳の前")
        #expect(QuizRegion.at(.komagatake, Point(x: 8, y: 13)) == .onuma)
        #expect(QuizRegion.at(.sapporoArea, Point(x: 27, y: 18)) == .sapporo, "札幌の外")
        #expect(QuizRegion.at(.otaru, Point(x: 10, y: 13)) == .sapporo, "小樽")
        #expect(QuizRegion.at(.sapporoArea, Point(x: 17, y: 26)) == .sapporo, "藻岩山の前")
        #expect(QuizRegion.at(.moiwa2, Point(x: 1, y: 1)) == .sapporo)
        #expect(QuizRegion.at(.shiretokoArea, Point(x: 18, y: 22)) == .rausu, "知床の外")
        #expect(QuizRegion.at(.rausudake2, Point(x: 1, y: 1)) == .rausu)
        #expect(QuizRegion.at(.innInside, Point(x: 4, y: 4)) == nil, "宿屋の中")
    }

    /// 奥のボスほど まもりが厚い。
    @Test func laterBossesHaveThickerVeils() {
        let layers = [EnemyKind.squidLord, .komaLord, .bearLord, .guardian].map(\.veilLayers)
        #expect(layers == layers.sorted() && Set(layers).count == 4, "\(layers)")
        #expect(EnemyKind.allCases.filter { !$0.isBoss }.allSatisfy { $0.veilLayers == 0 }, "ざこに まもりがある")
    }

    /// 問題のない土地では まくを張らない（やぶる手がないので、ただ固いだけになる）。
    @Test func noVeilWithoutQuizzes() {
        let battle = Battle(hero: hero(), enemies: [Enemy(.squidLord)])
        #expect(battle.veil == 0)
        #expect(battle.nextQuiz == nil)
    }

    // MARK: - 答え合わせ

    @Test func rightAnswerTearsTheVeilAndHitsHard() throws {
        var rng = SeededRandomSource(seed: 1)
        var battle = Battle(hero: hero(), enemies: [Enemy(.squidLord)], quizzes: quizzes)
        let quiz = try #require(battle.nextQuiz)
        #expect(battle.veil == 3)

        let result = battle.take(.quiz(answer: quiz.answer), target: 0, rng: &rng)
        #expect(battle.veil == 2)
        #expect(result.messages.contains { $0.hasPrefix("せいかい") })
        let critical = result.lines.first { $0.enemyDamage != nil }
        #expect(critical?.isCritical == true, "正解の一撃は会心なみ")
        // 正解した問題は 山の下へ回す。
        #expect(battle.quizzes.last == quiz)
    }

    @Test func wrongAnswerShowsTheAnswerAndComesBackSoon() throws {
        var rng = SeededRandomSource(seed: 1)
        var battle = Battle(hero: hero(), enemies: [Enemy(.squidLord)], quizzes: quizzes)
        let quiz = try #require(battle.nextQuiz)

        let result = battle.take(.quiz(answer: wrongAnswer(quiz)), target: 0, rng: &rng)
        #expect(battle.veil == 3, "まちがえても まくは やぶれない")
        #expect(result.messages.contains { $0.contains("こたえは「\(quiz.correctChoice)」") })
        #expect(!result.lines.contains { $0.enemyDamage != nil }, "まちがえたら 敵に当たらない")
        #expect(battle.quizzes.firstIndex(of: quiz) == 2, "まちがえた問題は 2問あとに また出る")
        #expect(battle.quizzes.count == quizzes.count)
    }

    /// まくが のこっているあいだは ふつうの こうげきが 半分になる。
    @Test func veilHalvesPlainAttacks() throws {
        func attackDamage(quizzes: [Quiz]) throws -> Int {
            var rng = FixedRandomSource(pick: .max)
            var battle = Battle(hero: hero(level: 8), enemies: [Enemy(.squidLord)], quizzes: quizzes)
            let hit = battle.take(.attack, target: 0, rng: &rng).lines.first { $0.enemyDamage != nil }
            return try #require(hit?.enemyDamage)
        }
        let veiled = try attackDamage(quizzes: quizzes)
        let bare = try attackDamage(quizzes: [])
        #expect(veiled == max(1, bare / 2), "まくがあるのに 半分になっていない: \(veiled) / \(bare)")
    }

    /// 3問 正解すると まくが消える。
    @Test func threeRightAnswersClearTheVeil() throws {
        var rng = SeededRandomSource(seed: 3)
        var battle = Battle(hero: hero(level: 6), enemies: [Enemy(.squidLord)], quizzes: quizzes)
        var messages: [String] = []
        for _ in 0..<3 where battle.end == nil {
            let quiz = try #require(battle.nextQuiz)
            messages += battle.take(.quiz(answer: quiz.answer), target: 0, rng: &rng).messages
        }
        #expect(battle.veil == 0)
        #expect(messages.contains("すみの まくが きえさった！"))
    }

    /// ざこ戦で正解すると 全員に当たる（3体に囲まれたときの 切り札）。
    @Test func rightAnswerHitsEveryFieldEnemy() throws {
        var rng = FixedRandomSource(pick: .max)
        let group = EnemyGroup.numbered([.potato, .kelpSlime, .scallop])
        var battle = Battle(hero: hero(), enemies: group, quizzes: quizzes)
        let quiz = try #require(battle.nextQuiz)

        let result = battle.take(.quiz(answer: quiz.answer), rng: &rng)
        let struck = Set(result.lines.compactMap(\.enemyID))
        #expect(struck == Set(group.map(\.id)), "当たらなかった敵がいる: \(struck)")
    }

    // MARK: - 戦いをまたいで

    @MainActor
    @Test func deckCarriesOverBetweenBattles() async throws {
        let game = GameState()
        game.newGame()
        game.messageInterval = .zero
        game.beatPause = .zero
        game.waitsForTap = false
        game.startBattle(.potato)
        let first = try #require(game.battle?.battle.nextQuiz)
        await game.command(.quiz(answer: first.answer), target: 0)

        game.battle = nil
        game.startBattle(.potato)
        #expect(game.battle?.battle.nextQuiz != first, "つぎの戦いで また同じ問題から始まった")
    }

    @MainActor
    @Test func withdrawingRestoresTheLog() {
        let game = GameState()
        game.newGame()
        game.startBattle(.potato)
        let before = game.battle?.log
        game.poseQuiz()
        #expect(game.battle?.log.first == "もんだい！")
        game.withdrawQuiz()
        #expect(game.battle?.log == before)
    }
}
