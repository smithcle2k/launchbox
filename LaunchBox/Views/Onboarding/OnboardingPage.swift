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
            id: "welcome",
            title: "Welcome",
            subtitle: "Your universal SwiftUI shell—tabs, navigation, and data ready to extend.",
            systemImage: "sparkles"
        ),
        OnboardingPage(
            id: "organize",
            title: "Stay organized",
            subtitle: "Use Home for your content and Explore to search across everything.",
            systemImage: "square.grid.2x2"
        ),
        OnboardingPage(
            id: "you",
            title: "Make it yours",
            subtitle: "Adjust settings, appearance, and notifications anytime in Profile.",
            systemImage: "person.crop.circle"
        ),
    ]
}
