//
//  AppDelegate.swift
//  LaunchBox
//

import CloudKit
import SwiftData
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        guard CKNotification(fromRemoteNotificationDictionary: userInfo) != nil else {
            completionHandler(.noData)
            return
        }
        Task { @MainActor in
            guard let context = ModelContainerHolder.container?.mainContext else {
                completionHandler(.noData)
                return
            }
            try? await HouseholdCloudKitStore.shared.pullCloudAndMerge(context: context)
            completionHandler(.newData)
        }
    }

    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith metadata: CKShare.Metadata) {
        Task { @MainActor in
            await HouseholdCloudKitStore.shared.handleUserAcceptedShare(metadata: metadata)
        }
    }
}
