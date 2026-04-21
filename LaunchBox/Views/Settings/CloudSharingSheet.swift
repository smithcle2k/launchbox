//
//  CloudSharingSheet.swift
//  LaunchBox
//

import CloudKit
import SwiftData
import SwiftUI
import UIKit

struct CloudSharingSheet: UIViewControllerRepresentable {
    let household: Household
    @Binding var isPresented: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController { _, completion in
            Task { @MainActor in
                do {
                    guard let ctx = ModelContainerHolder.container?.mainContext else {
                        completion(nil, nil, CloudKitSyncError.missingModelContainer)
                        return
                    }
                    let share = try await HouseholdCloudKitStore.shared.ensureShare(for: household, context: ctx)
                    completion(share, HouseholdCloudKitStore.shared.container, nil)
                } catch {
                    completion(nil, nil, error)
                }
            }
        }
        controller.availablePermissions = [.allowReadWrite]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        @Binding var isPresented: Bool

        init(isPresented: Binding<Bool>) {
            _isPresented = isPresented
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            isPresented = false
        }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            isPresented = false
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            String(localized: "Household")
        }
    }
}
