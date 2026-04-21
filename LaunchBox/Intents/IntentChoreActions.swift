//
//  IntentChoreActions.swift
//  LaunchBox
//

import Foundation
import SwiftData

/// Shared logic for App Intents (mirrors `ChoresViewModel.markDone`).
@MainActor
enum IntentChoreActions {
    static func markDone(_ chore: Chore, context: ModelContext) throws {
        let order = chore.rotationMemberIDs
        guard !order.isEmpty else { return }
        let assignee = chore.currentAssigneeID ?? order[0]
        let log = ChoreLog(memberID: assignee, chore: chore)
        log.touchModified()
        context.insert(log)
        chore.lastCompletedAt = Date()
        chore.touchModified()
        chore.household?.touchModified()
        chore.recomputeAssigneeFromLogs()
        try context.save()
        HouseholdCloudKitStore.shared.scheduleSync(context: context)
    }
}
