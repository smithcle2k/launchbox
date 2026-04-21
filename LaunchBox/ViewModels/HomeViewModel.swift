//
//  HomeViewModel.swift
//  LaunchBox
//

import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class HomeViewModel {
    var items: [AppItem] = []
    /// Starts true to avoid an empty-state flash before the first load completes.
    var isLoading = true
    var errorMessage: String?

    func load(context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var descriptor = FetchDescriptor<AppItem>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            descriptor.fetchLimit = 200
            items = try context.fetch(descriptor)
        } catch {
            errorMessage = error.localizedDescription
            items = []
        }
    }

    func addSampleItem(context: ModelContext) {
        let item = AppItem(
            title: String(localized: "New Item"),
            subtitle: String(localized: "Tap to edit details")
        )
        context.insert(item)
        items.insert(item, at: 0)
    }

    func delete(at offsets: IndexSet, context: ModelContext) {
        for index in offsets {
            let item = items[index]
            context.delete(item)
        }
        items.remove(atOffsets: offsets)
    }

    func toggleFavorite(_ item: AppItem, context: ModelContext) {
        item.isFavorite.toggle()
        try? context.save()
    }

    /// Seeds two sample rows on first launch so the boilerplate isn’t empty.
    func seedIfEmpty(context: ModelContext) async {
        guard items.isEmpty else { return }
        let samples: [AppItem] = [
            AppItem(
                title: String(localized: "Welcome"),
                subtitle: String(localized: "Add items from the toolbar.")
            ),
            AppItem(
                title: String(localized: "Explore"),
                subtitle: String(localized: "Use search to find content fast.")
            ),
        ]
        for item in samples {
            context.insert(item)
        }
        await load(context: context)
    }
}
