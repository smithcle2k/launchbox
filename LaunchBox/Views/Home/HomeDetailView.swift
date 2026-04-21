//
//  HomeDetailView.swift
//  LaunchBox
//

import SwiftData
import SwiftUI

struct HomeDetailView: View {
    let itemID: UUID

    @Environment(\.modelContext) private var modelContext
    @Query private var matches: [AppItem]

    init(itemID: UUID) {
        self.itemID = itemID
        let uid = itemID
        _matches = Query(filter: #Predicate<AppItem> { $0.id == uid })
    }

    var body: some View {
        Group {
            if let item = matches.first {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text(item.title)
                            .font(.title)
                            .foregroundStyle(.primary)

                        Text(item.subtitle)
                            .font(.body)
                            .foregroundStyle(.secondary)

                        Text(item.createdAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)

                        Toggle(isOn: favoriteBinding(for: item)) {
                            Label(String(localized: "Favorite"), systemImage: "star")
                        }
                        .padding(AppTheme.Spacing.md)
                        .cardStyle()
                    }
                    .padding(AppTheme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(.systemGroupedBackground))
            } else {
                ContentUnavailableView(
                    String(localized: "Missing Item"),
                    systemImage: "exclamationmark.triangle",
                    description: Text(String(localized: "This item may have been deleted."))
                )
            }
        }
        .navigationTitle(String(localized: "Details"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func favoriteBinding(for item: AppItem) -> Binding<Bool> {
        Binding(
            get: { item.isFavorite },
            set: { newValue in
                item.isFavorite = newValue
                try? modelContext.save()
            }
        )
    }
}

#Preview {
    NavigationStack {
        HomeDetailView(itemID: UUID())
    }
    .modelContainer(for: AppItem.self, inMemory: true)
}
