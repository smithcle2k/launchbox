//
//  ProfileView.swift
//  LaunchBox
//

import SwiftUI

struct ProfileView: View {
    @Bindable var router: AppRouter

    var body: some View {
        List {
            Section {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(String(localized: "Your Name"))
                            .font(.title3.weight(.semibold))
                        Text(String(localized: "you@example.com"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.sm)
            }

            Section {
                Button {
                    router.profilePath.append(AppRoute.settings)
                } label: {
                    Label(String(localized: "Settings"), systemImage: "gearshape")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .minTapTarget()
                .accessibilityHint(String(localized: "Opens settings"))

                Button {
                    router.selectedTab = .home
                } label: {
                    Label(String(localized: "Go to Home Tab"), systemImage: "house")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .minTapTarget()
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(String(localized: "Profile"))
    }
}

#Preview {
    NavigationStack {
        ProfileView(router: AppRouter())
    }
}
