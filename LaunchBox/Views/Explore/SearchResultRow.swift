//
//  SearchResultRow.swift
//  LaunchBox
//

import SwiftData
import SwiftUI

struct SearchResultRow: View {
    let item: AppItem

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.md) {
            Image(systemName: "doc.text")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(item.title)
                    .font(.body)
                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: AppTheme.Spacing.sm)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityHint(String(localized: "Opens details"))
    }
}

#Preview {
    List {
        SearchResultRow(
            item: AppItem(
                title: "Sample",
                subtitle: "Subtitle"
            )
        )
    }
    .modelContainer(for: AppItem.self, inMemory: true)
}
