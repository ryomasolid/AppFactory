import Testing
@testable import GeoHero2

/// 物語が さいごまで 進む。
/// 人に 話しかけて 立った 印で 関所が ひらき、ボスを 倒すと 次へ……を くりかえして、
/// 守護神と 恐山の まおうの かげまで たどりつけるかを 見る。
struct StoryTests {

    /// いまの 進みぐあいで 入れる 県の 地図。
    private func maps(open progress: StoryProgress) -> [GameMap] {
        World.all.values.filter { map in
            guard let region = map.region else { return false }
            return progress.canTravel(to: region)
        }
    }

    /// その ボスの 部屋に 入れるか（ほらあなへの 道の 関所を ぜんぶ こえられるか）。
    private func canReachBoss(_ kind: EnemyKind, _ progress: StoryProgress) -> Bool {
        guard let room = World.all.values.first(where: { $0.bossKind == kind }) else { return false }
        var current = room.id
        for _ in 0..<5 {
            guard let (map, warp) = World.all.values.lazy.compactMap({ map -> (GameMap, Warp)? in
                guard let found = map.warps.first(where: { $0.value.to == current
                    && [.cave, .stairsDown].contains(map.tile(at: $0.key)) }) else { return nil }
                return (map, found.value)
            }).first else { return false }
            if let need = warp.needs, !progress.has(need) { return false }
            if let need = warp.requires, !progress.defeatedBosses.contains(need) { return false }
            if map.kind == .field { return progress.canTravel(to: map.region!) }
            current = map.id
        }
        return false
    }

    /// 話して 倒して を くりかえし、倒した 順の ボスを 返す。
    private func playThrough(examsPassed: Bool) -> (order: [EnemyKind], progress: StoryProgress) {
        var progress = StoryProgress(flags: [], defeatedBosses: [], stamps: [:], seen: 0)
        if examsPassed { progress.flags.formUnion(Region.allCases.map(StoryFlag.examPassed)) }
        var order: [EnemyKind] = []
        for _ in 0..<60 {
            var changed = false
            for map in maps(open: progress) {
                for npc in map.npcs(progress) {
                    guard case let .resident(resident) = npc.role else { continue }
                    let scene = resident.scene(progress)
                    let fresh = Set(scene.sets).subtracting(progress.flags)
                    if !fresh.isEmpty { progress.flags.formUnion(fresh); changed = true }
                }
            }
            if let boss = EnemyKind.allCases.first(where: { $0.isBoss && !progress.defeatedBosses.contains($0)
                && canReachBoss($0, progress) }) {
                progress.defeatedBosses.insert(boss)
                order.append(boss)
                changed = true
            }
            if !changed { break }
        }
        return (order, progress)
    }

    @Test func theWholeStoryCanBeFinished() {
        let (order, _) = playThrough(examsPassed: true)
        let expected: [EnemyKind] = Region.allCases.flatMap { [$0.subBoss, $0.lord] } + [.maouShadow]
        #expect(order == expected, "ボスの 順番: \(order.map(\.name))")
    }

    /// 検定に 合格していないと まおうの かげには とどかない。
    @Test func secretBossNeedsEveryExam() {
        let (order, _) = playThrough(examsPassed: false)
        #expect(order.contains(.guardian))
        #expect(!order.contains(.maouShadow))
    }

    /// ぬしを 倒す まで 次の 県へは 行けない。
    @Test func trainNeedsThePreviousLord() {
        var progress = StoryProgress(flags: [], defeatedBosses: [], stamps: [:])
        #expect(progress.canTravel(to: .aomori))
        #expect(!progress.canTravel(to: .akita))
        progress.defeatedBosses.insert(.yukioni)
        #expect(progress.canTravel(to: .akita))
        #expect(!progress.canTravel(to: .iwate))
    }

    /// 関所の 印には かならず 止められたときの せりふが ある。
    @Test func everyGateExplainsItself() {
        for map in World.all.values {
            for warp in map.warps.values {
                guard let need = warp.needs else { continue }
                #expect(Story.gates[need] != nil, "\(map.id) → \(warp.to) の 関所 \(need) の せりふが ない")
            }
        }
    }

    /// 長老は どの だんかいでも 次に やることを 教える。
    @Test func elderAlwaysHasAHint() {
        let (_, finished) = playThrough(examsPassed: true)
        #expect(Story.elderHint(finished).joined().contains("しんの ちりの ゆうしゃ"))
        let start = StoryProgress(flags: [], defeatedBosses: [], stamps: [:])
        #expect(Story.elderHint(start).joined().contains("ねぶた師"))
    }

    /// おつかい・迷子さがしは さいごまで すすめられ、お礼が もらえる。
    @Test func sideQuestsFinish() {
        for errand in Errand.all {
            var progress = StoryProgress(flags: [], defeatedBosses: [], stamps: [:])
            for step in 0..<3 {
                let scene = step == 1 ? errand.receiverScene(progress) : errand.giverScene(progress)
                progress.flags.formUnion(scene.sets)
            }
            #expect(progress.has(errand.thanked), "\(errand.id) が おわらない")
        }
        for quest in LostQuest.all {
            var progress = StoryProgress(flags: [], defeatedBosses: [], stamps: [:])
            progress.flags.formUnion(quest.lostScene().sets)
            progress.flags.formUnion(quest.seekerScene(progress).sets)
            #expect(progress.has(quest.returned), "\(quest.id) が おわらない")
            #expect(!quest.ask.isEmpty && !quest.home.isEmpty)
        }
    }

    /// 物語の 人は みんな どこかの 地図に いる（迷子は 見つけたあとの すがたも）。
    @Test func everyResidentIsPlaced() {
        let placed = Set(World.all.values.flatMap(\.npcs).compactMap { npc -> Resident? in
            if case let .resident(resident) = npc.role { return resident }
            return nil
        })
        for resident in Resident.allCases {
            #expect(placed.contains(resident), "\(resident) が 地図に いない")
            #expect(resident.scene(StoryProgress(flags: [], defeatedBosses: [], stamps: [:])).lines != ["……"],
                    "\(resident) の せりふが ない")
        }
    }

    /// 案内所は 半分で 道具、ぜんぶで ゴールド。
    @Test func stampGuidesReward() {
        let total = World.stampTotal(in: .aomori)
        var progress = StoryProgress(flags: [], defeatedBosses: [], stamps: [.aomori: (total + 1) / 2])
        let half = Resident.aomoriGuide.scene(progress)
        #expect(half.items.count == 3)
        progress.flags.formUnion(half.sets)
        progress.stamps[.aomori] = total
        #expect(Resident.aomoriGuide.scene(progress).gold > 0)
    }

    /// 学芸員は ずかんの 数で ごほうびを くれる。
    @Test func curatorRewardsTheBook() {
        var progress = StoryProgress(flags: [], defeatedBosses: [], stamps: [:], seen: 10)
        #expect(Story.curatorScene(progress).items.isEmpty)
        progress.seen = 30
        let first = Story.curatorScene(progress)
        #expect(first.items == [.tanzaku])
        progress.flags.formUnion(first.sets)
        #expect(Story.curatorScene(progress).items.isEmpty)
        progress.seen = EnemyKind.allCases.count
        let second = Story.curatorScene(progress)
        #expect(second.items == [.okiagari])
    }

    /// 検定の 先生は 合格前なら 検定を はじめる。
    @Test func examinersStartTheExam() {
        for region in Region.allCases {
            let scene = Story.examScene(region, StoryProgress(flags: [], defeatedBosses: [], stamps: [:]))
            #expect(scene.startsExam == region)
            #expect(QuizBank.quizzes(in: region).count >= Story.examLength * 3)
        }
    }

    /// ボスの あいさつと たおしたあとの せりふが ある（ラスボス・裏ボスは エンディングへ）。
    @Test func bossesHaveLines() {
        for kind in EnemyKind.allCases where kind.isBoss {
            #expect(Story.bossGreeting(kind).count >= 2, "\(kind)")
            if !kind.isFinalBoss && !kind.isSecretBoss {
                #expect(!Story.bossDefeated(kind).isEmpty, "\(kind)")
            }
        }
    }
}
