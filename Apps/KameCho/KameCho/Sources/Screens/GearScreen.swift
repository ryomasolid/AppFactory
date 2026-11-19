import SwiftData
import SwiftUI

/// 器具：ライト・ヒーター・ろ材の交換時期。
struct GearScreen: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Gear.installedOn) private var gears: [Gear]
    @State private var editing: Gear?
    @State private var adding = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if gears.isEmpty {
                        Panel(title: "器具を登録しましょう", symbol: "sun.haze.fill") {
                            Text("紫外線ライト（UVB）は、光っていても半年ほどで紫外線が弱くなります。取り付けた日を残しておくと、交換の時期をお知らせできます。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    ForEach(ordered) { gear in
                        GearCard(gear: gear) {
                            gear.installedOn = Date()
                            gear.swaps += 1
                            Task { await Reminders.refresh(context) }
                        } edit: {
                            editing = gear
                        }
                    }
                }
                .padding()
            }
            .background(Palette.sand.ignoresSafeArea())
            .navigationTitle("器具")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { adding = true } label: { Label("追加", systemImage: "plus") }
                        .accessibilityIdentifier("add-gear")
                }
            }
            .sheet(item: $editing) { GearEditor(gear: $0) }
            .sheet(isPresented: $adding) { GearEditor(gear: nil) }
        }
    }

    /// 交換が近い順。
    private var ordered: [Gear] {
        gears.sorted {
            GearLife.daysLeft(installedOn: $0.installedOn, lifeDays: $0.lifeDays, now: Date())
                < GearLife.daysLeft(installedOn: $1.installedOn, lifeDays: $1.lifeDays, now: Date())
        }
    }
}

private struct GearCard: View {
    let gear: Gear
    let swap: () -> Void
    let edit: () -> Void
    @State private var confirm = false

    var body: some View {
        let left = GearLife.daysLeft(installedOn: gear.installedOn, lifeDays: gear.lifeDays, now: Date())
        let used = GearLife.used(installedOn: gear.installedOn, lifeDays: gear.lifeDays, now: Date())
        let color = left < 0 ? Palette.rust : GearLife.soon(daysLeft: left) ? Palette.amber : Palette.moss
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: gear.kind.symbol)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(gear.name).font(.headline).foregroundStyle(Palette.ink)
                    Text([gear.kind.label, gear.place].filter { !$0.isEmpty }.joined(separator: "・"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: edit) { Image(systemName: "ellipsis.circle") }
                    .accessibilityLabel("編集")
            }
            ProgressView(value: used).tint(color)
            HStack {
                Text("取り付け \(gear.installedOn.formatted(.dateTime.year().month().day()))")
                Spacer()
                Text(left < 0 ? "\(-left)日すぎ" : left == 0 ? "きょう交換" : "あと\(left)日")
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            }
            .font(.caption)
            if GearLife.soon(daysLeft: left) {
                if !gear.kind.why.isEmpty {
                    Text(gear.kind.why).font(.caption).foregroundStyle(.secondary)
                }
                Button("交換した") { confirm = true }
                    .buttonStyle(.borderedProminent)
                    .tint(color)
                    .accessibilityIdentifier("swap-\(gear.name)")
            }
        }
        .padding(16)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .confirmationDialog("「\(gear.name)」をきょう交換したことにします。", isPresented: $confirm, titleVisibility: .visible) {
            Button("交換した", action: swap)
        }
    }
}

struct GearEditor: View {
    let gear: Gear?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var kind: GearKind = .uvb
    @State private var name = ""
    @State private var place = ""
    @State private var installedOn = Date()
    @State private var lifeDays = GearKind.uvb.lifeDays
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("種類", selection: $kind) {
                        ForEach(GearKind.allCases) { Label($0.label, systemImage: $0.symbol).tag($0) }
                    }
                    TextField("名前（例：UVB 蛍光灯 10.0）", text: $name)
                        .accessibilityIdentifier("gear-name")
                    TextField("置き場所（例：90cm 水槽）", text: $place)
                }
                Section {
                    DatePicker("取り付けた日", selection: $installedOn, in: ...Date(), displayedComponents: .date)
                    Stepper(value: $lifeDays, in: 7...1095, step: lifeDays < 60 ? 7 : 30) {
                        HStack {
                            Text("交換の目安")
                            Spacer()
                            Text(lifeDays % 30 == 0 && lifeDays >= 60 ? "\(lifeDays / 30)か月" : "\(lifeDays)日").foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text(kind.why.isEmpty ? "製品の説明書にある交換時期に合わせてください。" : kind.why + "製品の説明書に時期があれば、それに合わせてください。")
                }
                if gear != nil {
                    Section { Button("この器具を削除", role: .destructive) { confirmDelete = true } }
                }
            }
            .navigationTitle(gear == nil ? "器具を追加" : "器具を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存", action: save) }
            }
            .onChange(of: kind) { old, new in
                if gear == nil || lifeDays == old.lifeDays { lifeDays = new.lifeDays }
            }
            .onAppear {
                guard let gear else { return }
                kind = gear.kind
                name = gear.name
                place = gear.place
                installedOn = gear.installedOn
                lifeDays = gear.lifeDays
            }
            .confirmationDialog("「\(gear?.name ?? "")」を削除します。", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("削除する", role: .destructive) {
                    if let gear { context.delete(gear) }
                    dismiss()
                }
            }
        }
    }

    private func save() {
        let title = name.trimmingCharacters(in: .whitespaces).isEmpty ? kind.label : name.trimmingCharacters(in: .whitespaces)
        if let gear {
            gear.kind = kind
            gear.name = title
            gear.place = place
            gear.installedOn = installedOn
            gear.lifeDays = lifeDays
        } else {
            context.insert(Gear(kind: kind, name: title, place: place, installedOn: installedOn, lifeDays: lifeDays))
        }
        Task { await Reminders.refresh(context) }
        dismiss()
    }
}
