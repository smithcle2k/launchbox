//
//  WhatsMyChoreIntent.swift
//  LaunchBox
//

import AppIntents
import Foundation
import SwiftData

struct WhatsMyChoreIntent: AppIntent {
    static var title: LocalizedStringResource = "What’s my chore"
    static var description = IntentDescription("Tells you which chores you’re on deck for, using “This is me” in Settings.")
    static var isDiscoverable: Bool = true
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        guard let context = ModelContainerHolder.container?.mainContext else {
            let s = "Open the app once, then run this again."
            return .result(value: s, dialog: IntentDialog("Open the app once, then run this again."))
        }

        do {
            let myRaw = UserDefaults.standard.string(forKey: AppStorageKeys.myMemberID) ?? ""
            guard let myID = UUID(uuidString: myRaw) else {
                let s = "Set “This is me” in Whose Turn? under Settings, then I can help."
                return .result(value: s, dialog: IntentDialog(LocalizedStringResource(stringLiteral: s)))
            }

            let home = try PersistenceBootstrap.ensureHousehold(context: context)
            var mine: [String] = []
            for c in home.chores ?? [] {
                c.recomputeAssigneeFromLogs()
                if c.currentAssigneeID == myID {
                    mine.append(c.title)
                }
            }
            mine.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

            if mine.isEmpty {
                let s = "You’re not on deck for any chores right now."
                return .result(value: s, dialog: IntentDialog(LocalizedStringResource(stringLiteral: s)))
            }
            let list = mine.joined(separator: ", ")
            let s = "You’re up for: \(list)."
            return .result(value: s, dialog: IntentDialog(LocalizedStringResource(stringLiteral: s)))
        } catch {
            let s = "Couldn’t read chores: \(error.localizedDescription)"
            return .result(value: s, dialog: IntentDialog(LocalizedStringResource(stringLiteral: s)))
        }
    }
}
