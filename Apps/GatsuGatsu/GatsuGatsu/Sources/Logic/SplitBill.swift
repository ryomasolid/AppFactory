import Foundation

/// 金額に差をつける割り勘。各グループは「通常メンバーより何円多い／少ないか」を持つ。
/// 1人あたりは100円単位で切り上げるので、集めた額がお会計を上回ることがある（幹事預かり）。
enum SplitBill {
    struct Tier: Identifiable, Equatable {
        var id = UUID()
        var name: String
        var count: Int
        var adjustment: Int
    }

    struct Line: Identifiable, Equatable {
        let id: UUID
        let name: String
        let count: Int
        let perPerson: Int
        var subtotal: Int { perPerson * count }
    }

    struct Result: Equatable {
        let lines: [Line]
        let bill: Int
        let people: Int
        var collected: Int { lines.reduce(0) { $0 + $1.subtotal } }
        var surplus: Int { collected - bill }

        var shareText: String {
            var rows = ["【割り勘の結果】", "お会計 \(bill.yen) ／ \(people)人", ""]
            rows += lines.map { "\($0.name)（\($0.count)人）: 1人 \($0.perPerson.yen)" }
            rows += ["", "集める合計 \(collected.yen)"]
            if surplus > 0 { rows.append("幹事の預かり \(surplus.yen)") }
            return rows.joined(separator: "\n")
        }
    }

    enum Failure: Error, Equatable {
        case noBill, noPeople, noRegulars
        case negative(String)

        var message: String {
            switch self {
            case .noBill: "お会計の金額を入れてください"
            case .noPeople: "参加人数を入れてください"
            case .noRegulars: "通常メンバーが0人になっています。グループの人数を見直してください"
            case .negative(let name): "「\(name)」の支払いがマイナスになります。差額を小さくしてください"
            }
        }
    }

    /// 全員のうち、差をつけるグループに入らない人数。
    static func regularCount(people: Int, tiers: [Tier]) -> Int {
        max(people - tiers.reduce(0) { $0 + $1.count }, 0)
    }

    static func calculate(bill: Int, people: Int, tiers: [Tier], regularsID: UUID = UUID()) -> Swift.Result<Result, Failure> {
        guard bill > 0 else { return .failure(.noBill) }
        guard people > 0 else { return .failure(.noPeople) }
        let regulars = regularCount(people: people, tiers: tiers)
        guard regulars > 0 else { return .failure(.noRegulars) }

        let adjustments = tiers.reduce(0) { $0 + $1.count * $1.adjustment }
        let base = (Double(bill) - Double(adjustments)) / Double(people)

        func perPerson(_ adjustment: Int) -> Int? {
            let raw = base + Double(adjustment)
            return raw > 0 ? Int((raw / 100).rounded(.up)) * 100 : nil
        }
        guard let regular = perPerson(0) else { return .failure(.negative("通常メンバー")) }
        var lines = [Line(id: regularsID, name: "通常メンバー", count: regulars, perPerson: regular)]
        for tier in tiers {
            guard let amount = perPerson(tier.adjustment) else { return .failure(.negative(tier.name)) }
            lines.append(Line(id: tier.id, name: tier.name, count: tier.count, perPerson: amount))
        }
        return .success(Result(lines: lines, bill: bill, people: people))
    }
}

extension Int {
    var yen: String { "\(formatted(.number.locale(Locale(identifier: "ja_JP"))))円" }
}
