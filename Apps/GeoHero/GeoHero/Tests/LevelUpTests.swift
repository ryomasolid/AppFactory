import Testing
@testable import GeoHero

/// レベルアップの見せ方と、会心の一撃の威力。
struct LevelUpTests {

    /// ちょうど次のレベルに上がるだけの経験値。
    private func hero(at level: Int) -> Hero {
        var hero = Hero()
        _ = hero.gainExp(LevelTable.row(level).exp)
        return hero
    }

    @Test func levelUpRestoresHPAndMP() {
        var hero = self.hero(at: 4)
        hero.hp = 1
        hero.mp = 0
        let need = LevelTable.row(5).exp - hero.exp
        _ = hero.gainExp(need)

        #expect(hero.level == 5)
        #expect(hero.hp == hero.maxHP, "レベルアップで HP が全快していない")
        #expect(hero.mp == hero.maxMP, "レベルアップで MP が全快していない")
    }

    /// 上がらなかったときは回復しない。
    @Test func gainingExpWithoutLevelUpDoesNotHeal() {
        var hero = self.hero(at: 3)
        hero.hp = 1
        _ = hero.gainExp(1)
        #expect(hero.level == 3)
        #expect(hero.hp == 1)
    }

    /// 「もとの値 → あがった値」が出る。
    @Test func levelUpShowsHowMuchEachStatGrew() {
        var hero = self.hero(at: 4)
        let before = (hp: hero.maxHP, mp: hero.maxMP, atk: hero.attack, def: hero.defense, agi: hero.agility)
        let need = LevelTable.row(5).exp - hero.exp
        let results = hero.gainExp(need)
        let text = results.flatMap(\.messages).joined(separator: "\n")

        #expect(text.contains("レベル5に あがった！"))
        #expect(text.contains("さいだいHP \(before.hp)→\(hero.maxHP)"))
        #expect(text.contains("MP \(before.mp)→\(hero.maxMP)"))
        #expect(text.contains("こうげき \(before.atk)→\(hero.attack)"))
        #expect(text.contains("しゅび \(before.def)→\(hero.defense)"))
        #expect(text.contains("すばやさ \(before.agi)→\(hero.agility)"))
    }

    /// 装備こみの値で出す（つよさの画面と食い違わないように）。
    @Test func growthUsesEquippedValues() {
        var hero = self.hero(at: 4)
        hero.receive(.steelSword)
        let beforeAttack = hero.attack
        let need = LevelTable.row(5).exp - hero.exp
        let text = hero.gainExp(need).flatMap(\.messages).joined(separator: "\n")
        #expect(text.contains("こうげき \(beforeAttack)→\(hero.attack)"))
    }

    /// 伸びなかった能力値の行は出さない。
    @Test func unchangedStatsAreNotListed() {
        var hero = Hero()
        let text = hero.gainExp(LevelTable.row(2).exp).flatMap(\.messages).joined(separator: "\n")
        // レベル1→2 は すばやさ 4→5 で伸びるので、行は出る。
        #expect(text.contains("すばやさ"))
        // 伸びていない値が「N→N」の形で出ていないこと。
        for value in 1...99 {
            #expect(text.contains("\(value)→\(value)") == false, "伸びていないのに \(value)→\(value) と出ている")
        }
    }

    /// 伸びた能力値は「ラベル・もとの値・あがった値」の形で取り出せる（画面が青く出すため）。
    @Test func gainsCarryBeforeAndAfter() {
        var hero = self.hero(at: 4)
        let need = LevelTable.row(5).exp - hero.exp
        let levelUp = try! #require(hero.gainExp(need).first)

        #expect(levelUp.level == 5)
        #expect(levelUp.gains.isEmpty == false)
        for gain in levelUp.gains {
            #expect(gain.after > gain.before, "\(gain.label) が伸びていないのに入っている")
        }
        #expect(levelUp.gains.contains { $0.label == "さいだいHP" })
    }

    /// 覚えた呪文は 別に持つ（板の2ページ目で出すため）。
    @Test func learnedSpellsAreSeparateFromGains() {
        var hero = Hero()
        let levelUp = try! #require(hero.gainExp(LevelTable.row(2).exp).first)
        #expect(levelUp.learned == [.heal])
        #expect(levelUp.gains.contains { $0.label.contains("HP") })
    }

    /// 呪文が 攻撃か回復かが分かる（アイコンを出し分けるため）。
    @Test func spellsKnowIfTheyHeal() {
        #expect(Spell.heal.isHealing)
        #expect(Spell.highHeal.isHealing)
        #expect(Spell.fire.isHealing == false)
        #expect(Spell.flame.isHealing == false)
    }

    @Test func spellsAreStillAnnounced() {
        var hero = Hero()
        let text = hero.gainExp(LevelTable.row(2).exp).flatMap(\.messages).joined(separator: "\n")
        #expect(text.contains("ヒールを おぼえた！"))
    }

    // MARK: - レベルアップの板が閉じるか

    /// 板を出したまま戦闘が終わると、画面をタップしても進めなくなる。
    /// 再生が終わったときに板が残っていないこと。
    @Test @MainActor func levelUpBoardClosesWhenTheTurnEnds() async {
        let game = GameState()
        game.stepDuration = .zero
        game.messageInterval = .zero
        game.beatPause = .zero
        game.fadeDuration = .zero
        game.waitsForTap = false
        game.rng = AnyRandomSource(SeededRandomSource(seed: 7))
        game.newGame()
        game.say([])
        game.hero.receive(.steelSword)

        // こんぶスライム3体（3EXP×3=9）で レベル1→2 に上がり、ヒールを覚える。
        game.startBattle([.kelpSlime, .kelpSlime, .kelpSlime])
        for _ in 0..<20 where game.battle?.end == nil {
            await game.command(.attack)
        }
        #expect(game.hero.level == 2, "レベルが上がっていない")
        #expect(game.battle?.end != nil)
        #expect(game.battle?.levelUp == nil, "レベルアップの板が出たまま 戦闘が終わっている")
    }

    /// わざを覚えたときは 板の2ページ目（わざ）まで出る。
    @Test func learningASpellAddsASecondPage() {
        var hero = Hero()
        var rng = SeededRandomSource(seed: 7)
        hero.receive(.steelSword)
        var battle = Battle(hero: hero, enemies: EnemyGroup.numbered([.kelpSlime, .kelpSlime, .kelpSlime]))
        var pages: [LevelUpPage] = []
        for _ in 0..<20 where battle.end == nil {
            pages += battle.take(.attack, rng: &rng).lines.compactMap(\.levelUp)
        }
        let hasStats = pages.contains { if case .stats = $0 { return true } else { return false } }
        let hasSpells = pages.contains { if case .spells = $0 { return true } else { return false } }
        #expect(hasStats, "能力値のページが出ていない")
        #expect(hasSpells, "覚えた わざ のページが出ていない")
    }

    // MARK: - 会心の一撃

    /// 会心は守備力を無視して、攻撃力の 1.25〜1.75 倍。
    @Test func criticalIgnoresDefenceAndHitsHard() {
        for attack in [10, 22, 45] {
            var low = FixedRandomSource(pick: .min)
            var high = FixedRandomSource(pick: .max)
            let least = Battle.criticalDamage(attack: attack, rng: &low)
            let most = Battle.criticalDamage(attack: attack, rng: &high)
            #expect(least == attack * 5 / 4, "こうげき \(attack) の会心の下限")
            #expect(most == attack * 7 / 4, "こうげき \(attack) の会心の上限")
        }
    }

    /// 守りの薄い敵にも、ふつうの攻撃よりはっきり強い。
    /// （もとは 攻撃力そのままで、ポテトー相手だと 1.06 倍しかなかった）
    @Test func criticalBeatsNormalHitEvenAgainstSoftEnemies() {
        var rngA = FixedRandomSource(pick: .max)
        var rngB = FixedRandomSource(pick: .max)
        for kind in EnemyKind.allCases {
            let attack = 22
            let normal = Battle.damage(attack: attack, defense: kind.stats.defense, rng: &rngA)
            let critical = Battle.criticalDamage(attack: attack, rng: &rngB)
            #expect(Double(critical) / Double(normal) >= 1.5,
                    "\(kind.stats.name) への会心が ふつうの \(Double(critical) / Double(normal)) 倍しかない")
        }
    }

    @Test func criticalNeverDealsZero() {
        for attack in 1...5 {
            var rng = FixedRandomSource(pick: .min)
            #expect(Battle.criticalDamage(attack: attack, rng: &rng) >= 1)
        }
    }
}
