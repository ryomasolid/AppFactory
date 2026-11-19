import SwiftData
import SwiftUI

/// 何匹もいるとき、画面の上で切りかえる。
struct TurtleSwitcher: View {
    let turtles: [Turtle]
    @Binding var selectedKey: String

    var body: some View {
        if turtles.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(turtles) { t in
                        let on = Selection.pick(turtles, key: selectedKey)?.key == t.key
                        Button {
                            selectedKey = t.key.uuidString
                        } label: {
                            HStack(spacing: 6) {
                                TurtleAvatar(turtle: t, size: 26)
                                Text(t.name).font(.subheadline.weight(on ? .bold : .regular))
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(on ? Palette.moss.opacity(0.18) : Palette.paper, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("switch-\(t.name)")
                    }
                }
            }
        }
    }
}
