//
//  LottieView.swift
//  LaunchBox
//
//  Add `lottie-ios` via SPM (see project). Drop JSON into the app target.
//  If Lottie isn’t linked, a system symbol placeholder is shown.
//

import SwiftUI

#if canImport(Lottie)
import Lottie
import UIKit

struct LottieView: UIViewRepresentable {
    var name: String
    var loopMode: LottieLoopMode = .loop

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView()
        view.contentMode = .scaleAspectFit
        view.loopMode = loopMode
        if let animation = LottieAnimation.named(name, bundle: .main) {
            view.animation = animation
            view.play()
        }
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        if uiView.animation == nil, let animation = LottieAnimation.named(name, bundle: .main) {
            uiView.animation = animation
            uiView.play()
        }
    }
}

#else

struct LottieView: View {
    var name: String

    var body: some View {
        Image(systemName: "sparkles")
            .font(.largeTitle)
            .foregroundStyle(.secondary)
            .accessibilityLabel(Text(String(localized: "Animation placeholder")))
    }
}

#endif
