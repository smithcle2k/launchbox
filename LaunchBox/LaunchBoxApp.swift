//
//  LaunchBoxApp.swift
//  LaunchBox
//

import SwiftData
import SwiftUI

@main
struct LaunchBoxApp: App {
    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AppItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        OneSignalService.configure(launchOptions: nil)
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
