import Testing
@testable import GeoHero

/// そうび・はずす・売る。
struct EquipmentTests {

    @Test func startsEquippedAndOwningTheStartingGear() {
        let hero = Hero()
        #expect(hero.weapon == .woodStick)
        #expect(hero.armor == .clothes)
        // はずしたあとに売れるよう、身につけているものも持ちものに入っている。
        #expect(hero.owns(.woodStick))
        #expect(hero.owns(.clothes))
    }

    /// 買った装備は身につくが、前の装備も持ちものに残る（前は消えていた）。
    @Test func buyingKeepsTheOldGear() {
        var hero = Hero()
        hero.receive(.copperSword)
        #expect(hero.weapon == .copperSword)
        #expect(hero.owns(.woodStick), "前のぶきが 消えている")
        #expect(hero.owns(.copperSword))
    }

    @Test func unequippingLeavesItInTheBag() {
        var hero = Hero()
        hero.unequip(.woodStick)
        #expect(hero.weapon == nil)
        #expect(hero.weaponName == "なし")
        #expect(hero.owns(.woodStick))
        // 素手なのでレベルぶんの攻撃力だけ。
        #expect(hero.attack == hero.base.attack)
    }

    @Test func equippingAgainRaisesAttack() {
        var hero = Hero()
        hero.receive(.steelSword)
        hero.unequip(.steelSword)
        let bare = hero.attack
        hero.equip(.steelSword)
        #expect(hero.attack == bare + Item.steelSword.power)
    }

    @Test func cannotEquipWhatYouDoNotOwn() {
        var hero = Hero()
        hero.equip(.steelSword)
        #expect(hero.weapon == .woodStick, "持っていない ぶきを そうびできてしまう")
    }

    // MARK: - 売る

    @Test func sellingGivesHalfThePrice() {
        var hero = Hero()
        hero.receive(.copperSword)
        hero.unequip(.copperSword)
        let before = hero.gold

        let paid = hero.sell(.copperSword)
        #expect(paid == Item.copperSword.price / 2)
        #expect(hero.gold == before + (paid ?? 0))
        #expect(hero.owns(.copperSword) == false)
    }

    @Test func cannotSellWhatYouAreWearing() {
        var hero = Hero()
        let before = hero.gold
        #expect(hero.sell(.woodStick) == nil, "そうび中なのに 売れてしまう")
        #expect(hero.gold == before)
        #expect(hero.owns(.woodStick))
    }

    @Test func cannotSellWhatYouDoNotHave() {
        var hero = Hero()
        #expect(hero.sell(.chainMail) == nil)
    }

    @Test func sellingHerbsReducesTheCount() {
        var hero = Hero()
        let before = hero.herbCount
        _ = hero.sell(.herb)
        #expect(hero.herbCount == before - 1)
    }

    @Test func sellPriceIsNeverZero() {
        for item in Item.allCases {
            #expect(Hero.sellPrice(of: item) >= 1, "\(item.name) の売り値が 0")
            #expect(Hero.sellPrice(of: item) < item.price, "\(item.name) を売って 買い値以上になる")
        }
    }

    // MARK: - 持ちものの並び

    @Test func belongingsListsWhatYouOwn() {
        var hero = Hero()
        hero.receive(.steelSword)
        let names = hero.belongings.map(\.item)
        #expect(names.contains(.herb))
        #expect(names.contains(.woodStick))
        #expect(names.contains(.steelSword))
        #expect(names.contains(.chainMail) == false)
    }

    /// 古いセーブ（装備が持ちものに入っていない）を読んでも、はずして売れる。
    @Test func oldSavesGetTheirGearBackIntoTheBag() {
        var hero = Hero()
        hero.inventory = [.herb: 1]      // 装備が持ちものに無い状態
        hero.weapon = .copperSword
        hero.armor = .leatherArmor
        hero.normalizeInventory()
        #expect(hero.owns(.copperSword))
        #expect(hero.owns(.leatherArmor))
    }
}

/// 道具屋で いくら上がるかが分かるか（能力値の差し引き）。
@MainActor
struct ShopPreviewTests {

    @Test func buyingAnUpgradeShowsTheDifferenceNotTheRawPower() {
        var hero = Hero()
        hero.receive(.copperSword)          // こうげき +8
        let now = hero.attack
        // 鋼の剣（+16）に買い替えたときの本当の伸びは +8。
        let after = hero.base.attack + Item.steelSword.power
        #expect(after - now == Item.steelSword.power - Item.copperSword.power)
    }

    /// 売れるのは どうぐやの中だけ。
    @Test func sellingOnlyWorksInsideTheShop() {
        let game = GameState()
        game.newGame()
        game.say([])
        game.hero.unequip(.woodStick)
        let before = game.hero.gold

        // 店の外では売れない。
        game.overlay = .none
        game.sell(.woodStick)
        #expect(game.hero.gold == before, "どうぐやの外で 売れてしまう")
        #expect(game.hero.owns(.woodStick))

        // 店の中なら売れる。
        game.overlay = .shop
        game.sell(.woodStick)
        #expect(game.hero.gold == before + Hero.sellPrice(of: .woodStick))
        #expect(game.hero.owns(.woodStick) == false)
    }

    /// 売っても店は開いたまま（続けて売れるように）。
    @Test func shopStaysOpenAfterSelling() {
        let game = GameState()
        game.newGame()
        game.say([])
        game.hero.unequip(.clothes)
        game.overlay = .shop
        game.sell(.clothes)
        #expect(game.overlay == .shop)
    }

    /// そうび中のものは 店でも売れない。
    @Test func equippedGearCannotBeSoldEvenInTheShop() {
        let game = GameState()
        game.newGame()
        game.say([])
        game.overlay = .shop
        let before = game.hero.gold
        game.sell(.woodStick)
        #expect(game.hero.gold == before)
        #expect(game.hero.owns(.woodStick))
    }

    /// 同じものは二度買わせない。
    @Test func alreadyOwnedGearIsRefused() {
        let game = GameState()
        game.newGame()
        game.say([])
        game.hero.gold = 1000
        game.buy(.copperSword)
        #expect(game.hero.owns(.copperSword))

        let goldAfterFirst = game.hero.gold
        game.buy(.copperSword)
        #expect(game.hero.gold == goldAfterFirst, "同じ装備を 二度買えてしまう")
    }
}
