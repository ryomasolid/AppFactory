import SwiftUI

@main
struct TinyHeroApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var game = GameState()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            switch game.screen {
            case .title: TitleView()
            case .field: FieldView()
            case .battle: BattleView()
            case .ending: EndingView()
            }
        }
        .environment(game)
        .task { Launch.apply(to: game) }
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }
}

// MARK: - 共通部品

enum Retro {
    static func font(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
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
        .background(Color.black.opacity(0.92), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white, lineWidth: 3))
        .padding(6)
    }
}

/// ウィンドウ内の選択肢。
struct RetroChoice: View {
    let title: String
    var detail: String?
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text("▶ \(title)")
                Spacer()
                if let detail { Text(detail) }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isEnabled ? .white : .gray)
        .disabled(!isEnabled)
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
        VStack(spacing: 28) {
            Spacer()
            Text("ちいさな勇者")
                .font(Retro.font(40))
                .foregroundStyle(.yellow)
            HStack(spacing: 40) {
                SpriteCache.image(.hero1).resizable().interpolation(.none).frame(width: 96, height: 96)
                SpriteCache.image(.darkDragon).resizable().interpolation(.none).frame(width: 120, height: 120)
            }
            Spacer()
            VStack(spacing: 12) {
                if game.hasSave {
                    RetroChoice(title: "つづきから") { game.continueGame() }
                }
                RetroChoice(title: "はじめから") { game.newGame() }
            }
            .font(Retro.font(22))
            .foregroundStyle(.white)
            .frame(width: 220)
            Spacer()
        }
        .padding()
    }
}

struct EndingView: View {
    @Environment(GameState.self) private var game

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            SpriteCache.image(.hero1).resizable().interpolation(.none).frame(width: 120, height: 120)
            RetroWindow {
                Text("ヤミドラゴンを たおした！")
                Text("村に へいわが もどった。")
                Text("ちいさな勇者の なは")
                Text("いつまでも かたりつがれるだろう。")
            }
            Text("THE END").font(Retro.font(34)).foregroundStyle(.yellow)
            Text("LV \(game.hero.level)  \(game.hero.gold)G").font(Retro.font(16)).foregroundStyle(.white)
            Spacer()
            RetroChoice(title: "タイトルへ") { game.backToTitle() }
                .frame(width: 200)
            Spacer()
        }
        .padding()
    }
}
