//
//  AppRouter.swift
//  LaunchBox
//

import SwiftUI

// MARK: - App launch phase (splash → onboarding → main shell)

enum AppPhase: Hashable {
    case splash
    case onboarding
    case main
}

// MARK: - Tabs (type-safe TabView selection)

enum AppTab: String, CaseIterable, Hashable, Identifiable {
    case chores
    case settings

    var id: String { rawValue }
}

// MARK: - Navigation routes (typed stack destinations)

enum AppRoute: Hashable {
    case choreDetail(UUID)
    case addChore
    case editMember(UUID)
    case history
}

// MARK: - Router

@Observable
@MainActor
final class AppRouter {
    var selectedTab: AppTab = .chores

    var choresPath = NavigationPath()
    var settingsPath = NavigationPath()
}
