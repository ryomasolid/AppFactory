import Foundation
import SwiftData

/// おぼえた言葉・鳴きまね。
@Model
final class Word {
    var text: String = ""
    var heardOn: Date = Date()
    var memo: String = ""
    var bird: Bird?

    init(text: String, heardOn: Date, bird: Bird) {
        self.text = text
        self.heardOn = heardOn
        self.bird = bird
    }
}
