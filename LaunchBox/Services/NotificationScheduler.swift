//
//  NotificationScheduler.swift
//  LaunchBox
//

import Foundation
import SwiftData
import UserNotifications

/// Local notifications only — no remote push or third-party SDKs.
enum NotificationScheduler {
    private static let hour = 9
    private static let minute = 0

    @MainActor
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    @MainActor
    static func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    /// Fires once when a housemate’s completion is merged from iCloud (not for your own `Member` on this device when set).
    @MainActor
    static func presentHousemateCompletionNotification(
        memberName: String,
        choreTitle: String,
        logID: UUID
    ) async {
        let enabled = UserDefaults.standard.object(forKey: AppStorageKeys.notifyHousemateCompletions) as? Bool ?? true
        guard enabled else { return }

        let granted = await authorizationStatus() == .authorized
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Chore update")
        content.body = String(localized: "\(memberName) marked “\(choreTitle)” done.")
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "whoseturn-housemate-\(logID.uuidString)",
            content: content,
            trigger: nil
        )
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // no remote logging
        }
    }

    /// Removes all pending chore notifications and re-schedules from current model state.
    @MainActor
    static func rescheduleAllChores(
        chores: [Chore],
        membersByID: [UUID: Member],
        remindersEnabled: Bool
    ) async {
        let center = UNUserNotificationCenter.current()
        let ids = chores.map { $0.id.uuidString }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        guard remindersEnabled else { return }

        let granted = await authorizationStatus() == .authorized
        guard granted else { return }

        for chore in chores {
            await schedule(chore: chore, membersByID: membersByID, center: center)
        }
    }

    @MainActor
    private static func schedule(
        chore: Chore,
        membersByID: [UUID: Member],
        center: UNUserNotificationCenter
    ) async {
        let next = ChoreDueDateCalculator.nextDueDate(
            lastCompletedAt: chore.lastCompletedAt,
            createdAt: chore.createdAt,
            cadence: chore.cadence
        )

        guard let triggerDate = notificationFireDate(forDue: next) else { return }
        if triggerDate <= Date() { return }

        var cal = Calendar.current
        cal.timeZone = .current
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)

        let content = UNMutableNotificationContent()
        content.title = chore.title
        let assigneeID = chore.currentAssigneeID ?? chore.rotationMemberIDs.first
        let name = assigneeID.flatMap { membersByID[$0]?.name } ?? String(localized: "Someone")
        content.body = String(localized: "It’s \(name)’s turn.")
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: chore.id.uuidString,
            content: content,
            trigger: trigger
        )
        do {
            try await center.add(request)
        } catch {
            // No analytics — silent failure for scheduling.
        }
    }

    /// Re-schedules from SwiftData after any chore or member change.
    @MainActor
    static func rescheduleFromModelContext(_ context: ModelContext) async {
        let enabled = UserDefaults.standard.bool(forKey: AppStorageKeys.choreRemindersEnabled)
        do {
            let home = try PersistenceBootstrap.ensureHousehold(context: context)
            let memberList = home.members ?? []
            let map = Dictionary(uniqueKeysWithValues: memberList.map { ($0.id, $0) })
            let choreList = (home.chores ?? []).sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }

            await rescheduleAllChores(
                chores: choreList,
                membersByID: map,
                remindersEnabled: enabled
            )
        } catch {
            // No remote logging
        }
    }

    /// Fires at 9:00 AM on the calendar day of `due`, or later today if that time already passed (then skip — caller may reschedule after completion).
    private static func notificationFireDate(forDue due: Date) -> Date? {
        var cal = Calendar.current
        cal.timeZone = .current
        var comps = cal.dateComponents([.year, .month, .day], from: due)
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        return cal.date(from: comps)
    }
}
