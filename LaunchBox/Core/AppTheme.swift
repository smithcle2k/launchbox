//
//  AppTheme.swift
//  LaunchBox
//

import SwiftUI

/// Semantic design tokens (HIG: consistency, no magic numbers in views).
enum AppTheme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let button: CGFloat = 10
        static let card: CGFloat = 12
    }

    /// Standard list row / control minimum (HIG: 44x44 pt touch targets).
    enum HitTarget {
        static let minimum: CGFloat = 44
    }

    enum Shadow {
        static let cardRadius: CGFloat = 4
        static let cardYOffset: CGFloat = 2
        static let cardOpacity: Double = 0.08
    }

    /// Large decorative SF Symbol sizes (splash / onboarding hero art).
    enum IconSize {
        static let splash: CGFloat = 56
        static let onboardingHero: CGFloat = 56
    }
}
