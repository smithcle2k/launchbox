//
//  OneSignalService.swift
//  LaunchBox
//
//  Setup (when you are ready for push):
//  1. In Xcode: File > Add Package Dependencies…
//     URL: https://github.com/OneSignal/OneSignal-iOS-SDK
//  2. Add the Swift/SPM product your SDK version documents (often `OneSignalFramework` or `OneSignal`) to the LaunchBox target.
//  3. Signing & Capabilities: enable Push Notifications and Background Modes → Remote notifications.
//  4. Copy `Resources/Secrets.sample.plist` to `Secrets.plist` and set `ONE_SIGNAL_APP_ID`.
//  5. Wire `configure(launchOptions:)` from `UIApplicationDelegate` if you need launch options, or keep calling from `LaunchBoxApp.init()`.
//

import Foundation
import UIKit

#if canImport(OneSignalFramework)
import OneSignalFramework
#endif

enum OneSignalService {
    /// Call once at launch (see also `LaunchBoxApp.init()`).
    static func configure(launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) {
        #if canImport(OneSignalFramework)
        let appId = Secrets.oneSignalAppID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !appId.isEmpty, appId != "YOUR_ONESIGNAL_APP_ID" else {
            assertionFailure("Set ONE_SIGNAL_APP_ID in Secrets.plist (copy from Secrets.sample.plist).")
            return
        }
        // OneSignal iOS SDK v5+ (verify against your installed version’s headers):
        OneSignal.initialize(appId, withLaunchOptions: launchOptions)
        #else
        #if DEBUG
        print("OneSignalService: add OneSignal-iOS-SDK via SPM to enable push.")
        #endif
        #endif
    }

    /// Request notification permission when you are ready (e.g. after onboarding).
    static func requestPermission() async -> Bool {
        #if canImport(OneSignalFramework)
        await withCheckedContinuation { continuation in
            OneSignal.Notifications.requestPermission({ accepted in
                continuation.resume(returning: accepted)
            }, fallbackToSettings: true)
        }
        #else
        false
        #endif
    }

    static func setExternalUserId(_ id: String?) {
        #if canImport(OneSignalFramework)
        if let id {
            OneSignal.login(id)
        } else {
            OneSignal.logout()
        }
        #endif
    }
}
