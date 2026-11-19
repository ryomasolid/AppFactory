import Foundation

/// 朝のお知らせの文面。何もない日は出さない。
enum MorningNote {
    struct Line: Equatable {
        let turtle: String
        let task: String
    }

    static func body(lines: [Line], gearNames: [String]) -> String? {
        var parts: [String] = []
        var byTask: [(String, [String])] = []
        for line in lines {
            if let i = byTask.firstIndex(where: { $0.0 == line.task }) {
                byTask[i].1.append(line.turtle)
            } else {
                byTask.append((line.task, [line.turtle]))
            }
        }
        for (task, names) in byTask {
            parts.append("\(task)：\(names.joined(separator: "・"))")
        }
        if !gearNames.isEmpty {
            parts.append("交換の時期：\(gearNames.joined(separator: "・"))")
        }
        return parts.isEmpty ? nil : parts.joined(separator: "\n")
    }

    static func taskName(_ task: Due.Task) -> String {
        switch task {
        case .care(let kind): kind.label
        case .measure: "体重・甲長を計る"
        }
    }
}
