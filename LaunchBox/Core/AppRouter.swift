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
    case home
    case explore
    case notifications
    case profile

    var id: String { rawValue }
}

// MARK: - Navigation routes (typed stack destinations)

enum AppRoute: Hashable {
    case itemDetail(UUID)
    case settings
}

// MARK: - Router

@Observable
@MainActor
final class AppRouter {
    var selectedTab: AppTab = .home

    var homePath = NavigationPath()
    var explorePath = NavigationPath()
    var notificationsPath = NavigationPath()
    var profilePath = NavigationPath()
}
