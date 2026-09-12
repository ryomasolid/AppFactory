import Foundation
import Testing
@testable import GomiAlarm

/// 種類編集の下書き。
/// 「周期の無い種類」や「名前が空白だけの種類」を保存できてしまうと、
/// 登録した本人は設定したつもりなのに通知が来ない状態になるので、保存条件を固定する。
struct KindDraftTests {

    private let weekly = RuleSpec(frequency: .weekly, weekdays: [.monday])

    @Test func newDraftIsNotSavable() {
        // 空の下書きは保存できない（名前も周期も無い）。
        #expect(!KindDraft().isValid)
    }

    @Test func nameAloneIsNotEnough() {
        var draft = KindDraft()
        draft.name = "燃えるゴミ"
        #expect(!draft.isValid)
    }

    @Test func ruleAloneIsNotEnough() {
        var draft = KindDraft()
        draft.specs = [weekly]
        #expect(!draft.isValid)
    }

    @Test func nameAndRuleMakeItSavable() {
        var draft = KindDraft()
        draft.name = "燃えるゴミ"
        draft.specs = [weekly]
        #expect(draft.isValid)
    }

    @Test func whitespaceOnlyNameIsRejected() {
        var draft = KindDraft()
        draft.name = "   "
        draft.specs = [weekly]
        #expect(!draft.isValid)
        #expect(draft.trimmedName.isEmpty)
    }

    @Test func nameIsTrimmed() {
        var draft = KindDraft()
        draft.name = "  燃えるゴミ \n"
        #expect(draft.trimmedName == "燃えるゴミ")
    }

    @Test func incompleteRulesAreDroppedOnSave() {
        // 曜日を選ばずに閉じた作りかけのルールは保存しない。
        var draft = KindDraft()
        draft.name = "燃えるゴミ"
        draft.specs = [weekly, RuleSpec(frequency: .weekly), RuleSpec(frequency: .biweekly, weekdays: [.tuesday])]
        #expect(draft.validSpecs == [weekly])
        #expect(draft.isValid)
    }

    @Test func draftWithOnlyIncompleteRulesIsNotSavable() {
        var draft = KindDraft()
        draft.name = "燃えるゴミ"
        draft.specs = [RuleSpec(frequency: .weekly)]
        #expect(!draft.isValid)
    }

    @Test func defaultAppearanceComesFromThePalette() {
        let draft = KindDraft()
        #expect(KindPalette.colors.contains(draft.colorHex))
        #expect(KindPalette.symbols.contains(draft.symbolName))
        // パレットの色はすべて白文字が載る前提なので、解釈できる値であること。
        for hex in KindPalette.colors {
            #expect(Theme.rgb(fromHex: hex) != nil)
        }
    }

    @Test func notificationTimesDefaultToSettings() {
        // nil は「設定の既定に従う」の意味。既定値そのものを持たせない。
        let draft = KindDraft()
        #expect(draft.eveningTime == nil)
        #expect(draft.morningTime == nil)
    }

    @Test func timeOfDayRoundTripsThroughDate() {
        let time = TimeOfDay(hour: 6, minute: 30)
        let date = time.date(on: day(2026, 9, 1), calendar: jst)
        #expect(date != nil)
        #expect(TimeOfDay(date ?? Date(), calendar: jst) == time)
    }
}
