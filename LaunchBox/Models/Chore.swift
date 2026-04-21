//
//  Chore.swift
//  LaunchBox
//

import Foundation
import SwiftData

@Model
final class Chore {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var createdAt: Date = Date()
    var lastCompletedAt: Date?
    var currentAssigneeID: UUID?
    /// JSON-encoded `ChoreCadence`
    var cadenceJSON: String = "{}"
    /// JSON array of member UUID strings in rotation order
    var rotationOrderJSON: String = "[]"
    var modifiedAt: Date = Date()

    var household: Household?

    @Relationship(deleteRule: .cascade, inverse: \ChoreLog.chore)
    var logs: [ChoreLog]?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        createdAt: Date = Date(),
        lastCompletedAt: Date? = nil,
        currentAssigneeID: UUID? = nil,
        cadence: ChoreCadence,
        rotationMemberIDs: [UUID],
        household: Household? = nil,
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.createdAt = createdAt
        self.lastCompletedAt = lastCompletedAt
        self.currentAssigneeID = currentAssigneeID
        self.cadenceJSON = (try? cadence.encodedJSON()) ?? "{}"
        self.rotationOrderJSON = Self.encodeRotation(rotationMemberIDs)
        self.household = household
        self.modifiedAt = modifiedAt
    }

    var cadence: ChoreCadence {
        get {
            (try? ChoreCadence.decode(json: cadenceJSON)) ?? .dailyDefault
        }
        set {
            cadenceJSON = (try? newValue.encodedJSON()) ?? "{}"
        }
    }

    var rotationMemberIDs: [UUID] {
        get { Self.decodeRotation(rotationOrderJSON) }
        set { rotationOrderJSON = Self.encodeRotation(newValue) }
    }

    static func encodeRotation(_ ids: [UUID]) -> String {
        let strings = ids.map(\.uuidString)
        guard let data = try? JSONEncoder().encode(strings),
              let s = String(data: data, encoding: .utf8)
        else { return "[]" }
        return s
    }

    static func decodeRotation(_ json: String) -> [UUID] {
        guard let data = json.data(using: .utf8),
              let strings = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return strings.compactMap(UUID.init(uuidString:))
    }

    func displayAssigneeName(members: [Member]) -> String {
        let id = currentAssigneeID ?? rotationMemberIDs.first
        guard let id else { return String(localized: "Anyone") }
        return members.first(where: { $0.id == id })?.name ?? String(localized: "Anyone")
    }

    /// Next person in rotation after the most recent completion in `logs`.
    static func nextAssigneeID(rotation: [UUID], logs: [ChoreLog]) -> UUID? {
        let order = rotation
        guard !order.isEmpty else { return nil }
        guard let last = logs.max(by: { $0.completedAt < $1.completedAt }),
              let idx = order.firstIndex(of: last.memberID)
        else {
            return order.first
        }
        let nextIdx = (idx + 1) % order.count
        return order[nextIdx]
    }

    func recomputeAssigneeFromLogs() {
        let list = logs ?? []
        currentAssigneeID = Self.nextAssigneeID(rotation: rotationMemberIDs, logs: list)
    }
}
