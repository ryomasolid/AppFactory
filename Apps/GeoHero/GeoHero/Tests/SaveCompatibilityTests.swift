import Foundation
import Testing
@testable import GeoHero

/// 1.4（北海道だけの ころ）の セーブを 2.0 で そのまま 読めるか。
/// セーブは 1.4 の コードで 書き出した 本物（はじめたばかり・札幌の 途中・知床クリア後）。
@MainActor
struct SaveCompatibilityTests {
    static let fixtures: [String: String] = [
        "start": #"""
{"defeatedBosses":[],"hero":{"armor":"clothes","exp":0,"gold":20,"growth":{},"hp":24,"inventory":{"clothes":1,"herb":2,"woodStick":1},"level":1,"mp":0,"name":"そら","weapon":"woodStick"},"interiorReturn":{"x":3,"y":6},"lastTown":"hakodate","map":"innInside","openedChests":[],"position":{"x":4,"y":4},"readPlaques":[],"storyFlags":[]}
"""#,
        "sapporo": #"""
{"defeatedBosses":["komaLord","squidLord"],"hero":{"armor":"samuraiArmor","exp":900,"gold":20,"growth":{"attack":2},"hp":96,"inventory":{"clothes":1,"omagariHanabi":1,"herb":2,"ikameshi":1,"katana":1,"samuraiArmor":1,"woodStick":1},"level":10,"mp":36,"name":"たろう","weapon":"katana"},"lastTown":"sapporo","map":"sapporoArea","openedChests":["field-1","hakodateyama-0"],"position":{"x":20,"y":20},"readPlaques":[{"map":"hakodate","point":{"x":15,"y":21}},{"map":"hakodate","point":{"x":12,"y":12}},{"map":"hakodate","point":{"x":6,"y":4}},{"map":"hakodate","point":{"x":22,"y":10}},{"map":"hakodate","point":{"x":3,"y":14}}],"storyFlags":["hakodateyamaPass","stampHalf","musicBox","childFound","heardFromFisher","childReturned","cygnetReturned","rangerThanked","ramenDelivered","cygnetFound","ramenCarrying","fireCharm","fisherThanked","stampAll"]}
"""#,
        "cleared": #"""
{"defeatedBosses":["squidLord","komaLord","todoLord","bearLord","guardian","tengu"],"hero":{"armor":"driftIceArmor","exp":99999,"gold":20,"growth":{},"hp":136,"inventory":{"attush":1,"bearBell":1,"chainMail":1,"clothes":2,"copperSword":1,"dango":1,"driftIceArmor":1,"glassSword":1,"hakka":1,"omagariHanabi":1,"herb":3,"herringMail":1,"ikameshi":1,"ikuraDon":1,"katana":1,"leatherArmor":1,"melon":1,"milk":1,"misoRamen":1,"onsenTamago":1,"orcaSpear":1,"samuraiArmor":1,"scallopPlate":1,"soybean":1,"squidSpear":1,"steelSword":1,"walnut":1,"woodStick":2},"level":15,"mp":60,"name":"そら","weapon":"orcaSpear"},"lastTown":"rausu","map":"rausu","openedChests":["rausudake2-0"],"position":{"x":10,"y":10},"readPlaques":[{"map":"onuma","point":{"x":21,"y":17}},{"map":"jozankei","point":{"x":7,"y":4}},{"map":"hakodate","point":{"x":15,"y":21}},{"map":"sapporo","point":{"x":22,"y":16}},{"map":"otaru","point":{"x":16,"y":11}},{"map":"otaru","point":{"x":6,"y":11}},{"map":"hakodate","point":{"x":3,"y":14}},{"map":"matsumae","point":{"x":24,"y":19}},{"map":"nakashibetsu","point":{"x":16,"y":2}},{"map":"otaru","point":{"x":16,"y":7}},{"map":"jozankei","point":{"x":14,"y":3}},{"map":"hakodate","point":{"x":12,"y":12}},{"map":"hakodate","point":{"x":6,"y":4}},{"map":"utoro","point":{"x":6,"y":4}},{"map":"utoro","point":{"x":18,"y":9}},{"map":"utoro","point":{"x":3,"y":9}},{"map":"matsumae","point":{"x":7,"y":9}},{"map":"sapporo","point":{"x":8,"y":4}},{"map":"utoro","point":{"x":16,"y":4}},{"map":"rausu","point":{"x":7,"y":3}},{"map":"rausu","point":{"x":21,"y":12}},{"map":"sapporo","point":{"x":26,"y":10}},{"map":"sapporo","point":{"x":10,"y":10}},{"map":"nakashibetsu","point":{"x":12,"y":13}},{"map":"hakodate","point":{"x":22,"y":10}},{"map":"otaru","point":{"x":11,"y":15}},{"map":"rausu","point":{"x":6,"y":6}},{"map":"jozankei","point":{"x":15,"y":6}},{"map":"utoro","point":{"x":9,"y":20}},{"map":"matsumae","point":{"x":3,"y":5}},{"map":"otaru","point":{"x":17,"y":20}},{"map":"onuma","point":{"x":20,"y":12}},{"map":"onuma","point":{"x":5,"y":3}},{"map":"onuma","point":{"x":2,"y":13}},{"map":"sapporo","point":{"x":25,"y":4}},{"map":"sapporo","point":{"x":22,"y":4}},{"map":"rausu","point":{"x":26,"y":8}},{"map":"otaru","point":{"x":8,"y":5}},{"map":"rausu","point":{"x":15,"y":10}},{"map":"matsumae","point":{"x":10,"y":6}},{"map":"matsumae","point":{"x":14,"y":16}}],"storyFlags":["childFound","fisherThanked","catReturned","kamuiFeather","milkThanked","heardFromFisher","cygnetReturned","stampAll","cygnetFound","stampHalf","childReturned","fireCharm","hakodateyamaPass","sapporoStampAll","milkCarrying","shiretokoStampHalf","milkDelivered","foxReturned","ticketToShiretoko","ramenCarrying","rangerThanked","catFound","ramenDelivered","shiretokoStampAll","ticketToSapporo","ramenThanked","musicBox","sapporoStampHalf","foxFound"]}
"""#,
    ]

    static func load(_ name: String) throws -> SaveData {
        let json = try #require(fixtures[name])
        return try JSONDecoder().decode(SaveData.self, from: Data(json.utf8))
    }

    @Test(arguments: ["start", "sapporo", "cleared"])
    func oldSavesDecode(name: String) throws {
        let save = try Self.load(name)
        // 開けた 宝箱は いまの 地図にも ある。
        let chests = Set(World.all.values.flatMap(\.chests).map(\.id))
        for id in save.openedChests { #expect(chests.contains(id), "\(name): 宝箱 \(id) が ない") }
        // 押した スタンプは いまの 看板と 合う。
        for plaque in save.readPlaques { #expect(World.stampPlaques.contains(plaque), "\(name): スタンプ \(plaque) が ない") }
        // 1.4 の 印は ぜんぶ 物語の どこかで 使われている。
        for flag in save.storyFlags { #expect(Story.allFlags.contains(flag), "\(name): 印 \(flag) を しらない") }
        // 持ちものと 装備は 北海道の 品の まま。
        #expect(save.hero.weapon?.name.isEmpty == false)
        #expect(save.hero.armor?.name.isEmpty == false)
    }

    @Test(arguments: ["start", "sapporo", "cleared"])
    func continueFromOldSave(name: String) throws {
        let defaults = try #require(UserDefaults(suiteName: "geohero.compat.\(UUID().uuidString)"))
        defaults.set(Data(try #require(Self.fixtures[name]).utf8), forKey: SaveStore.key)
        let save = try #require(SaveStore.load(from: defaults))
        let game = GameStateTests.makeGame()
        SaveStore.save(save, to: .standard)
        game.continueGame()
        #expect(game.screen == .field)
        #expect(game.map.contains(game.position) && game.map.tile(at: game.position).isPassable)
        #expect(game.hero == save.hero)
        #expect(!game.region.isTohoku)
    }

    /// 知床を クリアした セーブなら 新函館北斗駅から 青森へ 行ける。途中の セーブは まだ 行けない。
    @Test func clearedSaveCanRideToAomori() throws {
        let cleared = try Self.load("cleared")
        #expect(StoryProgress(flags: cleared.storyFlags, defeatedBosses: cleared.defeatedBosses).canTravel(to: .aomori))
        let middle = try Self.load("sapporo")
        #expect(!StoryProgress(flags: middle.storyFlags, defeatedBosses: middle.defeatedBosses).canTravel(to: .aomori))
    }

    @Test func saveKeyIsUnchanged() {
        #expect(SaveStore.key == "geohero.save.v2")
    }
}
