//
//  AddChoreViewModel.swift
//  LaunchBox
//

import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class AddChoreViewModel {
    var title: String = ""
    var notes: String = ""
    var cadenceMode: ChoreCadence.Mode = .daily
    var weeklyWeekday: Int = 2 // Monday default for many locales — user can change
    var everyNDays: Int = 3
    /// Member IDs in rotation order (subset of household).
    var rotationMemberIDs: [UUID] = []

    var errorMessage: String?

    func prepareRotation(from members: [Member]) {
        if rotationMemberIDs.isEmpty {
            rotationMemberIDs = members.sorted { $0.sortIndex < $1.sortIndex }.map(\.id)
        }
    }

    func toggleMemberInRotation(_ id: UUID) {
        if let idx = rotationMemberIDs.firstIndex(of: id) {
            rotationMemberIDs.remove(at: idx)
        } else {
            rotationMemberIDs.append(id)
        }
    }

    func moveRotation(from source: IndexSet, to destination: Int) {
        rotationMemberIDs.move(fromOffsets: source, toOffset: destination)
    }

    private func buildCadence() -> ChoreCadence {
        switch cadenceMode {
        case .daily:
            return .dailyDefault
        case .weekly:
            return .weekly(weekday: weeklyWeekday)
        case .everyNDays:
            return .every(days: everyNDays)
        }
    }

    func save(household: Household, context: ModelContext) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = String(localized: "Enter a chore name.")
            return false
        }
        guard !rotationMemberIDs.isEmpty else {
            errorMessage = String(localized: "Pick at least one person for the rotation.")
            return false
        }

        let chore = Chore(
            title: trimmed,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            cadence: buildCadence(),
            rotationMemberIDs: rotationMemberIDs,
            household: household
        )
        chore.currentAssigneeID = rotationMemberIDs[0]
        chore.recomputeAssigneeFromLogs()
        household.touchModified()
        context.insert(chore)
        errorMessage = nil
        return true
    }
}
