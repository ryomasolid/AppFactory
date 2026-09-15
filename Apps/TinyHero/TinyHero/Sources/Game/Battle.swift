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
                damage = rng.next(in: max(1, hero.attack * 3 / 4)...hero.attack)
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
            say("\(hero.name)は \(spell.name)を となえた！", .spell, pause: .beat, into: &result)
            let amount = rng.next(in: spell.power)
            if spell.isHealing {
                let healed = hero.heal(amount)
                say("HPが \(healed) かいふくした！", .heal, into: &result)
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
            say("HPが \(healed) かいふくした！", .heal, into: &result)

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
            say("\(enemy.name)は ほのおを はいた！", .fire, pause: .beat, into: &result)
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
                text: "\(enemy.name)に \(damage)の ダメージ！", cue: .hit, enemyDamage: damage, isCritical: isCritical, hero: hero
            ))
        }
    }

    private mutating func hit(heroFor damage: Int, into result: inout TurnResult) {
        if damage == 0 {
            say("ミス！ ダメージを うけない！", .miss, into: &result)
        } else {
            hero.hp = max(0, hero.hp - damage)
            result.lines.append(BattleLine(
                text: "\(hero.name)は \(damage)の ダメージを うけた！", cue: .damage, heroDamage: damage, hero: hero
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

    private func say(_ text: String, _ cue: SoundCue? = nil, pause: BattleLinePause = .none, into result: inout TurnResult) {
        result.lines.append(BattleLine(text: text, cue: cue, pause: pause, hero: hero))
    }
}
