//
//  OnboardingContainer.swift
//  LaunchBox
//

import SwiftUI

struct OnboardingContainer: View {
    enum Mode {
        case single(OnboardingPage)
        case walkthrough([OnboardingPage])
    }

    let mode: Mode
    var onFinished: () -> Void

    @State private var walkthroughIndex: Int = 0

    var body: some View {
        switch mode {
        case .single(let page):
            singleScreen(page)

        case .walkthrough(let pages):
            walkthrough(pages)
        }
    }

    private func singleScreen(_ page: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: AppTheme.Spacing.xl)

            pageContent(page, maxWidth: 600)
                .padding(.horizontal, AppTheme.Spacing.md)

            Spacer()

            Button(String(localized: "Get Started")) {
                HapticManager.impact(.medium)
                onFinished()
            }
            .buttonStyle(.borderedProminent)
            .minTapTarget()
            .padding(AppTheme.Spacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .top) {
            topBar(showSkip: false)
        }
    }

    private func walkthrough(_ pages: [OnboardingPage]) -> some View {
        VStack(spacing: 0) {
            TabView(selection: $walkthroughIndex) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    ScrollView {
                        pageContent(page, maxWidth: 600)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.top, AppTheme.Spacing.lg)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            bottomBar(pageCount: pages.count)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .top) {
            topBar(showSkip: true)
        }
    }

    private func topBar(showSkip: Bool) -> some View {
        HStack {
            Spacer()
            if showSkip {
                Button(String(localized: "Skip")) {
                    HapticManager.selection()
                    onFinished()
                }
                .minTapTarget()
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    private func bottomBar(pageCount: Int) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            if walkthroughIndex < pageCount - 1 {
                Button(String(localized: "Next")) {
                    HapticManager.selection()
                    withAnimation {
                        walkthroughIndex = min(walkthroughIndex + 1, pageCount - 1)
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .minTapTarget()
            } else {
                Button(String(localized: "Get Started")) {
                    HapticManager.impact(.medium)
                    onFinished()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .minTapTarget()
            }
        }
        .padding(AppTheme.Spacing.md)
    }

    @ViewBuilder
    private func pageContent(_ page: OnboardingPage, maxWidth: CGFloat) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            visual(for: page)
            textBlock(for: page)
        }
        .frame(maxWidth: maxWidth)
    }

    private func visual(for page: OnboardingPage) -> some View {
        Group {
            if let lottie = page.lottieName, !lottie.isEmpty {
                LottieView(name: lottie)
                    .frame(height: 220)
                    .accessibilityHidden(true)
            } else if let symbol = page.systemImage {
                Image(systemName: symbol)
                    .font(.system(size: AppTheme.IconSize.onboardingHero, weight: .medium))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func textBlock(for page: OnboardingPage) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(page.title)
                .font(.title.weight(.bold))
                .multilineTextAlignment(.leading)
            Text(page.subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Walkthrough") {
    OnboardingContainer(mode: .walkthrough(OnboardingPage.defaultWalkthrough)) {}
}

#Preview("Single") {
    OnboardingContainer(
        mode: .single(
            OnboardingPage(
                id: "one",
                title: "Hello",
                subtitle: "Single-screen welcome mode.",
                systemImage: "hand.wave"
            )
        )
    ) {}
}
