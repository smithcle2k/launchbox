//
//  ExploreViewModel.swift
//  LaunchBox
//

import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class ExploreViewModel {
    var query: String = ""
    var results: [AppItem] = []
    var isSearching = false

    private var searchTask: Task<Void, Never>?

    func performSearch(context: ModelContext) async {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 320_000_000)
            guard !Task.isCancelled else { return }
            await runQuery(trimmed, context: context)
        }
    }

    private func runQuery(_ trimmed: String, context: ModelContext) async {
        isSearching = true
        defer { isSearching = false }

        do {
            var descriptor = FetchDescriptor<AppItem>(
                sortBy: [SortDescriptor(\.title, order: .forward)]
            )
            descriptor.fetchLimit = 200
            let fetched = try context.fetch(descriptor)
            if trimmed.isEmpty {
                results = Array(fetched.prefix(100))
            } else {
                results = fetched.filter { item in
                    item.title.localizedStandardContains(trimmed)
                        || item.subtitle.localizedStandardContains(trimmed)
                }
            }
        } catch {
            results = []
        }
    }
}
