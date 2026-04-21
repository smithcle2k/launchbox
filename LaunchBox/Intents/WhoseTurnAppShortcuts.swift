//
//  WhoseTurnAppShortcuts.swift
//  LaunchBox
//

import AppIntents

/// Surfaces the two intents in the Shortcuts app and for Siri.
struct WhoseTurnAppShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: WhatsMyChoreIntent(),
            phrases: [
                "What’s my \(.applicationName) chore",
                "What chore is mine in \(.applicationName)",
                "Whose turn in \(.applicationName)"
            ],
            shortTitle: "What’s my chore",
            systemImageName: "checklist"
        )
        AppShortcut(
            intent: MarkChoreDoneIntent(),
            phrases: [
                "Mark a chore done in \(.applicationName)"
            ],
            shortTitle: "Mark chore done",
            systemImageName: "checkmark.circle"
        )
    }
}
