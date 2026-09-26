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
        let fastest = living.map(\.kind.stats.agility).max() ?? 0
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
            guard let effect = item.effect else { return }
            let (amount, isMP) = hero.apply(effect, rng: &rng)
            if isMP {
                say("MPが \(amount) かいふくした！", .heal, into: &result)
            } else {
                say("HPが \(amount) かいふくした！", .heal, effect: amount > 0 ? .heal(amount) : nil, into: &result)
            }

        case .run:
            if isBoss {
                say("しかし まわりこまれてしまった！", .miss, pause: .beat, into: &result)
                return
            }
            let fastest = living.map(\.kind.stats.agility).max() ?? 0
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
            damage = Self.damage(attack: hero.attack, defense: enemies[slot].kind.stats.defense, rng: &rng)
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
    }

    /// 生きている敵が上から順に動く。
    private mutating func enemiesAct(rng: inout some RandomSource, into result: inout TurnResult) {
        for slot in enemies.indices where !enemies[slot].isDead {
            let attacker = enemies[slot]
            if attacker.kind.isBoss, rng.chance(3) {
                say("\(attacker.name)は ふぶきを おこした！", .fire, pause: .beat, effect: .breath, into: &result)
                hit(heroFor: rng.next(in: EnemyKind.breathPower), into: &result)
            } else {
                say("\(attacker.name)の こうげき！", pause: .beat, into: &result)
                let damage = Self.damage(attack: attacker.kind.stats.attack, defense: hero.defense, rng: &rng)
                hit(heroFor: damage, into: &result)
            }
            if hero.isDead { return }
        }
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
