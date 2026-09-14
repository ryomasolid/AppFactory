import SwiftUI

/// `@AppStorage` のキー。タブをまたいで同じ値を読むので1か所にまとめる。
enum StorageKey {
    static let selectedVehicleID = "cl.selectedVehicleID"
    static let hasSeenOnboarding = "cl.hasSeenOnboarding"
    /// 新しく作るメンテ項目の通知時刻の既定値。
    static let notifyHour = "cl.notifyHour"
    static let notifyMinute = "cl.notifyMinute"
}

// MARK: - カード

extension View {
    /// 角丸の白いカード。一覧以外の画面はこの1種類で組む。
    func card(padding: CGFloat = 18, cornerRadius: CGFloat = 18) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
    }
}

struct SectionTitle: View {
    let title: LocalizedStringKey

    init(_ title: LocalizedStringKey) { self.title = title }

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }
}

/// 色付きの角丸にアイコンを白抜きで置く。カテゴリ・メンテ項目・クルマの見分けに使う。
struct IconTile: View {
    let symbolName: String
    let color: Color
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color, in: RoundedRectangle(cornerRadius: size * 0.26, style: .continuous))
            .accessibilityHidden(true)
    }
}

// MARK: - メンテの状態

extension DueState {
    var label: String {
        switch self {
        case .overdue: String(localized: "期限切れ")
        case .soon: String(localized: "もうすぐ")
        case .ok: String(localized: "余裕あり")
        }
    }

    var color: Color {
        switch self {
        case .overdue: Color(hex: "#D1495B")
        case .soon: Color(hex: "#E08A1B")
        case .ok: Theme.accent
        }
    }
}

struct DueBadge: View {
    let state: DueState

    var body: some View {
        Text(state.label)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .foregroundStyle(state.color)
            .background(state.color.opacity(0.14), in: Capsule())
    }
}

/// 次回予定の1行表示。
enum MaintenanceText {
    /// "9/25ごろ・あと 350 km" / "9/8・6日超過" / 予定が出せないときは入力を促す文。
    static func next(_ status: MaintenanceStatus) -> String {
        var parts: [String] = []
        if let date = status.effectiveDate {
            let text = date.formatted(.dateTime.month(.defaultDigits).day())
            // 距離からの予測日は目安なので「ごろ」を付ける。
            let isProjected = status.projectedDate == date && status.dueDate != date
            parts.append(isProjected ? String(localized: "\(text)ごろ") : text)
        }
        if let distance = status.remainingDistance {
            parts.append(
                distance >= 0
                    ? String(localized: "あと \(Formatting.kilometers(distance))")
                    : String(localized: "\(Formatting.kilometers(-distance)) 超過")
            )
        } else if let days = status.remainingDays {
            parts.append(days >= 0 ? String(localized: "あと\(days)日") : String(localized: "\(-days)日超過"))
        }
        guard !parts.isEmpty else { return String(localized: "前回の実施日を入れると予定が出ます") }
        return parts.joined(separator: "・")
    }
}

extension MaintenanceItem {
    /// 実施費用を「費用」にも記録するときのカテゴリ。テンプレのアイコンから推定する。
    var expenseCategory: ExpenseCategory {
        switch symbolName {
        case "checkmark.seal.fill": .inspection
        case "yensign.circle.fill": .tax
        case "shield.lefthalf.filled": .insurance
        default: .maintenance
        }
    }
}

// MARK: - クルマの切り替え

extension View {
    /// ナビゲーションバー右上にクルマの切り替えメニューを置く。
    /// 2台目の追加は Pro なので、上限に達していればペイウォールを出す。
    func vehicleSwitcher(_ vehicles: [Vehicle], selectedID: Binding<String>) -> some View {
        modifier(VehicleSwitcher(vehicles: vehicles, selectedID: selectedID))
    }
}

private struct VehicleSwitcher: ViewModifier {
    let vehicles: [Vehicle]
    @Binding var selectedID: String

    @Environment(StoreManager.self) private var store
    @State private var showEditor = false
    @State private var showPaywall = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                if let current = Vehicle.resolve(vehicles, selectedID: selectedID) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker("クルマ", selection: resolvedSelection) {
                                ForEach(vehicles, id: \.id) { vehicle in
                                    Label(vehicle.name, systemImage: vehicle.symbolName)
                                        .tag(vehicle.id.uuidString)
                                }
                            }
                            Divider()
                            Button {
                                if ProLimits.canAddVehicle(currentCount: vehicles.count, isPro: store.isPro) {
                                    showEditor = true
                                } else {
                                    showPaywall = true
                                }
                            } label: {
                                Label("クルマを追加", systemImage: "plus")
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: current.symbolName)
                                    .foregroundStyle(Color(hex: current.colorHex))
                                Image(systemName: "chevron.down")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityLabel(Text("クルマを切り替え"))
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                VehicleEditorView(vehicle: nil) { created in
                    selectedID = created.id.uuidString
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView().environment(store)
            }
    }

    private var resolvedSelection: Binding<String> {
        Binding(
            get: { Vehicle.resolve(vehicles, selectedID: selectedID)?.id.uuidString ?? "" },
            set: { selectedID = $0 }
        )
    }
}

/// クルマが1台も無いときの案内（オンボーディングを飛ばした・全部削除した場合）。
struct NoVehicleView: View {
    @State private var showEditor = false
    @AppStorage(StorageKey.selectedVehicleID) private var selectedID = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("クルマを登録しましょう")
                .font(.title3.weight(.semibold))
            Text("名前と燃料の種類だけで始められます。車種や初度登録年月はあとから追加できます。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                showEditor = true
            } label: {
                Label("クルマを登録", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .card()
        .padding(16)
        .sheet(isPresented: $showEditor) {
            VehicleEditorView(vehicle: nil) { selectedID = $0.id.uuidString }
        }
    }
}

/// 大きな主ボタン。
struct PrimaryButtonLabel: View {
    let title: String
    var systemImage: String?

    var body: some View {
        Group {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .foregroundStyle(.white)
    }
}
