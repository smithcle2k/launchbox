//
//  AppStorageKeys.swift
//  LaunchBox
//

import Foundation

enum AppStorageKeys {
    /// Local chore reminder notifications (no remote push).
    static let choreRemindersEnabled = "whosTurnChoreRemindersEnabled"

    /// When a housemate completes a chore, show a one-shot local alert after CloudKit remote notification + merge. Default is on in UI.
    static let notifyHousemateCompletions = "whosTurnNotifyHousemateCompletions"

    /// Which `Household.id` the UI syncs to (multi-household).
    static let activeHouseholdID = "whosTurnActiveHouseholdID"

    /// Which `Member.id` is the person using this device (optional).
    static let myMemberID = "whosTurnMyMemberID"

    /// `HouseholdCloudKitStore.SharingRole` raw value.
    static let cloudSharingRole = "whosTurnCloudSharingRole"

    /// Household UUID string this device syncs through CloudKit (root record).
    static let cloudSyncedHouseholdID = "whosTurnCloudSyncedHouseholdID"

    static let cloudZoneName = "whosTurnCloudZoneName"
    static let cloudZoneOwnerName = "whosTurnCloudZoneOwnerName"
}
