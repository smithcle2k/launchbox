//
//  SettingsViewModel.swift
//  LaunchBox
//

import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class SettingsViewModel {
    var household: Household?
    var members: [Member] = []
    /// Every household in the local store (for switching the active one).
    var allHouseholds: [Household] = []
    /// Picker state — kept in sync with `household` in `load`.
    var activeHouseholdSelection: UUID = UUID()
    var isLoading = true
    var errorMessage: String?

    func load(context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            allHouseholds = try PersistenceBootstrap.allHouseholds(context: context)
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            let home = try PersistenceBootstrap.ensureHousehold(context: context)
            household = home
            activeHouseholdSelection = home.id

            members = (home.members ?? []).sorted {
                if $0.sortIndex != $1.sortIndex { return $0.sortIndex < $1.sortIndex }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        } catch {
            errorMessage = error.localizedDescription
            members = []
            allHouseholds = []
        }
    }

    func switchToHousehold(id: UUID, context: ModelContext) {
        PersistenceBootstrap.setActiveHouseholdID(id)
        activeHouseholdSelection = id
        Task { await load(context: context) }
        NotificationCenter.default.post(name: .whosTurnCloudDataDidChange, object: nil)
    }

    func addMember(name: String, context: ModelContext) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let home = household else { return }
        let nextIndex = (members.map(\.sortIndex).max() ?? -1) + 1
        let color = MemberPalette.color(at: members.count)
        home.touchModified()
        let member = Member(name: trimmed, colorHex: color, sortIndex: nextIndex, household: home)
        context.insert(member)
        try? context.save()
        HouseholdCloudKitStore.shared.scheduleSync(context: context)
        Task { await load(context: context) }
    }

    func deleteMember(_ member: Member, context: ModelContext) {
        member.household?.touchModified()
        context.delete(member)
        try? context.save()
        HouseholdCloudKitStore.shared.scheduleSync(context: context)
        Task { await load(context: context) }
    }

    func moveMembers(from source: IndexSet, to destination: Int, context: ModelContext) {
        var ordered = members
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, member) in ordered.enumerated() {
            member.sortIndex = index
        }
        household?.touchModified()
        try? context.save()
        HouseholdCloudKitStore.shared.scheduleSync(context: context)
        Task { await load(context: context) }
    }

    func updateMemberName(_ member: Member, name: String, context: ModelContext) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        member.name = trimmed
        member.touchModified()
        member.household?.touchModified()
        try? context.save()
        HouseholdCloudKitStore.shared.scheduleSync(context: context)
        Task { await load(context: context) }
    }
}
