import StoreKit
import SwiftData
import SwiftUI

struct CalculatorView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview

    @State private var input = TeikiInput()
    @State private var editingTrip: ExtraTrip?
    @State private var showPaywall = false
    @State private var showSaveDialog = false
    @State private var saveName = ""
    @FocusState private var focused: Field?

    private enum Field { case fare, pass }

    private var result: TeikiCalculator.Result { TeikiCalculator.calculate(input) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    inputCard

                    if input.isCalculable {
                        ResultCardView(input: input, result: result)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        emptyHint
                    }

                    extraTripsCard
                }
                .padding(16)
                .animation(.snappy, value: input)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("定期チェック")
            .safeAreaInset(edge: .bottom, spacing: 0) { bannerArea }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        saveName = ""
                        showSaveDialog = true
                    } label: { Image(systemName: "bookmark") }
                        .disabled(!input.isCalculable)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPaywall = true
                    } label: {
                        Image(systemName: store.isPro ? "crown.fill" : "crown")
                            .foregroundStyle(store.isPro ? .yellow : .accentColor)
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") { focused = nil }
                }
            }
            .sheet(item: $editingTrip) { trip in
                ExtraTripEditor(trip: trip) { updated in
                    upsert(updated)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onAppear {
                // デモ／スクショ用の起動引数を反映する。
                if Launch.isDemo, input == TeikiInput() {
                    input = Launch.demoInput
                }
                if Launch.showPaywall { showPaywall = true }
            }
            .alert("この区間を保存", isPresented: $showSaveDialog) {
                TextField("区間名（例：自宅 ⇔ 会社）", text: $saveName)
                Button("保存") { save() }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("入力内容を履歴に保存します。")
            }
        }
    }

    // MARK: - 入力カード

    private var inputCard: some View {
        VStack(spacing: 18) {
            numberField("片道の普通運賃", systemImage: "yensign.circle", value: $input.oneWayFare, focus: .fare, suffix: "円")
            Divider()
            numberField("定期代（\(input.period.label)）", systemImage: "creditcard", value: $input.passPrice, focus: .pass, suffix: "円")
            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Label("定期の期間", systemImage: "calendar")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Picker("定期の期間", selection: $input.period) {
                    ForEach(TeikiPeriod.allCases) { period in
                        Text(period.label).tag(period)
                    }
                }
                .pickerStyle(.segmented)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("月の通勤・通学日数", systemImage: "figure.walk")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(input.commuteDaysPerMonth) 日")
                        .font(.headline)
                        .monospacedDigit()
                }
                Slider(value: Binding(
                    get: { Double(input.commuteDaysPerMonth) },
                    set: { input.commuteDaysPerMonth = Int($0.rounded()) }
                ), in: 0...31, step: 1)
            }
        }
        .cardStyle()
    }

    private func numberField(_ title: String, systemImage: String, value: Binding<Int>, focus: Field, suffix: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 26)
            Text(title)
                .font(.subheadline)
            Spacer()
            TextField("0", value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .focused($focused, equals: focus)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: 120)
            Text(suffix)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyHint: some View {
        VStack(spacing: 10) {
            Image(systemName: "tram.fill")
                .font(.system(size: 34))
                .foregroundStyle(Color.accentColor.opacity(0.6))
            Text("片道運賃と定期代を入力すると、\n元が取れる往復回数を計算します。")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    // MARK: - 追加利用カード

    private var extraTripsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("定期区間内の追加利用", systemImage: "sparkles")
                    .font(.headline)
                Spacer()
                Button {
                    editingTrip = ExtraTrip()
                } label: { Image(systemName: "plus.circle.fill").font(.title3) }
            }
            Text("途中下車での買い物や、区間内の駅での用事など。定期があれば追加料金ゼロになるぶんを元取りに加算します。")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if input.extraTrips.isEmpty {
                Text("まだ追加利用はありません")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(input.extraTrips) { trip in
                    Button { editingTrip = trip } label: { extraRow(trip) }
                        .buttonStyle(.plain)
                }
            }
        }
        .cardStyle()
    }

    private func extraRow(_ trip: ExtraTrip) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(trip.name.isEmpty ? "名称未設定" : trip.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text("\(Theme.yen(trip.oneWayFare))・\(trip.isRoundTrip ? "往復" : "片道")・月\(trip.timesPerMonth)回")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("+\(Theme.yen(trip.monthlyValue))/月")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }

    // MARK: - バナー広告

    /// iOS 26 のタブバーは中身の上に浮くので、バナーの下（タブバーの裏）も塗りつぶして、
    /// 広告とタブバーのすきまに中身が透けて見えないようにする（AdMob の「広告に重なるコンテンツ」対策）。
    @ViewBuilder private var bannerArea: some View {
        if !store.isPro, !Launch.hideAds {
            BannerAdView()
                .background(Color(.systemGroupedBackground).ignoresSafeArea(edges: .bottom))
        }
    }

    // MARK: - 操作

    private func upsert(_ trip: ExtraTrip) {
        if let index = input.extraTrips.firstIndex(where: { $0.id == trip.id }) {
            // 空欄で保存されたものは削除扱い。
            if trip.oneWayFare <= 0 {
                input.extraTrips.remove(at: index)
            } else {
                input.extraTrips[index] = trip
            }
        } else if trip.oneWayFare > 0 {
            input.extraTrips.append(trip)
        }
    }

    private func save() {
        let name = saveName.trimmingCharacters(in: .whitespaces)
        let route = SavedRoute(name: name.isEmpty ? "無題の区間" : name, input: input)
        modelContext.insert(route)
        try? modelContext.save()

        let ask = RatingAsk()
        if ask.isDue {
            ask.remember()
            // 保存の確認ダイアログが閉じてから出す。
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                requestReview()
            }
        }
    }
}

#Preview {
    CalculatorView()
        .environment(StoreManager())
        .modelContainer(for: SavedRoute.self, inMemory: true)
}
