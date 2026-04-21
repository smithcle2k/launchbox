//
//  Household.swift
//  LaunchBox
//

import Foundation
import SwiftData

@Model
final class Household {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()
    /// Monotonic sync stamp for CloudKit merge (last-write-wins per record).
    var modifiedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Member.household)
    var members: [Member]?

    @Relationship(deleteRule: .cascade, inverse: \Chore.household)
    var chores: [Chore]?

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
