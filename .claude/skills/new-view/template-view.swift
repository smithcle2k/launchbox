//
//  __FEATURE__View.swift
//  LaunchBox
//

import SwiftUI

struct __FEATURE__View: View {
    @Bindable var router: AppRouter

    var body: some View {
        ContentUnavailableView {
            Label(
                String(localized: "__FEATURE__"),
                systemImage: "square.grid.2x2"
            )
        } description: {
            Text(String(localized: "Description for __FEATURE__."))
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.md)
        .navigationTitle(String(localized: "__FEATURE__"))
    }
}

#Preview {
    NavigationStack {
        __FEATURE__View(router: AppRouter())
    }
}
