//
//  RootView.swift
//  LaunchBox
//

import SwiftData
import SwiftUI

struct RootView: View {
    @State private var router = AppRouter()

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                NavigationStack(path: $router.homePath) {
                    HomeView(router: router)
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .itemDetail(let id):
                                HomeDetailView(itemID: id)
                            case .settings:
                                SettingsView()
                            }
                        }
                }
            }

            Tab("Explore", systemImage: "magnifyingglass", value: AppTab.explore) {
                NavigationStack(path: $router.explorePath) {
                    ExploreView(router: router)
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .itemDetail(let id):
                                HomeDetailView(itemID: id)
                            case .settings:
                                SettingsView()
                            }
                        }
                }
            }

            Tab("Notifications", systemImage: "bell", value: AppTab.notifications) {
                NavigationStack(path: $router.notificationsPath) {
                    NotificationsView()
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .itemDetail(let id):
                                HomeDetailView(itemID: id)
                            case .settings:
                                SettingsView()
                            }
                        }
                }
            }

            Tab("Profile", systemImage: "person.crop.circle", value: AppTab.profile) {
                NavigationStack(path: $router.profilePath) {
                    ProfileView(router: router)
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .itemDetail(let id):
                                HomeDetailView(itemID: id)
                            case .settings:
                                SettingsView()
                            }
                        }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    RootView()
        .modelContainer(for: AppItem.self, inMemory: true)
}
