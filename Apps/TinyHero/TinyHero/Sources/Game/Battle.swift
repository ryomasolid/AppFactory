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

/// 戦闘メッセージの1行と、その行を出すときに鳴らす音。
struct BattleLine: Equatable {
    let text: String
    var cue: SoundCue?
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
            result.say("\(hero.name)の こうげき！", .attack)
            let damage: Int
            if rng.chance(16) {
                result.say("かいしんの いちげき！", .critical)
                damage = rng.next(in: max(1, hero.attack * 3 / 4)...hero.attack)
            } else {
                damage = Self.damage(attack: hero.attack, defense: enemy.kind.stats.defense, rng: &rng)
            }
            hit(enemyFor: damage, into: &result)

        case .spell(let spell):
            guard hero.spells.contains(spell), hero.mp >= spell.mpCost else {
                result.say("MPが たりない！", .miss)
                return
            }
            hero.mp -= spell.mpCost
            result.say("\(hero.name)は \(spell.name)を となえた！", .spell)
            let amount = rng.next(in: spell.power)
            if spell.isHealing {
                result.say("HPが \(hero.heal(amount)) かいふくした！", .heal)
            } else {
                hit(enemyFor: amount, into: &result)
            }

        case .item(let item):
            guard hero.consume(item) else {
                result.say("どうぐが ない！", .miss)
                return
            }
            result.say("\(hero.name)は \(item.name)を つかった！")
            result.say("HPが \(hero.heal(rng.next(in: Item.herbPower))) かいふくした！", .heal)

        case .run:
            if enemy.kind.isBoss {
                result.say("しかし まわりこまれてしまった！", .miss)
                return
            }
            let escaped = hero.agility >= enemy.kind.stats.agility ? !rng.chance(4) : rng.chance(2)
            if escaped {
                result.say("\(hero.name)は にげだした！", .run)
                end = .fled
            } else {
                result.say("\(hero.name)は にげだした！", .run)
                result.say("しかし まわりこまれてしまった！", .miss)
            }
        }
    }

    private mutating func enemyAct(rng: inout some RandomSource, into result: inout TurnResult) {
        if enemy.kind.isBoss, rng.chance(3) {
            result.say("\(enemy.name)は ほのおを はいた！", .fire)
            hit(heroFor: rng.next(in: EnemyKind.breathPower), into: &result)
            return
        }
        result.say("\(enemy.name)の こうげき！")
        let damage = Self.damage(attack: enemy.kind.stats.attack, defense: hero.defense, rng: &rng)
        hit(heroFor: damage, into: &result)
    }

    private mutating func hit(enemyFor damage: Int, into result: inout TurnResult) {
        if damage == 0 {
            result.say("ミス！ ダメージを あたえられない！", .miss)
        } else {
            enemy.hp = max(0, enemy.hp - damage)
            result.say("\(enemy.name)に \(damage)の ダメージ！", .hit)
        }
    }

    private mutating func hit(heroFor damage: Int, into result: inout TurnResult) {
        if damage == 0 {
            result.say("ミス！ ダメージを うけない！", .miss)
        } else {
            hero.hp = max(0, hero.hp - damage)
            result.say("\(hero.name)は \(damage)の ダメージを うけた！", .damage)
        }
    }

    /// 決着がついていれば、勝利の報酬まで反映して終わり方を返す。
    private mutating func resolveEnd(into result: inout TurnResult) -> BattleEnd? {
        if end == .fled { return .fled }
        if enemy.isDead {
            let stats = enemy.kind.stats
            result.say("\(enemy.name)を たおした！", .victory)
            if stats.exp > 0 { result.say("けいけんち \(stats.exp)ポイント かくとく") }
            if stats.gold > 0 { result.say("\(stats.gold)ゴールドを てにいれた！") }
            hero.gold += stats.gold
            for message in hero.gainExp(stats.exp) {
                result.say(message, message.contains("あがった") ? .levelUp : nil)
            }
            return .won(exp: stats.exp, gold: stats.gold)
        }
        if hero.isDead {
            result.say("\(hero.name)は ちからつきた…", .gameOver)
            return .lost
        }
        return nil
    }
}

private extension TurnResult {
    mutating func say(_ text: String, _ cue: SoundCue? = nil) {
        lines.append(BattleLine(text: text, cue: cue))
    }
}
