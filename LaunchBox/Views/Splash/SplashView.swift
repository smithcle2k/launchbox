//
//  SplashView.swift
//  LaunchBox
//

import SwiftUI

struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var opacity: Double = 0

    var onFinished: () -> Void

    var body: some View {
        ZStack {
            Color.accentColor
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: AppTheme.IconSize.splash, weight: .medium))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)

                Text("LaunchBox")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
            }
            .opacity(opacity)
        }
        .onAppear {
            if reduceMotion {
                opacity = 1
            } else {
                withAnimation(.easeIn(duration: 0.45)) {
                    opacity = 1
                }
            }
        }
        .task {
            let nanoseconds: UInt64 = 1_200_000_000
            try? await Task.sleep(nanoseconds: nanoseconds)
            onFinished()
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}
