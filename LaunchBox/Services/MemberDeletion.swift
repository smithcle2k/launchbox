//
//  MemberDeletion.swift
//  LaunchBox
//

import Foundation
import SwiftData

enum MemberDeletion {
    /// Removes the member and strips them from every chore rotation in the same household.
    static func delete(_ member: Member, context: ModelContext) throws {
        let mid = member.id
        guard let home = member.household else {
            context.delete(member)
            try context.save()
            return
        }
        let chores = home.chores ?? []

        for chore in chores {
            var order = chore.rotationMemberIDs
            order.removeAll { $0 == mid }
            chore.rotationMemberIDs = order
            if chore.currentAssigneeID == mid {
                chore.currentAssigneeID = order.first
            }
            chore.recomputeAssigneeFromLogs()
            chore.touchModified()
        }
        home.touchModified()

        context.delete(member)
        try context.save()
    }
}
