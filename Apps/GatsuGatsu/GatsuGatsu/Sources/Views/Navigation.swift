import Observation
import SwiftUI

enum AppTab: String, CaseIterable, Hashable {
    case home, stations, read, tools, log

    var title: String {
        switch self {
        case .home: "ホーム"
        case .stations: "駅で探す"
        case .read: "記事"
        case .tools: "ツール"
        case .log: "記録"
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .stations: "tram.fill"
        case .read: "book.fill"
        case .tools: "plusminus.circle.fill"
        case .log: "chart.bar.fill"
        }
    }
}

enum ToolKind: String, CaseIterable, Identifiable, Hashable {
    case quantity, calorie, queue, buffet, split
    var id: String { rawValue }

    var title: String {
        switch self {
        case .quantity: "外食の量 早見表"
        case .calorie: "カロリー＆PFC計算"
        case .queue: "行列の待ち時間"
        case .buffet: "食べ放題の元取り"
        case .split: "割り勘＆傾斜計算"
        }
    }

    var blurb: String {
        switch self {
        case .quantity: "麺300gは茹でると何g？ 茶碗何杯ぶん？"
        case .calorie: "チェーンの公式値で足し算して、そのまま記録"
        case .queue: "並ぶ人数と席数から入店時刻。5分前に通知も"
        case .buffet: "食べた分を足して、コース料金と比べる"
        case .split: "上司は多めに。結果はそのままLINEへ"
        }
    }

    var icon: String {
        switch self {
        case .quantity: "scalemass.fill"
        case .calorie: "flame.fill"
        case .queue: "person.3.sequence.fill"
        case .buffet: "takeoutbag.and.cup.and.straw.fill"
        case .split: "yensign.circle.fill"
        }
    }

    /// サイトの同じツールのパス。広告の文脈づけに使う。
    var webPath: String {
        switch self {
        case .quantity: "/ryou"
        case .calorie: "/calorie"
        case .queue: "/waittime"
        case .buffet: "/tabehoudai"
        case .split: "/warikan"
        }
    }
}

enum Route: Hashable {
    case guide(String)
    case report(String)
    case station(String)
    /// 記事のない駅（全国の駅一覧の id）。
    case japanStation(Int)
    case stationIndex
    case tool(ToolKind)
    case search
    case settings
    case privacy
    case monthReport

    /// サイト内リンク（/column/xxx など）をアプリの画面へ。
    init?(href: String) {
        let parts = href.split(separator: "/").map(String.init)
        switch (parts.first, parts.count) {
        case ("column", 2): self = .guide(parts[1])
        case ("report", 2): self = .report(parts[1])
        case ("station", 2): self = .station(parts[1].removingPercentEncoding ?? parts[1])
        case ("station", 1): self = .stationIndex
        case ("ryou", 1): self = .tool(.quantity)
        case ("calorie", 1): self = .tool(.calorie)
        case ("waittime", 1): self = .tool(.queue)
        case ("tabehoudai", 1): self = .tool(.buffet)
        case ("warikan", 1): self = .tool(.split)
        default: return nil
        }
    }

    /// 読み終えて戻ったときに「ひと区切り」と数える画面か。設定や検索は数えない。
    var countsAsContent: Bool {
        switch self {
        case .guide, .report, .station, .tool: true
        case .japanStation, .stationIndex, .search, .settings, .privacy, .monthReport: false
        }
    }
}

@MainActor
@Observable
final class Navigator {
    var tab: AppTab = .home
    var paths: [AppTab: [Route]] = [:]

    func binding(for tab: AppTab) -> Binding<[Route]> {
        Binding(get: { self.paths[tab] ?? [] }, set: { self.paths[tab] = $0 })
    }

    /// 撮影と動作確認用の起動引数（-tab log / -push guide:gohan-gram / -push japan:博多 / -homeQuery 名古屋）。
    func applyLaunchArguments() {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: "tab"), let tab = AppTab(rawValue: raw) { self.tab = tab }
        guard let push = defaults.string(forKey: "push") else { return }
        let parts = push.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return }
        let route: Route? = switch parts[0] {
        case "guide": .guide(parts[1])
        case "report": .report(parts[1])
        case "station": .station(parts[1])
        case "tool": ToolKind(rawValue: parts[1]).map(Route.tool)
        case "japan": JapanStations.shared.all.first { $0.name == parts[1] }.map { Route.japanStation($0.id) }
        case "screen": parts[1] == "settings" ? .settings : (parts[1] == "month" ? .monthReport : .search)
        default: nil
        }
        if let route { paths[tab] = [route] }
    }
}

/// 各タブの NavigationStack。バナーと「読み終えた」の検知をここにまとめる。
struct TabStack<Root: View>: View {
    let tab: AppTab
    @ViewBuilder let root: () -> Root
    @Environment(Navigator.self) private var navigator
    @Environment(AdDirector.self) private var ads

    var body: some View {
        NavigationStack(path: navigator.binding(for: tab)) {
            root()
                .navigationDestination(for: Route.self) { RouteScreen(route: $0) }
        }
        .bannerStrip(path: (navigator.paths[tab]?.last).flatMap(Self.webPath))
        .onChange(of: navigator.paths[tab] ?? []) { old, new in
            guard new.count < old.count, old[new.count...].contains(where: \.countsAsContent) else { return }
            ads.pageFinished()
        }
    }

    private static func webPath(_ route: Route) -> String? {
        switch route {
        case .guide(let slug): "/column/\(slug)"
        case .report(let slug): "/report/\(slug)"
        case .tool(let kind): kind.webPath
        default: nil
        }
    }
}

struct RouteScreen: View {
    let route: Route

    var body: some View {
        switch route {
        case .guide(let slug): GuideScreen(slug: slug)
        case .report(let slug): ReportScreen(slug: slug)
        case .station(let name): StationScreen(name: name)
        case .japanStation(let id): JapanStationScreen(id: id)
        case .stationIndex: StationIndexScreen()
        case .tool(.quantity): QuantityTool()
        case .tool(.calorie): CalorieTool()
        case .tool(.queue): QueueTool()
        case .tool(.buffet): BuffetTool()
        case .tool(.split): SplitTool()
        case .search: SearchScreen()
        case .settings: SettingsScreen()
        case .privacy: PrivacyScreen()
        case .monthReport: MonthReportScreen()
        }
    }
}
