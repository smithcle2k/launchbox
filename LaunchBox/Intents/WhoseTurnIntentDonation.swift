//
//  WhoseTurnIntentDonation.swift
//  LaunchBox
//

import AppIntents

/// Refreshes Shortcuts / Siri parameter metadata when the app becomes active.
@MainActor
enum WhoseTurnIntentDonation {
    static func refreshOnForeground() async {
        await WhoseTurnAppShortcuts.updateAppShortcutParameters()
    }
}
