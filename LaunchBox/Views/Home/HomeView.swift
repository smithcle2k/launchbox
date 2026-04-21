//
//  HomeView.swift
//  LaunchBox
//

import SwiftData
import SwiftUI

struct HomeView: View {
    @Bindable var router: AppRouter
    @Environment(\.modelContext) private var modelContext
    @State private var homeVM = HomeViewModel()

    var body: some View {
        Group {
            if homeVM.items.isEmpty && !homeVM.isLoading {
                ContentUnavailableView {
                    Label(
                        String(localized: "Nothing Here Yet"),
                        systemImage: "tray"
                    )
                } description: {
                    Text(String(localized: "Add your first item to get started."))
                        .multilineTextAlignment(.center)
                } actions: {
                    Button(String(localized: "Add Item")) {
                        homeVM.addSampleItem(context: modelContext)
                        try? modelContext.save()
                    }
                    .buttonStyle(.borderedProminent)
                    .minTapTarget()
                }
                .padding(AppTheme.Spacing.md)
            } else {
                List {
                    ForEach(homeVM.items, id: \.id) { item in
                        Button {
                            router.homePath.append(AppRoute.itemDetail(item.id))
                        } label: {
                            HomeRowContent(item: item)
                        }
                        .buttonStyle(.plain)
                        .minTapTarget()
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(String(localized: "Delete"), role: .destructive) {
                                if let index = homeVM.items.firstIndex(where: { $0.id == item.id }) {
                                    homeVM.delete(at: IndexSet(integer: index), context: modelContext)
                                    try? modelContext.save()
                                }
                            }

                            Button {
                                homeVM.toggleFavorite(item, context: modelContext)
                            } label: {
                                Label(
                                    String(localized: "Favorite"),
                                    systemImage: item.isFavorite ? "star.slash" : "star"
                                )
                            }
                            .tint(.orange)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle(String(localized: "Home"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    homeVM.addSampleItem(context: modelContext)
                    try? modelContext.save()
                } label: {
                    Label(String(localized: "Add Item"), systemImage: "plus.circle.fill")
                }
                .accessibilityLabel(String(localized: "Add Item"))
                .minTapTarget()
            }
        }
        .overlay {
            if homeVM.isLoading {
                ProgressView()
                    .padding(AppTheme.Spacing.lg)
            }
        }
        .task {
            await homeVM.load(context: modelContext)
            await homeVM.seedIfEmpty(context: modelContext)
            try? modelContext.save()
        }
        .alert(
            String(localized: "Couldn’t Load Data"),
            isPresented: Binding(
                get: { homeVM.errorMessage != nil },
                set: { if !$0 { homeVM.errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {
                homeVM.errorMessage = nil
            }
        } message: {
            if let message = homeVM.errorMessage {
                Text(message)
            }
        }
    }
}

private struct HomeRowContent: View {
    let item: AppItem

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.md) {
            Image(systemName: item.isFavorite ? "star.fill" : "circle.fill")
                .foregroundStyle(item.isFavorite ? .orange : .secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(item.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: AppTheme.Spacing.sm)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        HomeView(router: AppRouter())
    }
    .modelContainer(for: AppItem.self, inMemory: true)
}
