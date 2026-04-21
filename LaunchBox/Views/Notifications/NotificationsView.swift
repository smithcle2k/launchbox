//
//  NotificationsView.swift
//  LaunchBox
//

import SwiftUI

struct NotificationsView: View {
    var body: some View {
        List {
            Section {
                Label(String(localized: "All caught up"), systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
            } header: {
                Text(String(localized: "Today"))
                    .sectionHeader()
            }

            Section {
                notificationRow(
                    title: String(localized: "Sample notification"),
                    subtitle: String(localized: "Replace with your push or in-app feed."),
                    systemImage: "bell.badge"
                )
                notificationRow(
                    title: String(localized: "Design tip"),
                    subtitle: String(localized: "Keep list rows readable at large Dynamic Type sizes."),
                    systemImage: "textformat.size"
                )
            } header: {
                Text(String(localized: "Recent"))
                    .sectionHeader()
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(String(localized: "Notifications"))
    }

    private func notificationRow(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Image(systemName: systemImage)
                .foregroundStyle(.tint)
                .frame(width: AppTheme.HitTarget.minimum, height: AppTheme.HitTarget.minimum)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
    }
}
