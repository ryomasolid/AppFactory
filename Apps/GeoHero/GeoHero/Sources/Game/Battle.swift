import Foundation

enum BattleCommand: Equatable {
    case attack
    case spell(Spell)
    case item(Item)
    /// こうげきの ときに 出た「ちしきの チャンス」（`Battle.nextQuiz`）に 答えた こうげき。
    /// ふつうに なぐったあと、正解なら 追い打ちの ダメージ。
    case quizAttack(answer: Int)
    case run
}

enum BattleEnd: Equatable {
    case won(exp: Int, gold: Int)
    case lost
    case fled
}

/// 呪文や道具を使ったときに画面へ出す演出。揺れ・点滅はダメージのほうで出すので、ここには含めない。
enum BattleEffect: Equatable {
    /// 回復：白い湯気の粒に包まれ、緑の「+N」が浮かぶ。
    case heal(Int)
    /// 攻撃呪文：敵へ火の玉が飛び、当たった場所で爆発する。フレイムは大きく。
    case flame(big: Bool)
    /// ボスのほのお：画面の上から火の粉が降りそそぐ。
    case breath
}

/// レベルアップで出す画面。伸びた能力値のあと、覚えた呪文を出す。
enum LevelUpPage: Equatable, Hashable {
    case stats(Hero.LevelUp)
    case spells([Spell])
}

/// 行を出す前の間の取り方。
enum BattleLinePause: Equatable {
    /// 同じ場面の続き（少し待って下に足す）。
    case none
    /// 行動が変わる（長めに待ち、枠を空けて出し直す）。
    case beat
    /// 戦いの結果など、読み飛ばされたくないページ（タップを待ってから出し直す）。
    case page
}

/// 戦闘メッセージの1行と、その行を出すときの音・間・画面の変化。
struct BattleLine: Equatable {
    let text: String
    var cue: SoundCue?
    /// この行で敵に与えたダメージ（画面で敵を揺らし、数字を出すのに使う）。
    var enemyDamage: Int?
    /// ダメージを受けた敵。だれを揺らすかを決める。
    var enemyID: Int?
    /// この行で たおれた敵。画面から消す。
    var defeatedID: Int?
    var isCritical = false
    /// この行で勇者が受けたダメージ（画面を揺らすのに使う）。
    var heroDamage: Int?
    var pause: BattleLinePause = .none
    /// この行で出す演出（呪文・道具）。
    var effect: BattleEffect?
    /// この行で出すレベルアップの画面。文字を流さず、まとめて ぱっと出す。
    var levelUp: LevelUpPage?
    /// この行を出した時点の勇者。HP・MP・レベルの表示をメッセージに合わせて変える。
    var hero: Hero?
}

struct TurnResult: Equatable {
    var lines: [BattleLine] = []
    var end: BattleEnd?

    var messages: [String] { lines.map(\.text) }
    var cues: [SoundCue] { lines.compactMap(\.cue) }
}

/// 勇者ひとり対 敵1〜3体のコマンド戦闘。
/// 画面から切り離した純粋なロジックで、1コマンドごとに1ターン進める。
struct Battle {
    var hero: Hero
    private(set) var enemies: [Enemy]
    private(set) var end: BattleEnd?
    /// 「ちしきの チャンス」で出す問題の山。先頭が次の問題。空なら チャンスは 出ない。
    private(set) var quizzes: [Quiz]

    init(hero: Hero, enemies: [Enemy], quizzes: [Quiz] = []) {
        self.hero = hero
        self.enemies = enemies
        self.quizzes = quizzes
    }

    init(hero: Hero, enemy: Enemy) {
        self.init(hero: hero, enemies: [enemy])
    }

    /// まだ生きている敵。
    var living: [Enemy] { enemies.filter { !$0.isDead } }
    /// ボスがいる戦いか。
    var isBoss: Bool { enemies.contains { $0.kind.isBoss } }
    /// 1体目。画面の見出しなどに使う。
    var enemy: Enemy { enemies.first ?? Enemy(.potato) }
    /// ねらう相手が決まっていないときの相手。
    var defaultTarget: Int? { living.first?.id }
    /// 「ちしきの チャンス」で出す問題。
    var nextQuiz: Quiz? { quizzes.first }
    /// こうげきの ときに「ちしきの チャンス」が 出る 確率（分母）。会心の一撃のように ときどき出る。
    /// ボス戦は 見せ場なので 出やすくする。
    var quizChanceDenominator: Int { isBoss ? 2 : 4 }

    private func index(of id: Int?) -> Int? {
        if let id, let found = enemies.firstIndex(where: { $0.id == id && !$0.isDead }) { return found }
        // ねらっていた敵がもう倒れていたら、生きている先頭に振り替える。
        return enemies.firstIndex { !$0.isDead }
    }

    /// 会心の一撃のダメージ。守備力を無視して、攻撃力の 1.25〜1.75 倍。
    /// 守備力を無視するだけだと、守りの薄い敵にはふつうの攻撃とほぼ同じ威力にしかならない。
    static func criticalDamage(attack: Int, rng: inout some RandomSource) -> Int {
        let low = max(1, attack * 5 / 4)
        let high = max(low + 1, attack * 7 / 4)
        return rng.next(in: low...high)
    }

    /// 通常攻撃のダメージ。(攻撃力 − 守備力/2) の 3/4〜1倍。届かなければ 0〜1。
    static func damage(attack: Int, defense: Int, rng: inout some RandomSource) -> Int {
        let base = attack - defense / 2
        guard base > 0 else { return rng.next(in: 0...1) }
        return rng.next(in: max(1, base * 3 / 4)...base)
    }

    mutating func take(_ command: BattleCommand, target: Int? = nil, rng: inout some RandomSource) -> TurnResult {
        guard end == nil else { return TurnResult(end: end) }
        var result = TurnResult()

        // 素早さで先手を決める（いちばん速い敵と比べる。勇者側をやや有利に）。
        let fastest = living.map(\.agility).max() ?? 0
        let heroFirst = rng.next(in: 0...(hero.agility * 2)) >= rng.next(in: 0...fastest)
        let order: [Bool] = heroFirst ? [true, false] : [false, true]

        for isHeroTurn in order {
            if isHeroTurn {
                heroAct(command, target: target, rng: &rng, into: &result)
            } else {
                enemiesAct(rng: &rng, into: &result)
            }
            if let end = resolveEnd(into: &result) {
                self.end = end
                result.end = end
                return result
            }
        }
        return result
    }

    // MARK: - 行動

    private mutating func heroAct(_ command: BattleCommand, target: Int?, rng: inout some RandomSource, into result: inout TurnResult) {
        guard let slot = index(of: target) else { return }
        switch command {
        case .attack:
            attack(slot, rng: &rng, into: &result)

        case .quizAttack(let choice):
            attack(slot, rng: &rng, into: &result)
            answer(choice, target: target, rng: &rng, into: &result)

        case .spell(let spell):
            guard hero.spells.contains(spell), hero.mp >= spell.mpCost else {
                say("MPが たりない！", .miss, pause: .beat, into: &result)
                return
            }
            hero.mp -= spell.mpCost
            // 攻撃呪文は、唱えた行で火の玉を飛ばしてからダメージの行を出す。
            let castEffect: BattleEffect? = spell.isHealing ? nil : .flame(big: spell == .flame)
            say("\(hero.name)は \(spell.name)を となえた！", .spell, pause: .beat, effect: castEffect, into: &result)
            let amount = rng.next(in: spell.power)
            if spell.isHealing {
                let healed = hero.heal(amount)
                // HP が満タンで 0 しか回復しないときは、粒と「+0」を出さない。
                say("HPが \(healed) かいふくした！", .heal, effect: healed > 0 ? .heal(healed) : nil, into: &result)
            } else {
                hit(slot, for: amount, into: &result)
            }

        case .item(let item):
            guard hero.consume(item) else {
                say("どうぐが ない！", .miss, pause: .beat, into: &result)
                return
            }
            say("\(hero.name)は \(item.name)を つかった！", pause: .beat, into: &result)
            switch item.effect {
            case let .hp(range)?:
                let amount = hero.heal(rng.next(in: range))
                say("HPが \(amount) かいふくした！", .heal, effect: amount > 0 ? .heal(amount) : nil, into: &result)
            case let .mp(range)?:
                let (amount, _) = hero.apply(.mp(range), rng: &rng)
                say("MPが \(amount) かいふくした！", .heal, into: &result)
            case let .blastAll(range)?:
                say("はなびが どどーんと あがった！", .fire, effect: .flame(big: true), into: &result)
                for slot in enemies.indices where !enemies[slot].isDead {
                    hit(slot, for: rng.next(in: range), into: &result)
                }
            case .escape?:
                say("すずの おとが ひびきわたった！", .run, into: &result)
                if isBoss {
                    say("しかし \(enemy.name)は ひるまない！", .miss, into: &result)
                } else {
                    say("てきは おどろいて みちを あけた！", into: &result)
                    end = .fled
                }
            case .grow?, nil:
                say("しかし なにも おこらなかった。", .miss, into: &result)
            }

        case .run:
            if isBoss {
                say("しかし まわりこまれてしまった！", .miss, pause: .beat, into: &result)
                return
            }
            let fastest = living.map(\.agility).max() ?? 0
            let escaped = hero.agility >= fastest ? !rng.chance(4) : rng.chance(2)
            say("\(hero.name)は にげだした！", .run, pause: .beat, into: &result)
            if escaped {
                end = .fled
            } else {
                say("しかし まわりこまれてしまった！", .miss, into: &result)
            }
        }
    }

    /// ふつうの こうげき。16回に1回 会心の一撃。
    private mutating func attack(_ slot: Int, rng: inout some RandomSource, into result: inout TurnResult) {
        say("\(hero.name)の こうげき！", .attack, pause: .beat, into: &result)
        let damage: Int
        let isCritical = rng.chance(16)
        if isCritical {
            say("かいしんの いちげき！", .critical, into: &result)
            damage = Self.criticalDamage(attack: hero.attack, rng: &rng)
        } else {
            damage = Self.damage(attack: hero.attack, defense: enemies[slot].defense, rng: &rng)
        }
        hit(slot, for: damage, isCritical: isCritical, into: &result)
    }

    /// 「ちしきの チャンス」の答え合わせ。こうげきの あとに 出す。
    /// 正解なら 追い打ち（会心なみの一撃）。
    /// まちがえたら 正解を見せる（覚えて 次に使えるように）。ふつうの こうげきは もう 当たっている。
    private mutating func answer(_ choice: Int, target: Int?, rng: inout some RandomSource, into result: inout TurnResult) {
        guard let quiz = quizzes.first, quiz.choices.indices.contains(choice) else { return }
        quizzes.removeFirst()
        say("\(hero.name)「\(quiz.choices[choice])！」", .spell, pause: .beat, into: &result)
        guard choice == quiz.answer else {
            say("ざんねん！ こたえは「\(quiz.correctChoice)」。", .miss, into: &result)
            // まちがえた問題は すぐまた出す（覚えたかを たしかめられるように）。
            quizzes.insert(quiz, at: min(2, quizzes.count))
            return
        }
        quizzes.append(quiz)
        // こうげきで たおしていたら、生きている 先頭に 追い打ちする。
        guard let slot = index(of: target) else { return }
        say("せいかい！ ちしきの ひかりで おいうち！", .critical, effect: .flame(big: true), into: &result)
        hit(slot, for: Self.criticalDamage(attack: hero.attack, rng: &rng), isCritical: true, into: &result)
        // ちしきの ひかりは 敵が 上げた 強さも 消しさる。
        for index in enemies.indices where !enemies[index].isDead && !enemies[index].boosts.isEmpty {
            enemies[index].boosts = [:]
            sayWrapped("\(enemies[index].name)の", "ちからが もとに もどった！", into: &result)
        }
    }

    /// 生きている敵が上から順に動く。
    /// すばやさを 上げた敵は、段の数だけ 3回に1回ずつ もう一度 動ける。
    private mutating func enemiesAct(rng: inout some RandomSource, into result: inout TurnResult) {
        for slot in enemies.indices where !enemies[slot].isDead {
            enemyAct(slot, rng: &rng, into: &result)
            if hero.isDead { return }
            if !enemies[slot].isDead, enemies[slot].stage(.agility) > 0,
               rng.next(in: 1...3) <= enemies[slot].stage(.agility) {
                say("\(enemies[slot].name)は すばやく うごいた！", pause: .beat, into: &result)
                enemyAct(slot, rng: &rng, into: &result)
                if hero.isDead { return }
            }
        }
    }

    /// 敵 1体の 1回ぶんの 行動。わざを 使えないとき（回復する相手が いない・もう上がりきった）は こうげき。
    private mutating func enemyAct(_ slot: Int, rng: inout some RandomSource, into result: inout TurnResult) {
        let attacker = enemies[slot]
        let usable = attacker.kind.specialMoves.filter { canUse($0, by: slot) }
        guard !usable.isEmpty, rng.chance(attacker.kind.specialChance) else {
            say("\(attacker.name)の こうげき！", pause: .beat, into: &result)
            hit(heroFor: Self.damage(attack: attacker.attack, defense: hero.defense, rng: &rng), into: &result)
            return
        }
        switch usable[rng.next(in: 0...(usable.count - 1))] {
        case .magic(let text):
            sayWrapped("\(attacker.name)は", "\(text)！", .fire, pause: .beat, effect: .breath, into: &result)
            hit(heroFor: Self.magicDamage(attack: attacker.attack, rng: &rng), into: &result)
        case .smash:
            say("\(attacker.name)の こうげき！", pause: .beat, into: &result)
            say("つうこんの いちげき！", .critical, into: &result)
            let damage = Self.damage(attack: attacker.attack, defense: hero.defense, rng: &rng)
            hit(heroFor: max(1, damage * 3 / 2), into: &result)
        case .heal(let text):
            sayWrapped("\(attacker.name)は", "\(text)！", .spell, pause: .beat, into: &result)
            enemies[slot].hasHealed = true
            guard let patient = weakestAlly() else { return }
            // ボスは 何度でも 使えるぶん、1回の 量を 少なくする。
            let maxHP = enemies[patient].maxHP
            let range = attacker.kind.isBoss ? (maxHP / 8)...(maxHP / 6) : (maxHP / 4)...(maxHP / 3)
            let amount = rng.next(in: max(1, range.lowerBound)...max(1, range.upperBound))
            let before = enemies[patient].hp
            enemies[patient].hp = min(enemies[patient].maxHP, before + amount)
            if patient == slot {
                say("きずが かいふくした！", .heal, into: &result)
            } else {
                sayWrapped("\(enemies[patient].name)の", "きずが かいふくした！", .heal, into: &result)
            }
        case .boost(let boost, let text):
            sayWrapped("\(attacker.name)は", "\(text)！", .spell, pause: .beat, into: &result)
            enemies[slot].boosts[boost] = min(EnemyBoost.maxStage, enemies[slot].stage(boost) + 1)
            say("\(boost.label)が あがった！", into: &result)
        }
    }

    /// そのわざを いま使って 意味があるか。
    private func canUse(_ move: EnemyMove, by slot: Int) -> Bool {
        switch move {
        case .magic, .smash: true
        case .heal: weakestAlly() != nil && (enemies[slot].kind.isBoss || !enemies[slot].hasHealed)
        case .boost(let boost, _): enemies[slot].stage(boost) < EnemyBoost.maxStage
        }
    }

    /// 生きている敵のうち、HP が半分を 切って いちばん 弱っている者。
    private func weakestAlly() -> Int? {
        enemies.indices
            .filter { !enemies[$0].isDead && enemies[$0].hp * 2 < enemies[$0].maxHP }
            .min { enemies[$0].hp * enemies[$1].maxHP < enemies[$1].hp * enemies[$0].maxHP }
    }

    /// 敵の 呪文・息の ダメージ。守備力を 無視して、こうげき力の 2/5〜3/5。
    /// よろいで 軽くできないので、ふつうの こうげきより 少し 弱くしてある。
    static func magicDamage(attack: Int, rng: inout some RandomSource) -> Int {
        let low = max(1, attack * 2 / 5)
        return rng.next(in: low...max(low, attack * 3 / 5))
    }

    private mutating func hit(_ slot: Int, for damage: Int, isCritical: Bool = false, into result: inout TurnResult) {
        if damage == 0 {
            say("ミス！ ダメージを あたえられない！", .miss, into: &result)
            return
        }
        enemies[slot].hp = max(0, enemies[slot].hp - damage)
        result.lines.append(BattleLine(
            text: "\(enemies[slot].name)に \(damage)の ダメージ！", cue: .hit,
            enemyDamage: damage, enemyID: enemies[slot].id, isCritical: isCritical, hero: hero
        ))
        if enemies[slot].isDead {
            result.lines.append(BattleLine(
                text: "\(enemies[slot].name)を たおした！", defeatedID: enemies[slot].id, hero: hero
            ))
        }
    }

    private mutating func hit(heroFor damage: Int, into result: inout TurnResult) {
        if damage == 0 {
            say("ミス！ ダメージを うけない！", .miss, into: &result)
        } else {
            hero.hp = max(0, hero.hp - damage)
            result.lines.append(BattleLine(
                text: "\(hero.name)は \(damage)の ダメージを うけた！", cue: .damage, heroDamage: damage,
                hero: hero
            ))
        }
    }

    /// 決着がついていれば、勝利の報酬まで反映して終わり方を返す。
    private mutating func resolveEnd(into result: inout TurnResult) -> BattleEnd? {
        if end == .fled { return .fled }
        if living.isEmpty {
            let exp = enemies.reduce(0) { $0 + $1.kind.stats.exp }
            let gold = enemies.reduce(0) { $0 + $1.kind.stats.gold }
            say("たたかいに かった！", .victory, into: &result)
            // 報酬は「かった！」を読んでからタップで次のページに出す。
            var rewardPause = BattleLinePause.page
            if exp > 0 {
                say("けいけんち \(exp)ポイント かくとく", pause: rewardPause, into: &result)
                rewardPause = .none
            }
            if gold > 0 {
                hero.gold += gold
                say("\(gold)ゴールドを てにいれた！", pause: rewardPause, into: &result)
            }
            for levelUp in hero.gainExp(exp) {
                say(levelUp.headline, .levelUp, pause: .page, levelUp: .stats(levelUp), into: &result)
                if !levelUp.learned.isEmpty {
                    say("あたらしい わざを おぼえた！", pause: .page,
                        levelUp: .spells(levelUp.learned), into: &result)
                }
            }
            return .won(exp: exp, gold: gold)
        }
        if hero.isDead {
            say("\(hero.name)は ちからつきた…", .gameOver, pause: .beat, into: &result)
            return .lost
        }
        return nil
    }

    /// 戦いの 枠に 1行で 収まる 文字数。これより 長い文は 2行に 分けて出す（枠が 3行なので 折り返すと はみ出す）。
    static let lineLimit = 18

    /// 「〇〇は」「〜！」を 1行に 収まれば つなげて、長ければ 2行に 分けて出す。音と演出は 1行目に つける。
    private func sayWrapped(
        _ head: String,
        _ tail: String,
        _ cue: SoundCue? = nil,
        pause: BattleLinePause = .none,
        effect: BattleEffect? = nil,
        into result: inout TurnResult
    ) {
        let joined = "\(head) \(tail)"
        if joined.count <= Self.lineLimit {
            say(joined, cue, pause: pause, effect: effect, into: &result)
        } else {
            say(head, cue, pause: pause, effect: effect, into: &result)
            say(tail, into: &result)
        }
    }

    private func say(
        _ text: String,
        _ cue: SoundCue? = nil,
        pause: BattleLinePause = .none,
        effect: BattleEffect? = nil,
        levelUp: LevelUpPage? = nil,
        into result: inout TurnResult
    ) {
        result.lines.append(BattleLine(
            text: text, cue: cue, pause: pause, effect: effect, levelUp: levelUp, hero: hero
        ))
    }
}
