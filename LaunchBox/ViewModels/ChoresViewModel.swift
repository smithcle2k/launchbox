//
//  ChoresViewModel.swift
//  LaunchBox
//

import Foundation
import SwiftData
import UserNotifications

@Observable
@MainActor
final class ChoresViewModel {
    var household: Household?
    var members: [Member] = []
    var chores: [Chore] = []
    var dueToday: [Chore] = []
    var upcoming: [Chore] = []
    var later: [Chore] = []
    var isLoading = true
    var errorMessage: String?

    private var calendar: Calendar = .current

    func load(context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let home = try PersistenceBootstrap.ensureHousehold(context: context)
            household = home

            members = (home.members ?? []).sorted {
                if $0.sortIndex != $1.sortIndex { return $0.sortIndex < $1.sortIndex }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

            chores = (home.chores ?? []).sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }

            for c in chores {
                c.recomputeAssigneeFromLogs()
            }
            try? context.save()

            recomputeBuckets(now: Date())
            publishWidgetSnapshot()
        } catch {
            errorMessage = error.localizedDescription
            members = []
            chores = []
            dueToday = []
            upcoming = []
            later = []
        }
    }

    func recomputeBuckets(now: Date = Date()) {
        dueToday = []
        upcoming = []
        later = []
        for chore in chores {
            let cadence = chore.cadence
            if ChoreDueDateCalculator.isDueTodayOrOverdue(
                lastCompletedAt: chore.lastCompletedAt,
                createdAt: chore.createdAt,
                cadence: cadence,
                calendar: calendar,
                now: now
            ) {
                dueToday.append(chore)
            } else if ChoreDueDateCalculator.isUpcomingWithinDays(
                lastCompletedAt: chore.lastCompletedAt,
                createdAt: chore.createdAt,
                cadence: cadence,
                days: 7,
                calendar: calendar,
                now: now
            ) {
                upcoming.append(chore)
            } else {
                later.append(chore)
            }
        }
        let byTitle = SortDescriptor<Chore>(\.title)
        dueToday.sort(using: byTitle)
        upcoming.sort(using: byTitle)
        later.sort(using: byTitle)
    }

    func markDone(chore: Chore, context: ModelContext) async {
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

        do {
            try context.save()
            HouseholdCloudKitStore.shared.scheduleSync(context: context)
            await reloadAndReschedule(context: context)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func undoLastDone(chore: Chore, context: ModelContext) async {
        let logs = (chore.logs ?? []).sorted { $0.completedAt > $1.completedAt }
        guard let newest = logs.first else { return }
        context.delete(newest)
        let remaining = logs.dropFirst()
        chore.lastCompletedAt = remaining.first?.completedAt
        chore.touchModified()
        chore.household?.touchModified()
        chore.recomputeAssigneeFromLogs()
        do {
            try context.save()
            HouseholdCloudKitStore.shared.scheduleSync(context: context)
            await reloadAndReschedule(context: context)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reloadAndReschedule(context: ModelContext) async {
        await load(context: context)
        await NotificationScheduler.rescheduleFromModelContext(context)
    }

    private func publishWidgetSnapshot() {
        guard let home = household else { return }
        let map = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0) })
        let orderedForWidget = dueToday + upcoming + later
        let snap = WidgetSnapshotBuilder.make(household: home, chores: orderedForWidget, membersByID: map)
        WidgetSnapshotStore.write(snap)
    }

    func deleteChore(_ chore: Chore, context: ModelContext) {
        chore.household?.touchModified()
        context.delete(chore)
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [chore.id.uuidString]
        )
        try? context.save()
        HouseholdCloudKitStore.shared.scheduleSync(context: context)
        Task { await load(context: context) }
    }
}
