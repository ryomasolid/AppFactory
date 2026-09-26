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
        #expect(QuizRegion.at(.sapporoArea, Point(x: 36, y: 21)) == .sapporo, "札幌の外")
        #expect(QuizRegion.at(.sapporoArea, Point(x: 10, y: 22)) == .otaru, "小樽の外")
        #expect(QuizRegion.at(.sapporoArea, Point(x: 9, y: 29)) == .otaru, "天狗山の前")
        #expect(QuizRegion.at(.tenguyama, Point(x: 8, y: 13)) == .otaru)
        #expect(QuizRegion.at(.jozankei, Point(x: 11, y: 16)) == .sapporo, "定山渓")
        #expect(QuizRegion.at(.otaru, Point(x: 13, y: 20)) == .otaru, "小樽")
        #expect(QuizRegion.at(.sapporoArea, Point(x: 29, y: 28)) == .sapporo, "藻岩山の前")
        #expect(QuizRegion.at(.moiwa2, Point(x: 1, y: 1)) == .sapporo)
        #expect(QuizRegion.at(.shiretokoArea, Point(x: 16, y: 32)) == .rausu, "中標津の外")
        #expect(QuizRegion.at(.shiretokoArea, Point(x: 30, y: 12)) == .utoro, "ウトロの外")
        #expect(QuizRegion.at(.shiretokoMisaki, Point(x: 8, y: 13)) == .utoro, "知床岬")
        #expect(QuizRegion.at(.nakashibetsu, Point(x: 12, y: 16)) == .rausu, "中標津")
        #expect(QuizRegion.at(.rausudake2, Point(x: 1, y: 1)) == .rausu)
        #expect(QuizRegion.at(.innInside, Point(x: 4, y: 4)) == nil, "宿屋の中")
    }

    /// 問題のない土地では「ちしきの チャンス」は 出ない。
    @Test func noQuizWithoutQuizzes() {
        let battle = Battle(hero: hero(), enemies: [Enemy(.squidLord)])
        #expect(battle.nextQuiz == nil)
    }

    // MARK: - 答え合わせ

    /// 正解すると ふつうの こうげきの あとに 追い打ち（会心なみ）が 入る。
    @Test func rightAnswerAddsABonusHit() throws {
        var rng = SeededRandomSource(seed: 1)
        var battle = Battle(hero: hero(), enemies: [Enemy(.squidLord)], quizzes: quizzes)
        let quiz = try #require(battle.nextQuiz)

        let result = battle.take(.quizAttack(answer: quiz.answer), target: 0, rng: &rng)
        #expect(result.messages.contains { $0.hasPrefix("せいかい") })
        let hits = result.lines.filter { $0.enemyDamage != nil }
        #expect(hits.count == 2, "こうげきと 追い打ちの 2発に なっていない")
        #expect(hits.last?.isCritical == true, "追い打ちは 会心なみ")
        // 正解した問題は 山の下へ回す。
        #expect(battle.quizzes.last == quiz)
    }

    /// まちがえても ふつうの こうげきは 当たる。追い打ちは なく、正解を 見せて すぐ また出す。
    @Test func wrongAnswerStillAttacksAndShowsTheAnswer() throws {
        var rng = SeededRandomSource(seed: 1)
        var battle = Battle(hero: hero(), enemies: [Enemy(.squidLord)], quizzes: quizzes)
        let quiz = try #require(battle.nextQuiz)

        let result = battle.take(.quizAttack(answer: wrongAnswer(quiz)), target: 0, rng: &rng)
        #expect(result.messages.contains { $0.contains("こたえは「\(quiz.correctChoice)」") })
        #expect(result.lines.filter { $0.enemyDamage != nil }.count == 1, "ふつうの こうげきだけが 当たる")
        #expect(battle.quizzes.firstIndex(of: quiz) == 2, "まちがえた問題は 2問あとに また出る")
        #expect(battle.quizzes.count == quizzes.count)
    }

    /// ボスにも ふつうの こうげきは そのまま 通る（まもりで 半分に なったりしない）。
    @Test func bossTakesFullDamage() throws {
        func attackDamage(quizzes: [Quiz]) throws -> Int {
            var rng = FixedRandomSource(pick: .max)
            var battle = Battle(hero: hero(level: 8), enemies: [Enemy(.squidLord)], quizzes: quizzes)
            let hit = battle.take(.attack, target: 0, rng: &rng).lines.first { $0.enemyDamage != nil }
            return try #require(hit?.enemyDamage)
        }
        #expect(try attackDamage(quizzes: quizzes) == attackDamage(quizzes: []))
    }

    /// こうげきで たおした あとに 正解したら、生きている ほかの敵に 追い打ちする。
    @Test func bonusHitMovesToALivingEnemy() throws {
        var rng = FixedRandomSource(pick: .max)
        let group = EnemyGroup.numbered([.potato, .kelpSlime])
        var battle = Battle(hero: hero(), enemies: group, quizzes: quizzes)
        let quiz = try #require(battle.nextQuiz)
        let result = battle.take(.quizAttack(answer: quiz.answer), target: group[0].id, rng: &rng)
        let struck = Set(result.lines.compactMap(\.enemyID))
        #expect(struck.contains(group[1].id), "追い打ちが ほかの敵に 当たらない: \(struck)")
    }

    /// 「ちしきの チャンス」は ときどき出る。ボスは まもりを やぶる 手が これしかないので 出やすい。
    @Test func quizChanceIsOccasional() {
        let field = Battle(hero: hero(), enemies: [Enemy(.potato)], quizzes: quizzes)
        let boss = Battle(hero: hero(), enemies: [Enemy(.squidLord)], quizzes: quizzes)
        #expect(field.quizChanceDenominator > boss.quizChanceDenominator)
        #expect(boss.quizChanceDenominator >= 2, "ボスでも 毎回は 出さない")
    }

    // MARK: - 戦いをまたいで

    /// 「こうげき」で チャンスが 出たら 問題を 出して 待ち、答えると こうげきする。出なければ すぐ こうげき。
    @MainActor
    @Test func attackOffersAQuizSometimes() async throws {
        let game = GameState()
        game.newGame()
        game.messageInterval = .zero
        game.beatPause = .zero
        game.waitsForTap = false
        game.startBattle(.snowFestival)

        // チャンスが 出ない くじ。そのまま こうげきする。
        game.rng = AnyRandomSource(FixedRandomSource(pick: .max))
        await game.attack(target: 0)
        #expect(game.quizChance == nil)
        #expect(game.battle?.lastHits.isEmpty == false || game.battle?.end != nil, "こうげきしていない")

        // チャンスが 出る くじ。問題を 出して 答えを まつ。
        game.rng = AnyRandomSource(FixedRandomSource(pick: .min))
        await game.attack(target: 0)
        let quiz = try #require(game.quizChance, "チャンスが 出ない")
        #expect(game.battle?.log.first == "ちしきの チャンス！")
        #expect(game.battle?.log.last == quiz.question)
        await game.answerQuiz(quiz.answer)
        #expect(game.quizChance == nil)
    }

    @MainActor
    @Test func deckCarriesOverBetweenBattles() async throws {
        let game = GameState()
        game.newGame()
        game.messageInterval = .zero
        game.beatPause = .zero
        game.waitsForTap = false
        game.startBattle(.potato)
        let first = try #require(game.battle?.battle.nextQuiz)
        await game.command(.quizAttack(answer: first.answer), target: 0)

        game.battle = nil
        game.startBattle(.potato)
        #expect(game.battle?.battle.nextQuiz != first, "つぎの戦いで また同じ問題から始まった")
    }

    /// 追い打ちを 当てた あとに 別の1体を なぐっても、ほかの敵は 揺れない
    /// （最新の一撃だけを 見ていたころは、当たっていない敵まで 揺れて 点滅していた）。
    @MainActor
    @Test func attackAfterQuizShakesOnlyTheTarget() async throws {
        let game = GameState()
        game.newGame()
        game.messageInterval = .zero
        game.beatPause = .zero
        game.waitsForTap = false
        game.rng = AnyRandomSource(SeededRandomSource(seed: 2))
        // 固い敵にも ダメージが 通り、ひと振りでは たおれない 強さにする。
        _ = game.hero.gainExp(LevelTable.row(14).exp)
        game.hero.restoreFully()
        game.startBattle([.iceGolem, .iceGolem, .iceGolem])
        for target in 0..<3 {
            await game.command(.attack, target: target)
        }
        let afterQuiz = try #require(game.battle?.lastHits)
        #expect(afterQuiz.count == 3, "3体に 当たっていない")

        await game.command(.attack, target: 0)
        let afterAttack = try #require(game.battle?.lastHits)
        let targetID = try #require(game.battle?.enemyHit?.enemyID)
        for (id, hit) in afterQuiz where id != targetID {
            #expect(afterAttack[id] == hit, "なぐっていない 敵 \(id) の 一撃が かわった")
        }
    }
}
