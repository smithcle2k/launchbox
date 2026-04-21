//
//  OnboardingPage.swift
//  LaunchBox
//

import SwiftUI

struct OnboardingPage: Identifiable, Hashable {
    let id: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let systemImage: String?
    /// Name of a Lottie JSON in the app bundle (without extension). If nil, `systemImage` is shown.
    let lottieName: String?

    init(
        id: String,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        systemImage: String? = nil,
        lottieName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.lottieName = lottieName
    }

    static func == (lhs: OnboardingPage, rhs: OnboardingPage) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension OnboardingPage {
    static let defaultWalkthrough: [OnboardingPage] = [
        OnboardingPage(
            id: "people",
            title: "Add your people",
            subtitle: "Everyone who shares chores—roommates, partner, or kids. You can edit names anytime in Settings.",
            systemImage: "person.2.fill"
        ),
        OnboardingPage(
            id: "chores",
            title: "Add chores",
            subtitle: "Create a chore, pick who rotates, and tap Done when it’s finished. We’ll move to the next person automatically.",
            systemImage: "checklist"
        ),
        OnboardingPage(
            id: "privacy",
            title: "On your device only",
            subtitle: "No accounts, no tracking, no cloud. Your household list stays on this iPhone or iPad.",
            systemImage: "lock.fill"
        ),
    ]
}
