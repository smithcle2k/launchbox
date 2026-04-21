//
//  RootAppView.swift
//  LaunchBox
//

import SwiftData
import SwiftUI

/// Gates the main `TabView` shell behind splash and first-run onboarding.
struct RootAppView: View {
    @State private var phase: AppPhase = .splash
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            switch phase {
            case .splash:
                SplashView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        phase = hasCompletedOnboarding ? .main : .onboarding
                    }
                }
                .transition(.opacity)

            case .onboarding:
                OnboardingContainer(
                    mode: .walkthrough(OnboardingPage.defaultWalkthrough)
                ) {
                    hasCompletedOnboarding = true
                    withAnimation(.easeInOut(duration: 0.35)) {
                        phase = .main
                    }
                }
                .transition(.opacity)

            case .main:
                RootView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: phase)
    }
}

#Preview {
    RootAppView()
        .modelContainer(for: AppItem.self, inMemory: true)
}
