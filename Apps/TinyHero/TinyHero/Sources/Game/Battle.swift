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

struct TurnResult: Equatable {
    var messages: [String] = []
    var end: BattleEnd?
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
            result.messages.append("\(hero.name)の こうげき！")
            let damage: Int
            if rng.chance(16) {
                result.messages.append("かいしんの いちげき！")
                damage = rng.next(in: max(1, hero.attack * 3 / 4)...hero.attack)
            } else {
                damage = Self.damage(attack: hero.attack, defense: enemy.kind.stats.defense, rng: &rng)
            }
            hit(enemyFor: damage, into: &result)

        case .spell(let spell):
            guard hero.spells.contains(spell), hero.mp >= spell.mpCost else {
                result.messages.append("MPが たりない！")
                return
            }
            hero.mp -= spell.mpCost
            result.messages.append("\(hero.name)は \(spell.name)を となえた！")
            let amount = rng.next(in: spell.power)
            if spell.isHealing {
                result.messages.append("HPが \(hero.heal(amount)) かいふくした！")
            } else {
                hit(enemyFor: amount, into: &result)
            }

        case .item(let item):
            guard hero.consume(item) else {
                result.messages.append("どうぐが ない！")
                return
            }
            result.messages.append("\(hero.name)は \(item.name)を つかった！")
            result.messages.append("HPが \(hero.heal(rng.next(in: Item.herbPower))) かいふくした！")

        case .run:
            if enemy.kind.isBoss {
                result.messages.append("しかし まわりこまれてしまった！")
                return
            }
            let escaped = hero.agility >= enemy.kind.stats.agility ? !rng.chance(4) : rng.chance(2)
            if escaped {
                result.messages.append("\(hero.name)は にげだした！")
                end = .fled
            } else {
                result.messages.append("\(hero.name)は にげだした！")
                result.messages.append("しかし まわりこまれてしまった！")
            }
        }
    }

    private mutating func enemyAct(rng: inout some RandomSource, into result: inout TurnResult) {
        if enemy.kind.isBoss, rng.chance(3) {
            result.messages.append("\(enemy.name)は ほのおを はいた！")
            hit(heroFor: rng.next(in: EnemyKind.breathPower), into: &result)
            return
        }
        result.messages.append("\(enemy.name)の こうげき！")
        let damage = Self.damage(attack: enemy.kind.stats.attack, defense: hero.defense, rng: &rng)
        hit(heroFor: damage, into: &result)
    }

    private mutating func hit(enemyFor damage: Int, into result: inout TurnResult) {
        if damage == 0 {
            result.messages.append("ミス！ ダメージを あたえられない！")
        } else {
            enemy.hp = max(0, enemy.hp - damage)
            result.messages.append("\(enemy.name)に \(damage)の ダメージ！")
        }
    }

    private mutating func hit(heroFor damage: Int, into result: inout TurnResult) {
        if damage == 0 {
            result.messages.append("ミス！ ダメージを うけない！")
        } else {
            hero.hp = max(0, hero.hp - damage)
            result.messages.append("\(hero.name)は \(damage)の ダメージを うけた！")
        }
    }

    /// 決着がついていれば、勝利の報酬まで反映して終わり方を返す。
    private mutating func resolveEnd(into result: inout TurnResult) -> BattleEnd? {
        if end == .fled { return .fled }
        if enemy.isDead {
            let stats = enemy.kind.stats
            result.messages.append("\(enemy.name)を たおした！")
            if stats.exp > 0 { result.messages.append("けいけんち \(stats.exp)ポイント かくとく") }
            if stats.gold > 0 { result.messages.append("\(stats.gold)ゴールドを てにいれた！") }
            hero.gold += stats.gold
            result.messages += hero.gainExp(stats.exp)
            return .won(exp: stats.exp, gold: stats.gold)
        }
        if hero.isDead {
            result.messages.append("\(hero.name)は ちからつきた…")
            return .lost
        }
        return nil
    }
}
