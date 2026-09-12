import SwiftUI

/// 選択状態を持つ丸いチップ。周期・曜日・第n の選択に使う。
///
/// 横に7つ（曜日）並べても画面幅を超えないよう、`expands` で等幅に分配できるようにしてある。
struct ChipButton: View {
    let title: String
    let isSelected: Bool
    var minWidth: CGFloat = 32
    var horizontalPadding: CGFloat = 12
    /// true なら利用可能な幅を等分する（固定幅で並べると狭い端末ではみ出すため）。
    var expands: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(minWidth: minWidth, maxWidth: expands ? .infinity : nil)
                .padding(.vertical, 9)
                .padding(.horizontal, horizontalPadding)
                .background(
                    isSelected ? Theme.accent : Color(.tertiarySystemFill),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// 曜日の複数選択。7つを等幅に並べる。
struct WeekdayChipRow: View {
    @Binding var selection: Set<Weekday>

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Weekday.allCases) { weekday in
                ChipButton(
                    title: weekday.shortLabel,
                    isSelected: selection.contains(weekday),
                    minWidth: 0,
                    horizontalPadding: 4,
                    expands: true
                ) {
                    toggle(weekday)
                }
                .accessibilityLabel(Text(weekday.shortLabel) + Text("曜日"))
            }
        }
    }

    private func toggle(_ weekday: Weekday) {
        if selection.contains(weekday) {
            selection.remove(weekday)
        } else {
            selection.insert(weekday)
        }
    }
}

/// 第n（第1〜第4・最終）の複数選択。
struct NthWeekChipRow: View {
    @Binding var selection: Set<NthWeek>

    var body: some View {
        HStack(spacing: 4) {
            ForEach(NthWeek.allCases) { nth in
                ChipButton(
                    title: nth.label,
                    isSelected: selection.contains(nth),
                    minWidth: 0,
                    horizontalPadding: 4,
                    expands: true
                ) {
                    if selection.contains(nth) {
                        selection.remove(nth)
                    } else {
                        selection.insert(nth)
                    }
                }
            }
        }
    }
}
