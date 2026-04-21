//
//  RootAppView.swift
//  LaunchBox
//

import SwiftData
import SwiftUI

/// Gates the main `TabView` shell behind splash and first-run onboarding.
struct RootAppView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var phase: AppPhase = .splash
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage(AppStorageKeys.myMemberID) private var myMemberIDRaw = ""
    @State private var showMyMemberPick = false

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
                    seedSampleMembersIfNeeded()
                    hasCompletedOnboarding = true
                    withAnimation(.easeInOut(duration: 0.35)) {
                        phase = .main
                    }
                }
                .transition(.opacity)

            case .main:
                RootView()
                    .transition(.opacity)
                    .task {
                        try? await HouseholdCloudKitStore.shared.pullCloudAndMerge(context: modelContext)
                        evaluateMyMemberPrompt()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .whosTurnCloudDataDidChange)) { _ in
                        Task { @MainActor in
                            try? await HouseholdCloudKitStore.shared.pullCloudAndMerge(context: modelContext)
                            evaluateMyMemberPrompt()
                        }
                    }
                    .sheet(isPresented: $showMyMemberPick) {
                        NavigationStack {
                            MyMemberPickSheet(isPresented: $showMyMemberPick)
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: phase)
    }

    private func evaluateMyMemberPrompt() {
        guard hasCompletedOnboarding else { return }
        guard myMemberIDRaw.isEmpty else { return }
        do {
            let home = try PersistenceBootstrap.ensureHousehold(context: modelContext)
            if (home.members ?? []).count >= 2 {
                showMyMemberPick = true
            }
        } catch {}
    }

    private func seedSampleMembersIfNeeded() {
        do {
            let home = try PersistenceBootstrap.ensureHousehold(context: modelContext)
            if let existing = home.members, !existing.isEmpty { return }

            let alex = Member(
                name: String(localized: "Alex"),
                colorHex: MemberPalette.color(at: 0),
                sortIndex: 0,
                household: home
            )
            let sam = Member(
                name: String(localized: "Sam"),
                colorHex: MemberPalette.color(at: 1),
                sortIndex: 1,
                household: home
            )
            modelContext.insert(alex)
            modelContext.insert(sam)
            try modelContext.save()
        } catch {
            // Local-only app: no remote logging.
        }
    }
}

#Preview {
    RootAppView()
        .modelContainer(
            for: [Household.self, Member.self, Chore.self, ChoreLog.self],
            inMemory: true
        )
}
