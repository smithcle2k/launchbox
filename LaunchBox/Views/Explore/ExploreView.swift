//
//  ExploreView.swift
//  LaunchBox
//

import SwiftData
import SwiftUI

struct ExploreView: View {
    @Bindable var router: AppRouter
    @Environment(\.modelContext) private var modelContext
    @State private var exploreVM = ExploreViewModel()

    var body: some View {
        Group {
            if exploreVM.results.isEmpty {
                if exploreVM.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ContentUnavailableView(
                        String(localized: "Nothing to Explore"),
                        systemImage: "tray",
                        description: Text(
                            String(localized: "Create items on the Home tab, then search here.")
                        )
                    )
                } else {
                    ContentUnavailableView(
                        String(localized: "No Matches"),
                        systemImage: "magnifyingglass",
                        description: Text(String(localized: "Try a different search term."))
                    )
                }
            } else {
                List {
                    ForEach(exploreVM.results, id: \.id) { item in
                        Button {
                            router.explorePath.append(AppRoute.itemDetail(item.id))
                        } label: {
                            SearchResultRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .minTapTarget()
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle(String(localized: "Explore"))
        .searchable(
            text: $exploreVM.query,
            placement: .automatic,
            prompt: Text(String(localized: "Search items"))
        )
        .overlay {
            if exploreVM.isSearching {
                ProgressView()
                    .padding(AppTheme.Spacing.lg)
            }
        }
        .task {
            await exploreVM.performSearch(context: modelContext)
        }
        .onChange(of: exploreVM.query) { _, _ in
            Task {
                await exploreVM.performSearch(context: modelContext)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExploreView(router: AppRouter())
    }
    .modelContainer(for: AppItem.self, inMemory: true)
}
