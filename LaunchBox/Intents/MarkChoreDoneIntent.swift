//
//  MarkChoreDoneIntent.swift
//  LaunchBox
//

import AppIntents
import SwiftData

struct MarkChoreDoneIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark chore done"
    static var description = IntentDescription("Marks a chore as done for whoever’s turn it is right now.")
    static var isDiscoverable: Bool = true
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Chore title", requestValueDialog: IntentDialog("Which chore?"))
    var choreTitle: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmed = choreTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .result(dialog: IntentDialog("Say which chore to mark done."))
        }

        guard let context = ModelContainerHolder.container?.mainContext else {
            return .result(dialog: IntentDialog("Open the app once, then try this shortcut again."))
        }

        do {
            let home = try PersistenceBootstrap.ensureHousehold(context: context)
            let all = home.chores ?? []
            for c in all { c.recomputeAssigneeFromLogs() }

            if let exact = all.first(where: { $0.title.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                try IntentChoreActions.markDone(exact, context: context)
                return .result(dialog: IntentDialog("Marked “\(exact.title)” done."))
            }

            let partial = all.filter { $0.title.localizedCaseInsensitiveContains(trimmed) }
            if partial.count == 1, let c = partial.first {
                try IntentChoreActions.markDone(c, context: context)
                return .result(dialog: IntentDialog("Marked “\(c.title)” done."))
            }
            if partial.isEmpty {
                return .result(dialog: IntentDialog("No chore matches that name in your home."))
            }
            return .result(dialog: IntentDialog("Several chores match. Say the full name, or do it in the app."))
        } catch {
            return .result(dialog: IntentDialog("Couldn’t update chores: \(error.localizedDescription)"))
        }
    }
}
