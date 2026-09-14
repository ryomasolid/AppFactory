import SwiftData
import SwiftUI

/// 初回起動時の導入。
///
/// 役目は**「クルマと現在の走行距離を入れてもらう」**（全ての計算の起点）ことと、
/// **「メンテ通知を許可してもらう」**ことの2つに絞る。車種や初度登録はあとから。
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store
    @AppStorage(StorageKey.selectedVehicleID) private var selectedID = ""
    @AppStorage(StorageKey.notifyHour) private var notifyHour = 9
    @AppStorage(StorageKey.notifyMinute) private var notifyMinute = 0

    let onDone: () -> Void

    @State private var step: Step = OnboardingView.initialStep
    @State private var name = ""
    @State private var fuelType: FuelType = .regular
    @State private var odometerText = ""
    @State private var selection: Set<String> = Set(
        MaintenanceTemplate.all.filter(\.isRecommended).map(\.id)
    )
    @State private var notificationDenied = false
    @FocusState private var focused: Bool

    private enum Step: String {
        case intro
        case vehicle
        case odometer
        case templates
        case notifications
    }

    /// スクショ撮影用に、起動引数で開始ページを指定できるようにする。
    private static var initialStep: Step {
        Launch.onboardingStep.flatMap(Step.init(rawValue:)) ?? .intro
    }

    var body: some View {
        VStack(spacing: 0) {
            switch step {
            case .intro: intro
            case .vehicle: vehicle
            case .odometer: odometer
            case .templates: templates
            case .notifications: notifications
            }
        }
        .padding(28)
        .tint(Theme.accent)
        .animation(.default, value: step)
    }

    // MARK: - 1. 説明

    private var intro: some View {
        VStack(spacing: 28) {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: "car.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.accent)
                Text("カーログ")
                    .font(.largeTitle.bold())
                Text("給油を入れるだけで、燃費も維持費も次の点検も。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 22) {
                feature("fuelpump.fill", "入力は4つだけ", "日付・走行距離・給油量・金額。燃費と1kmあたりのコストは自動で出ます。")
                feature("bell.badge.fill", "メンテ時期をお知らせ", "オイル交換は「6か月または5,000km」の早いほうで。車検や自動車税も。")
                feature("lock.fill", "すべて端末内に保存", "アカウント登録も位置情報も不要。記録が外部に送信されることはありません。")
            }

            Spacer()
            primaryButton("はじめる") { step = .vehicle }
        }
    }

    // MARK: - 2. クルマ

    private var vehicle: some View {
        VStack(alignment: .leading, spacing: 24) {
            header("クルマを登録", "名前と燃料だけで始められます。車種などはあとから設定で追加できます。")

            VStack(alignment: .leading, spacing: 8) {
                Text("名前").font(.subheadline.weight(.semibold))
                TextField("例：プリウス、通勤用", text: $name)
                    .font(.title3)
                    .padding(14)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    .focused($focused)
                    .submitLabel(.next)
                    .onSubmit { step = .odometer }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("燃料").font(.subheadline.weight(.semibold))
                Picker("燃料", selection: $fuelType) {
                    ForEach(FuelType.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Spacer()
            primaryButton("次へ") {
                focused = false
                step = .odometer
            }
        }
        .onAppear { if !Launch.isDemo { focused = true } }
    }

    // MARK: - 3. 走行距離

    private var odometer: some View {
        VStack(alignment: .leading, spacing: 24) {
            header("いまの走行距離は？", "メーターの総走行距離（ODO）を入れてください。燃費とメンテ時期を計算する起点になります。")

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                TextField("0", text: $odometerText)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .keyboardType(.numberPad)
                    .monospacedDigit()
                    .focused($focused)
                Text("km")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))

            Spacer()
            VStack(spacing: 10) {
                primaryButton("次へ") {
                    focused = false
                    step = .templates
                }
                Button("あとで入力する") {
                    odometerText = ""
                    focused = false
                    step = .templates
                }
                .font(.subheadline)
            }
        }
        .onAppear { if !Launch.isDemo { focused = true } }
    }

    // MARK: - 4. テンプレート

    private var templates: some View {
        VStack(alignment: .leading, spacing: 20) {
            header("知らせてほしいメンテは？", "前回の実施日はあとで「メンテ」タブから入れると、予定がより正確になります。")

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(MaintenanceTemplate.all) { template in
                        templateRow(template)
                    }
                }
            }

            if !canSelectMore {
                Text("無料版で登録できるのは\(ProLimits.freeMaintenanceItems)件までです。あとから Pro で無制限にできます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            primaryButton(selection.isEmpty ? "スキップ" : "これで始める") {
                createVehicle()
                step = .notifications
            }
        }
    }

    private func templateRow(_ template: MaintenanceTemplate) -> some View {
        let isSelected = selection.contains(template.id)
        // 無料枠を超える選択は、初回から課金の壁に当てないために「増やせない」で止める。
        let isDisabled = !isSelected && !canSelectMore
        return Button {
            if isSelected { selection.remove(template.id) } else { selection.insert(template.id) }
        } label: {
            HStack(spacing: 12) {
                IconTile(symbolName: template.symbolName, color: Theme.accent, size: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.title).foregroundStyle(.primary)
                    Text(Formatting.interval(months: template.intervalMonths, distance: template.intervalDistance))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.accent : Color.secondary)
            }
            .padding(14)
            .background(
                Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .opacity(isDisabled ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var canSelectMore: Bool {
        ProLimits.canAddMaintenanceItem(currentCount: selection.count, isPro: store.isPro)
    }

    // MARK: - 5. 通知の許可

    private var notifications: some View {
        VStack(spacing: 28) {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accent)
                Text("メンテの時期を通知でお知らせ")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text("車検やオイル交換は年に1〜2回。覚えておくのではなく、時期が来たらアプリが知らせます。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            notificationSample(
                String(localized: "オイル交換"),
                String(localized: "9/25ごろが次回の目安です。（6か月 または 5,000 km ごと）")
            )

            if notificationDenied {
                Text("通知がオフになっています。設定アプリ →「カーログ」→「通知」で許可してください。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
            VStack(spacing: 10) {
                // 「許可」などシステムのダイアログを模した文言は審査で指摘されるため使わない。
                primaryButton("通知をオンにする") {
                    Task { await enableNotifications() }
                }
                Button("あとで設定する") { finish() }
                    .font(.subheadline)
            }
        }
    }

    private func notificationSample(_ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "car.fill")
                .font(.caption)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(text).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    // MARK: - 共通

    private func header(_ title: LocalizedStringKey, _ subtitle: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.title2.bold())
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.top, 20)
    }

    private func primaryButton(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
        }
    }

    private func feature(_ icon: String, _ title: LocalizedStringKey, _ subtitle: LocalizedStringKey) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(Theme.accent)
                .frame(width: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    /// クルマとメンテ項目を作る。スクショ撮影で途中のページから始めても二重に作らない。
    private func createVehicle() {
        let existing = (try? modelContext.fetchCount(FetchDescriptor<Vehicle>())) ?? 0
        guard existing == 0 else { return }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let vehicle = Vehicle(
            name: trimmed.isEmpty ? String(localized: "マイカー") : trimmed,
            fuelType: fuelType,
            purchaseOdometer: NumberInput.double(odometerText).map { max(0, $0) } ?? 0,
            isDefault: true
        )
        modelContext.insert(vehicle)

        let chosen = MaintenanceTemplate.all.filter { selection.contains($0.id) }
        for (index, template) in chosen.enumerated() {
            // 前回の実施は分からないので空のまま（起点はクルマの記録開始時の距離になる）。
            let item = template.makeItem(sortOrder: index, startDate: nil, startOdometer: nil)
            item.notifyHour = notifyHour
            item.notifyMinute = notifyMinute
            item.vehicle = vehicle
            modelContext.insert(item)
        }
        try? modelContext.save()
        selectedID = vehicle.id.uuidString
    }

    private func enableNotifications() async {
        let granted = await NotificationScheduler.shared.requestAuthorizationIfNeeded()
        notificationDenied = !granted
        // 拒否されても先へ進める。設定アプリからいつでも許可でき、起動時に組み直される。
        if granted { finish() }
    }

    private func finish() {
        createVehicle()
        let context = modelContext
        Task { await NotificationScheduler.shared.rebuild(context: context) }
        onDone()
    }
}
