import Foundation

enum BattleCommand: Equatable {
    case attack
    case spell(Spell)
    case item(Item)
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
    var isCritical = false
    /// この行で勇者が受けたダメージ（画面を揺らすのに使う）。
    var heroDamage: Int?
    var pause: BattleLinePause = .none
    /// この行で出す演出（呪文・道具）。
    var effect: BattleEffect?
    /// この行を出した時点の勇者。HP・MP・レベルの表示をメッセージに合わせて変える。
    var hero: Hero?
}

struct TurnResult: Equatable {
    var lines: [BattleLine] = []
    var end: BattleEnd?

    var messages: [String] { lines.map(\.text) }
    var cues: [SoundCue] { lines.compactMap(\.cue) }
}

/// 1対1のコマンド戦闘。画面から切り離した純粋なロジックで、1コマンドごとに1ターン進める。
struct Battle {
    var hero: Hero
    var enemy: Enemy
    private(set) var end: BattleEnd?

    init(hero: Hero, enemy: Enemy) {
        self.hero = hero
        self.enemy = enemy
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

    mutating func take(_ command: BattleCommand, rng: inout some RandomSource) -> TurnResult {
        guard end == nil else { return TurnResult(end: end) }
        var result = TurnResult()

        // 素早さで先手を決める（勇者側をやや有利に）。
        let heroFirst = rng.next(in: 0...(hero.agility * 2)) >= rng.next(in: 0...enemy.kind.stats.agility)
        let order: [Bool] = heroFirst ? [true, false] : [false, true]

        for isHeroTurn in order {
            if isHeroTurn {
                heroAct(command, rng: &rng, into: &result)
            } else {
                enemyAct(rng: &rng, into: &result)
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

    private mutating func heroAct(_ command: BattleCommand, rng: inout some RandomSource, into result: inout TurnResult) {
        switch command {
        case .attack:
            say("\(hero.name)の こうげき！", .attack, pause: .beat, into: &result)
            let damage: Int
            let isCritical = rng.chance(16)
            if isCritical {
                say("かいしんの いちげき！", .critical, into: &result)
                damage = Self.criticalDamage(attack: hero.attack, rng: &rng)
            } else {
                damage = Self.damage(attack: hero.attack, defense: enemy.kind.stats.defense, rng: &rng)
            }
            hit(enemyFor: damage, isCritical: isCritical, into: &result)

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
                hit(enemyFor: amount, into: &result)
            }

        case .item(let item):
            guard hero.consume(item) else {
                say("どうぐが ない！", .miss, pause: .beat, into: &result)
                return
            }
            say("\(hero.name)は \(item.name)を つかった！", pause: .beat, into: &result)
            let healed = hero.heal(rng.next(in: Item.herbPower))
            say("HPが \(healed) かいふくした！", .heal, effect: healed > 0 ? .heal(healed) : nil, into: &result)

        case .run:
            if enemy.kind.isBoss {
                say("しかし まわりこまれてしまった！", .miss, pause: .beat, into: &result)
                return
            }
            let escaped = hero.agility >= enemy.kind.stats.agility ? !rng.chance(4) : rng.chance(2)
            say("\(hero.name)は にげだした！", .run, pause: .beat, into: &result)
            if escaped {
                end = .fled
            } else {
                say("しかし まわりこまれてしまった！", .miss, into: &result)
            }
        }
    }

    private mutating func enemyAct(rng: inout some RandomSource, into result: inout TurnResult) {
        if enemy.kind.isBoss, rng.chance(3) {
            say("\(enemy.name)は ふぶきを おこした！", .fire, pause: .beat, effect: .breath, into: &result)
            hit(heroFor: rng.next(in: EnemyKind.breathPower), into: &result)
            return
        }
        say("\(enemy.name)の こうげき！", pause: .beat, into: &result)
        let damage = Self.damage(attack: enemy.kind.stats.attack, defense: hero.defense, rng: &rng)
        hit(heroFor: damage, into: &result)
    }

    private mutating func hit(enemyFor damage: Int, isCritical: Bool = false, into result: inout TurnResult) {
        if damage == 0 {
            say("ミス！ ダメージを あたえられない！", .miss, into: &result)
        } else {
            enemy.hp = max(0, enemy.hp - damage)
            result.lines.append(BattleLine(
                text: "\(enemy.name)に \(damage)の ダメージ！", cue: .hit, enemyDamage: damage, isCritical: isCritical,
                hero: hero
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
        if enemy.isDead {
            let stats = enemy.kind.stats
            say("\(enemy.name)を たおした！", .victory, into: &result)
            // 報酬は「たおした！」を読んでからタップで次のページに出す。
            var rewardPause = BattleLinePause.page
            if stats.exp > 0 {
                say("けいけんち \(stats.exp)ポイント かくとく", pause: rewardPause, into: &result)
                rewardPause = .none
            }
            if stats.gold > 0 {
                hero.gold += stats.gold
                say("\(stats.gold)ゴールドを てにいれた！", pause: rewardPause, into: &result)
            }
            for message in hero.gainExp(stats.exp) {
                let isLevelUp = message.contains("あがった")
                say(message, isLevelUp ? .levelUp : nil, pause: isLevelUp ? .page : .none, into: &result)
            }
            return .won(exp: stats.exp, gold: stats.gold)
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
        into result: inout TurnResult
    ) {
        result.lines.append(BattleLine(text: text, cue: cue, pause: pause, effect: effect, hero: hero))
    }
}
