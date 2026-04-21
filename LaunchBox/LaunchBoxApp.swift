//
//  LaunchBoxApp.swift
//  LaunchBox
//

import SwiftData
import SwiftUI

@main
struct LaunchBoxApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue

    /// Local-only SwiftData store. Multi-user sync uses `HouseholdCloudKitStore` (SwiftData cannot use CloudKit shared DB).
    private let sharedModelContainer: ModelContainer

    init() {
        let schema = Schema([
            Household.self,
            Member.self,
            Chore.self,
            ChoreLog.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            sharedModelContainer = container
            ModelContainerHolder.container = container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootAppView()
                .preferredColorScheme(resolvedColorScheme)
        }
        .modelContainer(sharedModelContainer)
    }

    private var resolvedColorScheme: ColorScheme? {
        AppearanceMode(rawValue: appearanceRaw)?.colorScheme
    }
}
