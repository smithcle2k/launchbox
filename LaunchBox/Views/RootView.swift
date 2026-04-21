//
//  RootView.swift
//  LaunchBox
//

import SwiftData
import SwiftUI

struct RootView: View {
    @State private var router = AppRouter()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            Tab(String(localized: "Chores"), systemImage: "arrow.triangle.2.circlepath", value: AppTab.chores) {
                NavigationStack(path: $router.choresPath) {
                    ChoresView(router: router)
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .choreDetail(let id):
                                ChoreDetailView(choreID: id, router: router)
                            case .addChore:
                                AddChoreView(router: router)
                            case .history:
                                HistoryView(router: router)
                            case .editMember(_):
                                EmptyView()
                            }
                        }
                }
            }

            Tab(String(localized: "Settings"), systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack(path: $router.settingsPath) {
                    SettingsView(router: router)
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .choreDetail(_), .addChore, .history:
                                EmptyView()
                            case .editMember(let id):
                                EditMemberView(memberID: id, router: router)
                            }
                        }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .onChange(of: scenePhase) { _, new in
            guard new == .active else { return }
            Task { await WhoseTurnIntentDonation.refreshOnForeground() }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(
            for: [Household.self, Member.self, Chore.self, ChoreLog.self],
            inMemory: true
        )
}
