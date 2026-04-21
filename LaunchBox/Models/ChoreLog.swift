//
//  ChoreLog.swift
//  LaunchBox
//

import Foundation
import SwiftData

@Model
final class ChoreLog {
    var id: UUID = UUID()
    var completedAt: Date = Date()
    var memberID: UUID = UUID()
    var modifiedAt: Date = Date()

    var chore: Chore?

    init(
        id: UUID = UUID(),
        completedAt: Date = Date(),
        memberID: UUID,
        chore: Chore? = nil,
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.completedAt = completedAt
        self.memberID = memberID
        self.chore = chore
        self.modifiedAt = modifiedAt
    }
}
