import SwiftUI

struct FieldView: View {
    @Environment(GameState.self) private var game

    /// 横に見えるマス数（奇数にして勇者を真ん中に置く）。
    static let columns = 11

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let tile = geo.size.width / CGFloat(Self.columns)
                let center = CGPoint(x: (geo.size.width - tile) / 2, y: (geo.size.height - tile) / 2)
                ZStack(alignment: .topLeading) {
                    MapLayer(
                        map: game.map,
                        openedChests: game.openedChests,
                        tile: tile,
                        center: game.position,
                        // 画面に入る範囲＋すこし余分だけ描く。
                        radius: Int((geo.size.height / tile / 2).rounded(.up)) + 2
                    )
                        .offset(
                            x: center.x - CGFloat(game.position.x + MapLayer.padding) * tile,
                            y: center.y - CGFloat(game.position.y + MapLayer.padding) * tile
                        )
                        .animation(game.lastMoveWasWarp ? nil : .linear(duration: 0.15), value: game.position)

                    SpriteCache.image(.hero(facing: game.facing, step: game.walkFrame))
                        .resizable()
                        .interpolation(.none)
                        .frame(width: tile, height: tile)
                        .offset(x: center.x, y: center.y)

                    HStack(alignment: .top) {
                        StatusPanel(hero: game.hero)
                        Spacer()
                        Text(game.map.name)
                            .font(Retro.font(13))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 4))
                    }
                    .padding(8)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                .clipped()
            }
            .overlay(alignment: .top) {
                FieldOverlay()
                    .padding(.top, 120)
            }
            .overlay(alignment: .bottom) {
                if let page = game.currentPage {
                    MessageBox(lines: page)
                        .onTapGesture { game.advanceMessage() }
                }
            }

            ControlPad()
        }
    }
}

/// マップ全体を1枚に描く。外周に `padding` マス分だけ「外側の地形」を足し、端でも黒い余白が見えないようにする。
struct MapLayer: View {
    static let padding = 7

    let map: GameMap
    let openedChests: Set<String>
    let tile: CGFloat
    /// 勇者のいるマス。この まわりだけ描く。
    let center: Point
    /// 中心から何マスぶん描くか。
    let radius: Int

    /// 大きく描く地形と、その絵・倍率。
    /// 絵は背景を透かした版を使う。不透明のままだと まわりのマス（海や道）を塗りつぶしてしまう。
    static func landmark(_ tile: Tile) -> (sprite: SpriteID, scale: CGFloat)? {
        switch tile {
        case .town: (.townLarge, 2.0)
        case .cave: (.caveLarge, 1.7)
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

    var body: some View {
        let pad = Self.padding
        Canvas { context, _ in
            // 地図が広いので、画面に入らないところは描かない。
            let yRange = max(-pad, center.y - radius)..<min(map.height + pad, center.y + radius + 1)
            let xRange = max(-pad, center.x - radius)..<min(map.width + pad, center.x + radius + 1)
            for y in yRange {
                for x in xRange {
                    let point = Point(x: x, y: y)
                    let rect = CGRect(x: CGFloat(x + pad) * tile, y: CGFloat(y + pad) * tile, width: tile, height: tile)
                    let kind = map.tile(at: point)
                    // 街と ほらあなは あとでまとめて大きく描くので、ここでは地面だけ敷く。
                    let ground = MapLayer.landmark(kind) == nil ? kind : .grass
                    context.draw(SpriteCache.image(SpriteID(tile: ground)), in: rect)
                }
            }
            // 街と ほらあなは 1マスより大きく描く。
            // ふつうのタイルを敷き終えたあとに描かないと、右や下のタイルに削られる。
            for y in yRange {
                for x in xRange {
                    let point = Point(x: x, y: y)
                    let kind = map.tile(at: point)
                    guard let mark = MapLayer.landmark(kind) else { continue }
                    let rect = CGRect(x: CGFloat(x + pad) * tile, y: CGFloat(y + pad) * tile, width: tile, height: tile)
                    context.draw(SpriteCache.image(mark.sprite), in: MapLayer.standing(rect, scale: mark.scale))
                }
            }
            for chest in map.chests {
                let sprite: SpriteID = openedChests.contains(chest.id) ? .chestOpen : .chestClosed
                context.draw(SpriteCache.image(sprite), in: rect(for: chest.position))
            }
            for npc in map.npcs {
                context.draw(SpriteCache.image(SpriteID(npc: npc.role)), in: rect(for: npc.position))
            }
            if let boss = map.boss {
                // そのマップのボスの絵で出す（どの ほらあなでも守護神が座っていた）。
                let sprite = map.bossKind.map(SpriteID.init(enemy:)) ?? .guardian
                context.draw(SpriteCache.image(sprite), in: rect(for: boss).insetBy(dx: -tile * 0.25, dy: -tile * 0.25))
            }
        }
        .frame(width: CGFloat(map.width + pad * 2) * tile, height: CGFloat(map.height + pad * 2) * tile)
    }

    private func rect(for point: Point) -> CGRect {
        CGRect(x: CGFloat(point.x + Self.padding) * tile, y: CGFloat(point.y + Self.padding) * tile, width: tile, height: tile)
    }
}

/// 十字キー（指を滑らせて向きを変えられる）と A/B ボタン。押している間は歩き続ける。
struct ControlPad: View {
    @Environment(GameState.self) private var game

    private let padSize: CGFloat = 156

    var body: some View {
        HStack {
            dPad
            Spacer()
            HStack(alignment: .bottom, spacing: 18) {
                roundButton("B") { game.pressB() }
                    .padding(.top, 40)
                roundButton("A") { game.pressA() }
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
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    game.hold(direction(at: value.location))
                }
                .onEnded { _ in
                    game.hold(nil)
                }
        )
    }

    private func roundButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Retro.font(24))
                .foregroundStyle(.white)
                .frame(width: 70, height: 70)
                .background(Circle().fill(label == "A" ? Color.red.opacity(0.8) : Color.blue.opacity(0.7)))
        }
        .buttonStyle(.plain)
    }

    private func direction(at location: CGPoint) -> Direction? {
        let dx = location.x - padSize / 2
        let dy = location.y - padSize / 2
        guard dx * dx + dy * dy > 14 * 14 else { return nil }
        if abs(dx) > abs(dy) { return dx > 0 ? .right : .left }
        return dy > 0 ? .down : .up
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
