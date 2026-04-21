//
//  WidgetSnapshotStore.swift
//  LaunchBox
//

import Foundation
import WidgetKit

/// JSON snapshot read by the widget extension; written by the main app when chores change.
struct WidgetChoreRow: Codable, Sendable {
    var title: String
    var colorHex: String
    var assigneeName: String
}

struct WidgetSnapshot: Codable, Sendable {
    var householdName: String
    var caughtUp: Bool
    var primaryLine: String
    var rows: [WidgetChoreRow]
}

enum WidgetSnapshotStore {
    static let appGroupId = "group.com.csmith.LaunchBox"
    private static let fileName = "widget-snapshot.json"

    static var fileURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        )?
            .appendingPathComponent(fileName, isDirectory: false)
    }

    @MainActor
    static func write(_ snapshot: WidgetSnapshot) {
        guard let url = fileURL else { return }
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url, options: .atomic)
            WidgetCenter.shared.reloadTimelines(ofKind: "WhoseTurnWidget")
        } catch {
            // no remote logging
        }
    }
}

/// Builds a snapshot from the active household and chores (used by the main app only).
@MainActor
enum WidgetSnapshotBuilder {
    static func make(household: Household, chores: [Chore], membersByID: [UUID: Member]) -> WidgetSnapshot {
        let name = household.name
        var rows: [WidgetChoreRow] = []
        for c in chores.prefix(3) {
            let assigneeID = c.currentAssigneeID ?? c.rotationMemberIDs.first
            let m = assigneeID.flatMap { membersByID[$0] }
            let label = m?.name ?? String(localized: "Someone")
            let color = m?.colorHex ?? "#808080"
            rows.append(WidgetChoreRow(title: c.title, colorHex: color, assigneeName: label))
        }
        if rows.isEmpty {
            return WidgetSnapshot(
                householdName: name,
                caughtUp: true,
                primaryLine: String(localized: "You’re all caught up"),
                rows: []
            )
        }
        let first = rows[0]
        return WidgetSnapshot(
            householdName: name,
            caughtUp: false,
            primaryLine: String(
                localized: "Next: \(first.title) — \(first.assigneeName)"
            ),
            rows: rows
        )
    }
}
