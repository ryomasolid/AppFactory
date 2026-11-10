import StoreKit
import SwiftUI

struct FieldView: View {
    @Environment(GameState.self) private var game
    @Environment(\.requestReview) private var requestReview

    /// 横に見えるマス数（奇数にして勇者を真ん中に置く）。
    static let columns = 11

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                // マスは 整数の ポイントに そろえる（板の 継ぎ目に すきまが 出ないように）。
                let tile = (geo.size.width / CGFloat(Self.columns)).rounded(.up)
                let center = CGPoint(x: (geo.size.width - tile) / 2, y: (geo.size.height - tile) / 2)
                ZStack(alignment: .topLeading) {
                    MapLayer(
                        map: game.map,
                        npcs: game.npcs,
                        openedChests: game.openedChests,
                        boss: game.bossPoint,
                        tile: tile,
                        center: game.position,
                        // 画面に入る範囲＋すこし余分だけ描く。
                        radius: Int((geo.size.height / tile / 2).rounded(.up)) + 2
                    )
                        .offset(
                            x: center.x - CGFloat(game.position.x + MapLayer.padding) * tile,
                            y: center.y - CGFloat(game.position.y + MapLayer.padding) * tile
                        )
                        // 1歩（0.15秒）と おなじ 長さ。長くすると つぎの 1歩と かさなった あいだだけ 速くなり、ガクッと 見える。
                        .animation(game.lastMoveWasWarp ? nil : .linear(duration: 0.15), value: game.position)

                    SpriteCache.image(.hero(facing: game.facing, step: game.walkFrame))
                        .resizable()
                        .interpolation(.none)
                        .frame(width: tile, height: tile)
                        .offset(x: center.x, y: center.y)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                .clipped()
            }
            // 地図より大きい ZStack の中に置くと 右端が画面の外へ出てしまうので、上にかぶせる。
            .overlay(alignment: .top) {
                HStack(alignment: .top) {
                    StatusPanel(hero: game.hero)
                    Spacer()
                    Text(placeLabel)
                        .font(Retro.font(13))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 4))
                }
                .padding(8)
            }
            // 真ん中の勇者に かぶらないよう、ステータスの下あたりに出す。
            .overlay(alignment: .top) {
                if let banner = game.arrivalBanner {
                    PlaceBannerView(banner: banner)
                        .padding(.top, 150)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .allowsHitTesting(false)
                }
            }
            .animation(.easeOut(duration: 0.35), value: game.arrivalBanner)
            .overlay(alignment: .top) {
                FieldOverlay()
                    .padding(.top, 120)
            }
            .overlay(alignment: .bottom) {
                if let page = game.currentPage {
                    MessageBox(lines: page, speaker: game.currentSpeaker)
                        .onTapGesture { game.advanceMessage() }
                }
            }

            ControlPad()
        }
        // ぬしを たおした 話を 読みおえたら、iOS の 評価の ダイアログを 出す（バージョンごとに 1回）。
        .onChange(of: game.reviewRequests) { _, _ in requestReview() }
    }
}

extension FieldView {
    /// 右上の地名。街は 漢字に よみを そえる。
    private var placeLabel: String {
        guard let town = game.map.id.townInfo else { return game.map.name }
        return "\(town.name)（\(town.reading)）"
    }
}

/// 街に入ったとき・ひこうきで着いたときに 真ん中に しばらく出す 地名の札。
struct PlaceBannerView: View {
    let banner: PlaceBanner

    var body: some View {
        VStack(spacing: 6) {
            Text(banner.reading)
                .font(Retro.font(14))
                .foregroundStyle(Retro.dim)
            Text(banner.name)
                .font(Retro.font(banner.name.count > 3 ? 32 : 40))
                .foregroundStyle(Retro.accent)
            Text(banner.tagline)
                .font(Retro.font(15))
                .foregroundStyle(Retro.ink)
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 18)
        .background(Color.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white, lineWidth: 3))
    }
}

/// マップを 描く。外周に `padding` マス分だけ「外側の地形」を足し、端でも黒い余白が見えないようにする。
///
/// 地面は 8×8 マスの 小さな 板（`MapChunk`）に わけて 描く。板は 一度 描いたら 歩いても 描きなおさず、
/// 歩くときの スクロールは 外側（FieldView）の offset だけで 見せる（GPU が 板を ずらすだけなので なめらか）。
/// 前は 地図ぜんぶの 大きさの 1枚の 板を 1歩ごとに 描きなおしていて、歩くたびに 引っかかっていた。
/// 町・ほらあな・人・宝箱などは 板とは べつの 絵として かさねる（板の ふちで 大きな 絵が 切れないように）。
struct MapLayer: View {
    static let padding = 7
    /// 地面の 板の 1辺の マス数。
    static let chunkSize = 8

    let map: GameMap
    /// いま出ている人（迷子のように 出たり消えたりする人がいる）。
    let npcs: [NPC]
    let openedChests: Set<String>
    /// まだ立っているボスのマス。倒したあとは nil（絵も消す）。
    let boss: Point?
    let tile: CGFloat
    /// 勇者のいるマス。この まわりの 板だけ 置く。
    let center: Point
    /// 中心から何マスぶん描くか。
    let radius: Int

    /// 大きく描く地形と、その絵・倍率。
    /// 絵は背景を透かした版を使う。不透明のままだと まわりのマス（海や道）を塗りつぶしてしまう。
    static func landmark(_ tile: Tile) -> (sprite: SpriteID, scale: CGFloat)? {
        switch tile {
        case .town: (.townLarge, 2.0)
        case .cave: (.caveLarge, 1.7)
        case .airport: (.airportLarge, 1.8)
        case .station: (.stationLarge, 1.8)
        default: nil
        }
    }

    /// マスの底に足をそろえたまま大きくする（建物が地面に立って見えるように）。
    static func standing(_ rect: CGRect, scale: CGFloat) -> CGRect {
        let size = rect.width * scale
        return CGRect(
            x: rect.midX - size / 2,
            y: rect.maxY - size,
            width: size,
            height: size
        )
    }

    /// 勇者の まわりに 置く 板（板の 番号。マス = 番号 × chunkSize）。
    /// 板の 境目を またぐまでは 同じ 並びを 返すので、1歩ごとには 板が 入れかわらない。
    static func chunks(around center: Point, radius: Int, map: GameMap) -> [Point] {
        let size = chunkSize
        func floorDiv(_ a: Int) -> Int { a >= 0 ? a / size : -((-a + size - 1) / size) }
        let minX = floorDiv(max(-padding, center.x - radius))
        let maxX = floorDiv(min(map.width + padding - 1, center.x + radius))
        let minY = floorDiv(max(-padding, center.y - radius))
        let maxY = floorDiv(min(map.height + padding - 1, center.y + radius))
        return (minY...maxY).flatMap { y in (minX...maxX).map { Point(x: $0, y: y) } }
    }

    var body: some View {
        let pad = Self.padding
        let chunks = Self.chunks(around: center, radius: radius, map: map)
        // 板の ならぶ 範囲（マス）。人や 宝箱も この 範囲の ものだけ 置く。
        let area = (
            minX: (chunks.map(\.x).min() ?? 0) * Self.chunkSize, maxX: ((chunks.map(\.x).max() ?? 0) + 1) * Self.chunkSize,
            minY: (chunks.map(\.y).min() ?? 0) * Self.chunkSize, maxY: ((chunks.map(\.y).max() ?? 0) + 1) * Self.chunkSize
        )
        let inArea: (Point) -> Bool = { p in p.x >= area.minX && p.x < area.maxX && p.y >= area.minY && p.y < area.maxY }

        ZStack(alignment: .topLeading) {
            ForEach(chunks, id: \.self) { chunk in
                MapChunk(map: map, chunk: chunk, tile: tile)
                    .equatable()
                    .offset(x: CGFloat(chunk.x * Self.chunkSize + pad) * tile,
                            y: CGFloat(chunk.y * Self.chunkSize + pad) * tile)
                    // 新しく 置く 板は ふわっと 出さずに すぐ 出す（歩く アニメーションに まきこまれないように）。
                    .transition(.identity)
            }
            ForEach(sprites(where: inArea), id: \.id) { sprite in
                SpriteCache.image(sprite.sprite)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: sprite.rect.width, height: sprite.rect.height)
                    .offset(x: sprite.rect.minX, y: sprite.rect.minY)
                    .transition(.identity)
            }
            ForEach(captions(where: inArea), id: \.id) { caption in
                caption.view
                    .transition(.identity)
            }
        }
        .frame(width: CGFloat(map.width + pad * 2) * tile, height: CGFloat(map.height + pad * 2) * tile,
               alignment: .topLeading)
    }

    private struct PlacedSprite {
        let id: String
        let sprite: SpriteID
        let rect: CGRect
    }

    /// 町・ほらあなの 大きな 絵、宝箱、人、ボス（かさねる 順）。
    private func sprites(where visible: (Point) -> Bool) -> [PlacedSprite] {
        var result: [PlacedSprite] = []
        for (y, row) in map.tiles.enumerated() where visible(Point(x: max(0, centerColumn), y: y)) {
            for (x, kind) in row.enumerated() {
                let point = Point(x: x, y: y)
                guard let mark = Self.landmark(kind), visible(point) else { continue }
                result.append(PlacedSprite(id: "mark-\(x)-\(y)", sprite: mark.sprite,
                                           rect: Self.standing(rect(for: point), scale: mark.scale)))
            }
        }
        for chest in map.chests where visible(chest.position) {
            let sprite: SpriteID = openedChests.contains(chest.id) ? .chestOpen : .chestClosed
            result.append(PlacedSprite(id: "chest-\(chest.id)", sprite: sprite, rect: rect(for: chest.position)))
        }
        for npc in npcs where visible(npc.position) {
            result.append(PlacedSprite(id: "npc-\(npc.position.x)-\(npc.position.y)", sprite: SpriteID(npc: npc.role),
                                       rect: rect(for: npc.position)))
        }
        if let boss, visible(boss) {
            // そのマップのボスの絵で出す（どの ほらあなでも守護神が座っていた）。
            let sprite = map.bossKind.map(SpriteID.init(enemy:)) ?? .guardian
            result.append(PlacedSprite(id: "boss", sprite: sprite,
                                       rect: rect(for: boss).insetBy(dx: -tile * 0.25, dy: -tile * 0.25)))
        }
        return result
    }

    private struct Caption {
        let id: String
        let view: AnyView
    }

    /// 看板の 字と、フィールドの 町・ほらあな・駅の 下の 地名。
    private func captions(where visible: (Point) -> Bool) -> [Caption] {
        var result: [Caption] = []
        // 看板には 街の名前を書く。名所の看板には その名前。3文字は 板に収まるよう 小さくする。
        if let town = map.id.townInfo {
            for (y, row) in map.tiles.enumerated() where visible(Point(x: max(0, centerColumn), y: y)) {
                for (x, kind) in row.enumerated() where kind == .signpost && visible(Point(x: x, y: y)) {
                    let point = Point(x: x, y: y)
                    let board = rect(for: point)
                    let title = map.plaques[point]?.title ?? town.name
                    let size = tile * (title.count > 2 ? 0.25 : 0.34)
                    let text = Text(title).font(Retro.font(size)).foregroundColor(.black)
                        .fixedSize()
                        .frame(width: board.width * 2, height: tile * 0.5)
                        .offset(x: board.midX - board.width, y: board.minY + board.height * 5.5 / 16 - tile * 0.25)
                    result.append(Caption(id: "sign-\(x)-\(y)", view: AnyView(text)))
                }
            }
        }
        // フィールドでは 街と ほらあなの下に 地名を出す。どこが どの街か 地図だけで分かるように。
        var labels: [(Point, String)] = map.warps.compactMap { point, warp in
            guard Self.landmark(map.tile(at: point)) != nil, let name = warp.to.placeName else { return nil }
            return (point, name)
        }
        // 駅には 駅の 名前（新青森駅 など）。
        if let station = map.station, let region = map.region, let name = region.stationName {
            labels.append((station, name))
        }
        for (point, name) in labels where visible(point) {
            let below = rect(for: point)
            let label = Text(name).font(Retro.font(tile * 0.36)).foregroundColor(.white)
                .fixedSize()
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 3))
                .frame(width: tile * 5)
                .offset(x: below.midX - tile * 2.5, y: below.maxY + 2)
            result.append(Caption(id: "label-\(point.x)-\(point.y)", view: AnyView(label)))
        }
        return result
    }

    /// 行を しぼる ときに 使う 列（勇者の いる 列。地図の 外なら 0）。
    private var centerColumn: Int { min(max(center.x, 0), map.width - 1) }

    private func rect(for point: Point) -> CGRect {
        CGRect(x: CGFloat(point.x + Self.padding) * tile, y: CGFloat(point.y + Self.padding) * tile, width: tile, height: tile)
    }
}

/// 地面の 8×8 マスの 板。絵は `ChunkCache` に 焼いてあるので、歩いても 描きなおさない。
struct MapChunk: View, Equatable {
    let map: GameMap
    let chunk: Point
    let tile: CGFloat

    static func == (lhs: MapChunk, rhs: MapChunk) -> Bool {
        lhs.map.id == rhs.map.id && lhs.chunk == rhs.chunk && lhs.tile == rhs.tile
    }

    var body: some View {
        let size = MapLayer.chunkSize
        // 焼いておいた 絵を ぼかさずに 拡大して 出す（Canvas だと 歩くたびに 描きなおされた）。
        Image(decorative: ChunkCache.image(map: map, chunk: chunk, size: size), scale: 1)
            .resizable()
            .interpolation(.none)
        .frame(width: CGFloat(size) * tile, height: CGFloat(size) * tile)
    }
}

/// 十字キーの どこを 押しているかを 向きに直す。
enum DPadInput {
    /// 真ん中の これより内側は 向きを決めない。
    static let deadZone: CGFloat = 14
    /// いまの向きと ちがう軸へ 変わるのは、そちらへ これだけ はっきり ずれたときだけ。
    static let turnRatio: CGFloat = 1.4

    /// 指が ななめに ずれても 向きが ぱたぱた変わらず、真ん中に ずれても 歩きやまないようにする。
    static func direction(dx: CGFloat, dy: CGFloat, current: Direction?) -> Direction? {
        guard dx * dx + dy * dy > deadZone * deadZone else { return current }
        var horizontal = abs(dx) > abs(dy)
        if let current {
            let wasHorizontal = current.delta.x != 0
            let along = wasHorizontal ? abs(dx) : abs(dy)
            let across = wasHorizontal ? abs(dy) : abs(dx)
            horizontal = across > along * turnRatio ? !wasHorizontal : wasHorizontal
        }
        if horizontal { return dx > 0 ? .right : .left }
        return dy > 0 ? .down : .up
    }
}

/// A/B ボタン。指が ふれた瞬間に 効かせる（離したときに 効くと 反応が おそく感じる）。
private struct PadButton: View {
    let label: String
    let tint: Color
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Text(label)
            .font(Retro.font(24))
            .foregroundStyle(.white)
            .frame(width: 70, height: 70)
            .background(Circle().fill(tint))
            .brightness(isPressed ? 0.15 : 0)
            .scaleEffect(isPressed ? 0.92 : 1)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else { return }
                        isPressed = true
                        action()
                    }
                    .onEnded { _ in isPressed = false }
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { action() }
    }
}

/// 十字キー（指を滑らせて向きを変えられる）と A/B ボタン。押している間は歩き続ける。
struct ControlPad: View {
    @Environment(GameState.self) private var game

    private let padSize: CGFloat = 156
    /// 十字キーの 絵より 外でも 押せる はば。
    private let padSlop: CGFloat = 12

    var body: some View {
        HStack {
            dPad
            Spacer()
            HStack(alignment: .bottom, spacing: 18) {
                PadButton(label: "B", tint: .blue.opacity(0.7)) { game.pressB() }
                    .padding(.top, 40)
                PadButton(label: "A", tint: .red.opacity(0.8)) { game.pressA() }
                    .padding(.bottom, 40)
            }
        }
        .onDisappear { game.hold(nil) }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.13))
    }

    private var dPad: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.25))
                .frame(width: padSize / 3, height: padSize)
            RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.25))
                .frame(width: padSize, height: padSize / 3)
            ForEach(Direction.allCases, id: \.self) { direction in
                Image(systemName: arrow(direction))
                    .font(.title2.bold())
                    .foregroundStyle(game.heldDirection == direction ? .yellow : .white)
                    .offset(x: CGFloat(direction.delta.x) * padSize / 3, y: CGFloat(direction.delta.y) * padSize / 3)
            }
        }
        .frame(width: padSize, height: padSize)
        .padding(padSlop)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let center = padSize / 2 + padSlop
                    game.hold(DPadInput.direction(
                        dx: value.location.x - center,
                        dy: value.location.y - center,
                        current: game.heldDirection
                    ))
                }
                .onEnded { _ in
                    game.hold(nil)
                }
        )
        .padding(-padSlop)
    }

    private func arrow(_ direction: Direction) -> String {
        switch direction {
        case .up: "arrowtriangle.up.fill"
        case .down: "arrowtriangle.down.fill"
        case .left: "arrowtriangle.left.fill"
        case .right: "arrowtriangle.right.fill"
        }
    }
}
