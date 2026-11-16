import SwiftUI

/// 2羽以上いるとき、画面上で見る子を切りかえる。
struct BirdMenu: View {
    let birds: [Bird]
    @Binding var tag: String

    var body: some View {
        if birds.count > 1, let current = Picked.bird(in: birds, tag: tag) {
            Picker(selection: Binding(get: { current.tag.uuidString }, set: { tag = $0 })) {
                ForEach(birds) { Text($0.name).tag($0.tag.uuidString) }
            } label: {
                Text(current.name)
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("bird-menu")
        } else {
            Text(birds.first?.name ?? "").font(.headline)
        }
    }
}
