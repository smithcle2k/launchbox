//
//  HistoryViewModel.swift
//  LaunchBox
//

import Foundation
import SwiftData

struct HistoryRow: Identifiable, Hashable {
    var id: UUID { log.id }
    let log: ChoreLog
    let choreTitle: String
    let memberName: String
    let colorHex: String
}

struct HistoryWeekSummary: Identifiable, Hashable {
    var id: String { weekKey }
    let weekKey: String
    let title: String
    let rows: [HistoryRow]
    /// "Alex: 3, Sam: 2"
    let countsLine: String
}

@Observable
@MainActor
final class HistoryViewModel {
    var sections: [HistoryWeekSummary] = []
    var isLoading = true
    var errorMessage: String?

    private let calendar = Calendar.current

    func load(context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let home = try PersistenceBootstrap.ensureHousehold(context: context)
            let members = (home.members ?? []).sorted {
                if $0.sortIndex != $1.sortIndex { return $0.sortIndex < $1.sortIndex }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            let memberMap = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0) })

            var allLogs: [ChoreLog] = []
            for c in home.chores ?? [] {
                allLogs.append(contentsOf: c.logs ?? [])
            }
            allLogs.sort { $0.completedAt > $1.completedAt }

            let now = Date()
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now

            var thisWeek: [HistoryRow] = []
            var earlier: [HistoryRow] = []

            for log in allLogs {
                let choreTitle = log.chore?.title ?? String(localized: "Chore")
                let m = memberMap[log.memberID]
                let name = m?.name ?? String(localized: "Someone")
                let hex = m?.colorHex ?? "#8E8E93"
                let row = HistoryRow(log: log, choreTitle: choreTitle, memberName: name, colorHex: hex)
                if log.completedAt >= weekAgo {
                    thisWeek.append(row)
                } else if log.completedAt >= monthAgo {
                    earlier.append(row)
                }
            }

            var result: [HistoryWeekSummary] = []
            if !thisWeek.isEmpty {
                result.append(
                    HistoryWeekSummary(
                        weekKey: "7d",
                        title: String(localized: "Last 7 days"),
                        rows: thisWeek,
                        countsLine: Self.countsLine(rows: thisWeek, memberMap: memberMap)
                    )
                )
            }
            if !earlier.isEmpty {
                result.append(
                    HistoryWeekSummary(
                        weekKey: "30d",
                        title: String(localized: "Last 30 days"),
                        rows: earlier,
                        countsLine: Self.countsLine(rows: earlier, memberMap: memberMap)
                    )
                )
            }
            sections = result
        } catch {
            errorMessage = error.localizedDescription
            sections = []
        }
    }

    private static func countsLine(rows: [HistoryRow], memberMap: [UUID: Member]) -> String {
        var counts: [UUID: Int] = [:]
        for r in rows {
            counts[r.log.memberID, default: 0] += 1
        }
        let parts = counts.keys.sorted { (memberMap[$0]?.name ?? "") < (memberMap[$1]?.name ?? "") }
            .map { id -> String in
                let name = memberMap[id]?.name ?? String(localized: "Someone")
                return "\(name): \(counts[id] ?? 0)"
            }
        return parts.joined(separator: ", ")
    }
}
