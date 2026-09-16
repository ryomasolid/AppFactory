import SwiftUI

@main
struct GeoHeroApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var game = GameState()
    @State private var audio = AudioManager()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            switch game.screen {
            case .title: TitleView()
            case .naming: NameEntryView()
            case .field: FieldView()
            case .battle: BattleView()
            case .ending: EndingView()
            }

            // 場面の切り替えと 宿屋の ねむり。濃さは GameState、動きはここ。
            Curtain(opacity: game.curtain, caption: game.curtainCaption)
                .animation(.easeInOut(duration: game.fadeSeconds), value: game.curtain)
        }
        .environment(game)
        .onAppear {
            game.playSound = { [audio] cue in audio.play(cue) }
        }
        .onChange(of: game.soundEnabled, initial: true) { _, enabled in
            audio.isEnabled = enabled
        }
        .onChange(of: game.musicTrack, initial: true) { _, track in
            audio.playMusic(track)
        }
        .task { Launch.apply(to: game) }
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }
}

/// 画面をおおう黒い幕。出入りのときや 宿屋で眠るときに下ろす。
struct Curtain: View {
    let opacity: Double
    let caption: String?

    var body: some View {
        ZStack {
            Color.black
            if let caption {
                Text(caption)
                    .font(Retro.font(20))
                    .foregroundStyle(Retro.ink)
            }
        }
        .opacity(opacity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - 共通部品

enum Retro {
    static func font(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }

    // 画面じゅうで使う色。ばらばらに書かず、ここから引く。
    static let ink = Color.white
    static let dim = Color(white: 0.62)
    static let accent = Color(red: 0.98, green: 0.85, blue: 0.28)
    static let hp = Color(red: 0.36, green: 0.85, blue: 0.40)
    static let hpLow = Color(red: 0.95, green: 0.42, blue: 0.30)
    static let heal = Color(red: 0.45, green: 1.00, blue: 0.50)
    /// あがったあとの数値。目立たせる青。
    static let fresh = Color(red: 0.45, green: 0.78, blue: 1.00)
    static let ember = Color(red: 1.00, green: 0.55, blue: 0.15)
    /// 戦闘の空と地面。ボス戦は暗いほうを使う。
    static let sky = Color(red: 0.30, green: 0.55, blue: 0.85)
    static let ground = Color(red: 0.85, green: 0.91, blue: 0.97)
    static let bossSky = Color(red: 0.08, green: 0.05, blue: 0.16)
    static let bossGround = Color(red: 0.16, green: 0.16, blue: 0.26)
}

/// HP などの棒グラフ。残りが 1/4 を切ると色が変わる。
struct RetroBar: View {
    let value: Int
    let maximum: Int
    var tint: Color = Retro.hp
    var width: CGFloat = 92
    var height: CGFloat = 8

    private var ratio: Double {
        guard maximum > 0 else { return 0 }
        return min(1, max(0, Double(value) / Double(maximum)))
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle().fill(Color(white: 0.22))
            Rectangle()
                .fill(ratio <= 0.25 ? Retro.hpLow : tint)
                .frame(width: width * ratio)
        }
        .frame(width: width, height: height)
        .overlay(Rectangle().strokeBorder(Retro.ink.opacity(0.7), lineWidth: 1))
        .animation(.easeOut(duration: 0.25), value: value)
    }
}

/// 夜空と山なみ。タイトルの背景に使う。
struct NightSkyBackdrop: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.03, green: 0.04, blue: 0.13), Color(red: 0.12, green: 0.16, blue: 0.36)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Canvas { context, size in
                    // 星の位置は固定にして、毎回同じ空にする。
                    var seed = SeededRandomSource(seed: 20_260_916)
                    for _ in 0..<70 {
                        let x = CGFloat(seed.next(in: 0...max(1, Int(size.width))))
                        let y = CGFloat(seed.next(in: 0...max(1, Int(size.height * 0.62))))
                        let dot = CGFloat(seed.next(in: 1...2))
                        context.fill(
                            Path(CGRect(x: x, y: y, width: dot, height: dot)),
                            with: .color(.white.opacity(0.5 + Double(seed.next(in: 0...4)) / 10))
                        )
                    }
                }
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height * 0.74))
                    path.addLine(to: CGPoint(x: width * 0.22, y: height * 0.58))
                    path.addLine(to: CGPoint(x: width * 0.40, y: height * 0.70))
                    path.addLine(to: CGPoint(x: width * 0.62, y: height * 0.52))
                    path.addLine(to: CGPoint(x: width * 0.82, y: height * 0.68))
                    path.addLine(to: CGPoint(x: width, y: height * 0.60))
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(Color(red: 0.06, green: 0.09, blue: 0.20))
            }
        }
        .ignoresSafeArea()
    }
}

/// 黒地に白枠のウィンドウ。
struct RetroWindow<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .font(Retro.font())
        .foregroundStyle(.white)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        // 後ろのマップが透けると文字に模様が重なって読みにくいので、塗りつぶす。
        .background(Color.black, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white, lineWidth: 3))
        .padding(6)
    }
}

/// ウィンドウ内の選択肢。
struct RetroChoice: View {
    @Environment(GameState.self) private var game
    let title: String
    var detail: String?
    /// detail だけ色を変えたいとき（買えない値段を赤くするなど）。
    var detailStyle: Color?
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button {
            game.playSound(.cursor)
            action()
        } label: {
            HStack {
                Text(title)
                Spacer()
                if let detail {
                    if let detailStyle {
                        Text(detail).foregroundStyle(detailStyle)
                    } else {
                        Text(detail)
                    }
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(RetroChoiceStyle())
        .foregroundStyle(isEnabled ? .white : .gray)
        .disabled(!isEnabled)
    }
}

/// ウィンドウ内の「項目名 … 値」の行。選択肢と頭がそろうよう、▶ の幅を空けておく。
struct RetroRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Text("▶").hidden()
            Text(label)
            Spacer()
            Text(value)
        }
    }
}

/// 押している間だけ左に ▶ を出す。
/// ▶ は「いま選んでいる1つ」を指す印なので、全部の選択肢に並べると意味がなくなる。
/// 印の分の幅は常に空けておき、押したときに文字がずれないようにする。
private struct RetroChoiceStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            Text("▶")
                .opacity(configuration.isPressed ? 1 : 0)
            configuration.label
        }
    }
}

struct StatusPanel: View {
    let hero: Hero

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(hero.name)
            Text("LV \(hero.level)")
            Text("HP \(hero.hp)").foregroundStyle(hero.hp * 4 <= hero.maxHP ? .orange : .white)
            Text("MP \(hero.mp)")
            Text("G  \(hero.gold)")
        }
        .font(Retro.font(14))
        .foregroundStyle(.white)
        .padding(10)
        .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white, lineWidth: 2))
    }
}

struct MessageBox: View {
    let lines: [String]
    var showsCursor = true

    var body: some View {
        RetroWindow {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line).fixedSize()
            }
            if showsCursor {
                HStack {
                    Spacer()
                    Text("▼").font(Retro.font(12))
                }
            }
        }
        .frame(minHeight: 130, alignment: .top)
    }
}

private extension Text {
    func fixedSize() -> some View {
        fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - タイトル・エンディング

struct TitleView: View {
    @Environment(GameState.self) private var game

    var body: some View {
        ZStack {
            NightSkyBackdrop()
            content
        }
    }

    private var content: some View {
        VStack(spacing: 28) {
            Spacer()
            VStack(spacing: 6) {
                // 題は2行に分ける。1行にすると 小さい画面で はみ出すため。
                Text("地理の勇者")
                    .font(Retro.font(42))
                    .foregroundStyle(Retro.accent)
                    // ドット絵に合わせて、ぼかさない影で縁取る。
                    .shadow(color: .black, radius: 0, x: 3, y: 3)
                Text("R P G")
                    .font(Retro.font(20))
                    .tracking(4)
                    .foregroundStyle(Retro.accent)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)
                Text("〜 北海道 守護神 かいほう編 〜")
                    .font(Retro.font(13))
                    .foregroundStyle(Retro.dim)
                    .padding(.top, 6)
            }
            HStack(spacing: 40) {
                SpriteCache.image(.hero1).resizable().interpolation(.none).frame(width: 96, height: 96)
                SpriteCache.image(.guardian).resizable().interpolation(.none).frame(width: 120, height: 120)
            }
            Spacer()
            VStack(spacing: 12) {
                if game.hasSave {
                    RetroChoice(title: "つづきから") { game.continueGame() }
                }
                RetroChoice(title: "はじめから") { game.beginNaming() }
            }
            .font(Retro.font(22))
            .foregroundStyle(Retro.ink)
            .frame(width: 220)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Retro.ink, lineWidth: 3))
            Spacer()
        }
        .padding()
    }
}

/// 勇者の名前を決める画面。
struct NameEntryView: View {
    @Environment(GameState.self) private var game
    @State private var name = Hero.defaultName
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            NightSkyBackdrop()

            VStack(spacing: 24) {
                Spacer()

                SpriteCache.image(.hero1)
                    .resizable().interpolation(.none)
                    .frame(width: 96, height: 96)

                Text("ゆうしゃの なまえを きめてください")
                    .font(Retro.font(15))
                    .foregroundStyle(Retro.ink)

                RetroWindow {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("", text: $name)
                            .font(Retro.font(24))
                            .foregroundStyle(Retro.accent)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.center)
                            .focused($isFocused)
                            .submitLabel(.done)
                            .onSubmit(decide)
                            .padding(.vertical, 4)
                            .overlay(alignment: .bottom) {
                                Rectangle().fill(Retro.ink).frame(height: 2)
                            }
                        Text("\(Hero.maxNameLength)文字まで。あとから かえられません。")
                            .font(Retro.font(11))
                            .foregroundStyle(Retro.dim)
                    }
                }
                .frame(maxWidth: 300)

                RetroWindow {
                    RetroChoice(title: "けってい", action: decide)
                }
                .frame(width: 180)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear { isFocused = true }
        .onChange(of: name) { _, value in
            if value.count > Hero.maxNameLength { name = String(value.prefix(Hero.maxNameLength)) }
        }
    }

    private func decide() {
        isFocused = false
        game.newGame(name: name)
    }
}

struct EndingView: View {
    @Environment(GameState.self) private var game

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            SpriteCache.image(.hero1).resizable().interpolation(.none).frame(width: 120, height: 120)
            RetroWindow {
                Text("知床の守護神は 正気を とりもどした！")
                Text("守護神「よくぞ 解きはなってくれた。")
                Text("　まおうは まだ 4つの地方を あやつっている。")
                Text("　つぎの地方へ いそぐのだ。」")
                Text("北海道に へいわが もどった。")
            }
            Text("つづく").font(Retro.font(34)).foregroundStyle(Retro.accent)
            Text("LV \(game.hero.level)  \(game.hero.gold)G").font(Retro.font(16)).foregroundStyle(.white)
            Spacer()
            RetroChoice(title: "タイトルへ") { game.backToTitle() }
                .frame(width: 200)
            Spacer()
        }
        .padding()
    }
}
