import SwiftUI

/// 収集の周期エディタ。
///
/// 設計上の合格ラインは **「第2・第4水曜」が2タップで作れること**。
/// 周期の種類→第n→曜日と3段階で選ばせると離脱するので、実際に使われる周期
/// （毎週／隔週／第1・第3／第2・第4）をプリセットとして最初に並べ、
/// 残り（毎月◯日・単発・第n の自由な組み合わせ）は「詳細」に押し込んでいる。
///
/// もうひとつの要は **その場で出す「次の収集日」プレビュー**。
/// ゴミ出しは間違えても1週間後まで気づけないので、保存前に確認できることが安心につながる。
struct RuleEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (RuleSpec) -> Void
    let onDelete: (() -> Void)?

    @State private var preset: RulePreset
    @State private var weekdays: Set<Weekday>
    @State private var nthWeeks: Set<NthWeek>
    @State private var dayOfMonth: Int
    @State private var anchorDate: Date
    @State private var customFrequency: RuleFrequency

    /// - Parameter spec: 編集するルール。新規作成なら nil。
    init(spec: RuleSpec?, onSave: @escaping (RuleSpec) -> Void, onDelete: (() -> Void)? = nil) {
        self.onSave = onSave
        self.onDelete = onDelete

        let today = Calendar.current.startOfDay(for: Date())
        let spec = spec ?? RuleSpec(frequency: .weekly)
        _preset = State(initialValue: RulePreset.preset(for: spec))
        _weekdays = State(initialValue: spec.weekdays)
        _nthWeeks = State(initialValue: spec.nthWeeks.isEmpty ? [.second, .fourth] : spec.nthWeeks)
        _dayOfMonth = State(initialValue: spec.dayOfMonth ?? 15)
        _anchorDate = State(initialValue: spec.anchorDate ?? today)
        _customFrequency = State(initialValue: spec.frequency)
    }

    var body: some View {
        NavigationStack {
            Form {
                presetSection
                if preset == .custom { customSection }
                if preset.usesWeekdayChips { weekdaySection }
                if preset == .biweekly { biweeklySection }
                previewSection
                if let onDelete { deleteSection(onDelete) }
            }
            .navigationTitle("収集の周期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(currentSpec)
                        dismiss()
                    }
                    .disabled(!currentSpec.isValid)
                }
            }
        }
    }

    // MARK: - セクション

    private var presetSection: some View {
        Section {
            // 横スクロールにすると5つ目が見切れて「壊れている」ように見えるので、
            // 幅が足りなければ折り返すグリッドにする（文字を縮めず、隠れる項目も作らない）。
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 86), spacing: 6)],
                alignment: .leading,
                spacing: 6
            ) {
                ForEach(RulePreset.allCases) { item in
                    ChipButton(title: item.label, isSelected: preset == item, expands: true) {
                        select(item)
                    }
                }
            }
            .padding(.vertical, 2)
        } header: {
            Text("周期")
        }
    }

    private var customSection: some View {
        Section("詳細") {
            Picker("周期の種類", selection: $customFrequency) {
                ForEach(RuleFrequency.allCases) { frequency in
                    Text(frequency.label).tag(frequency)
                }
            }

            switch customFrequency {
            case .weekly:
                WeekdayChipRow(selection: $weekdays)
            case .biweekly:
                WeekdayChipRow(selection: $weekdays)
                DatePicker("基準の週", selection: $anchorDate, displayedComponents: .date)
            case .nthWeekday:
                NthWeekChipRow(selection: $nthWeeks)
                WeekdayChipRow(selection: $weekdays)
            case .monthlyDay:
                Picker("日にち", selection: $dayOfMonth) {
                    ForEach(1...31, id: \.self) { day in
                        Text("\(day)日").tag(day)
                    }
                }
                // 31日など、その月に無い日は月末に寄せる仕様を明示しておく。
                Text("その月に無い日は月末に繰り上げます")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .once:
                DatePicker("収集日", selection: $anchorDate, displayedComponents: .date)
            }
        }
    }

    private var weekdaySection: some View {
        Section("曜日") {
            WeekdayChipRow(selection: $weekdays)
        }
    }

    private var biweeklySection: some View {
        Section {
            DatePicker("次の収集日", selection: $anchorDate, displayedComponents: .date)
        } header: {
            Text("次の収集日")
        } footer: {
            // 隔週は「どの週か」が決まらないと計算できない。曜日を別に選ばせるより、
            // 次の1回を指定してもらう方が迷いがない。
            Text("この日を基準に、2週間ごとの同じ曜日を収集日にします")
        }
    }

    private var previewSection: some View {
        Section {
            if previewDates.isEmpty {
                Text(currentSpec.isValid ? "この条件に合う日がありません" : "曜日などを選んでください")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(previewDates, id: \.self) { date in
                    Text(date.formatted(.dateTime.month().day().weekday()))
                        .monospacedDigit()
                }
            }
        } header: {
            Text("次の収集日")
        } footer: {
            if currentSpec.isValid {
                Text(currentSpec.summary)
            }
        }
    }

    private func deleteSection(_ delete: @escaping () -> Void) -> some View {
        Section {
            Button("このルールを削除", role: .destructive) {
                delete()
                dismiss()
            }
        }
    }

    // MARK: - 状態

    /// いま編集中の内容から組み上げたルール。
    private var currentSpec: RuleSpec {
        if preset == .custom {
            return RuleSpec(
                frequency: customFrequency,
                weekdays: weekdays,
                nthWeeks: nthWeeks,
                dayOfMonth: dayOfMonth,
                anchorDate: anchorDate
            )
        }
        return preset.spec(weekdays: weekdays, anchorDate: anchorDate)
            ?? RuleSpec(frequency: .weekly, weekdays: weekdays)
    }

    /// 保存前の確認用に、今日から先の収集日を3つ出す。
    private var previewDates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard currentSpec.isValid,
              let end = calendar.date(byAdding: .day, value: 120, to: today)
        else { return [] }
        let dates = ScheduleCalculator.occurrences(
            of: currentSpec, from: today, through: end, calendar: calendar
        )
        return Array(dates.prefix(3))
    }

    private func select(_ item: RulePreset) {
        preset = item
        // プリセットを選び直したら、そのプリセットが使う「第n」に揃える。
        if !item.nthWeeks.isEmpty { nthWeeks = item.nthWeeks }
        if item == .custom, customFrequency == .weekly, !nthWeeks.isEmpty {
            // 「第1・第3」などから詳細に来たときは、その設定を引き継ぐ。
            customFrequency = .nthWeekday
        }
    }
}

#Preview("新規") {
    RuleEditorView(spec: nil) { _ in }
}

#Preview("第2・第4 水曜") {
    RuleEditorView(
        spec: RuleSpec(frequency: .nthWeekday, weekdays: [.wednesday], nthWeeks: [.second, .fourth]),
        onSave: { _ in },
        onDelete: {}
    )
}
