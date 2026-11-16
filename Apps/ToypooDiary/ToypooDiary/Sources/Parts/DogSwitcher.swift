import SwiftData
import SwiftUI

/// 画面上の「いまの子」。2頭以上いるときだけメニューになる。
struct DogSwitcher: View {
    let dogs: [Dog]
    @Binding var currentKey: String

    var body: some View {
        if dogs.count > 1 {
            Menu {
                ForEach(dogs) { dog in
                    Button { currentKey = dog.key.uuidString } label: {
                        if dog.key.uuidString == currentKey { Label(dog.name, systemImage: "checkmark") } else { Text(dog.name) }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(CurrentDog.pick(dogs, key: currentKey)?.name ?? "")
                    Image(systemName: "chevron.down").font(.caption2.weight(.bold))
                }
                .font(.headline)
                .foregroundStyle(Tone.cocoa)
            }
            .accessibilityIdentifier("dog-switcher")
        }
    }
}
