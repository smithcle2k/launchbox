//
//  HouseholdCloudKitStore.swift
//  LaunchBox
//
//  SwiftData does not support CloudKit shared DB / CKShare. This store mirrors the household
//  graph to custom CKRecords in a dedicated zone and uses CKShare for multi-user access.

import CloudKit
import Foundation
import SwiftData
import UIKit

enum CloudKitSyncError: LocalizedError {
    case iCloudUnavailable
    case missingRootRecord
    case missingModelContainer

    var errorDescription: String? {
        switch self {
        case .iCloudUnavailable:
            String(localized: "Sign in to iCloud to share or sync your household.")
        case .missingRootRecord:
            String(localized: "Couldn’t read the shared household from iCloud.")
        case .missingModelContainer:
            String(localized: "The app isn’t ready yet. Try again in a moment.")
        }
    }
}

private enum CloudRecordType: String {
    case household = "WT_Household"
    case member = "WT_Member"
    case chore = "WT_Chore"
    case choreLog = "WT_ChoreLog"
}

@MainActor
final class HouseholdCloudKitStore {
    static let shared = HouseholdCloudKitStore()

    let container = CKContainer(identifier: CloudKitConstants.containerIdentifier)

    enum SharingRole: String {
        case none
        case owner
        case participant
    }

    private var debounceTask: Task<Void, Never>?

    private init() {}

    var sharingRole: SharingRole {
        get {
            let raw = UserDefaults.standard.string(forKey: AppStorageKeys.cloudSharingRole) ?? SharingRole.none.rawValue
            return SharingRole(rawValue: raw) ?? .none
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: AppStorageKeys.cloudSharingRole)
        }
    }

    private func persistedZoneID() -> CKRecordZone.ID? {
        guard let zn = UserDefaults.standard.string(forKey: AppStorageKeys.cloudZoneName),
              let on = UserDefaults.standard.string(forKey: AppStorageKeys.cloudZoneOwnerName)
        else { return nil }
        return CKRecordZone.ID(zoneName: zn, ownerName: on)
    }

    private func persistZone(_ zoneID: CKRecordZone.ID) {
        UserDefaults.standard.set(zoneID.zoneName, forKey: AppStorageKeys.cloudZoneName)
        UserDefaults.standard.set(zoneID.ownerName, forKey: AppStorageKeys.cloudZoneOwnerName)
    }

    private func databaseForSync() -> CKDatabase {
        sharingRole == .participant ? container.sharedCloudDatabase : container.privateCloudDatabase
    }

    private static func zoneID(for householdUUID: UUID) -> CKRecordZone.ID {
        CKRecordZone.ID(zoneName: "whos-turn-\(householdUUID.uuidString.lowercased())", ownerName: CKCurrentUserDefaultName)
    }

    // MARK: - Public entry points

    func scheduleSync(context: ModelContext) {
        guard sharingRole != .none, persistedZoneID() != nil else { return }
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            await pushLocalThenPull(context: context)
        }
    }

    func handleUserAcceptedShare(metadata: CKShare.Metadata) async {
        do {
            try await accept(metadata: metadata)
            guard let context = ModelContainerHolder.container?.mainContext else {
                throw CloudKitSyncError.missingModelContainer
            }
            let zoneID = metadata.share.recordID.zoneID
            persistZone(zoneID)
            sharingRole = .participant
            let root = metadata.rootRecordID
            if let uuid = UUID(uuidString: root.recordName) {
                UserDefaults.standard.set(uuid.uuidString, forKey: AppStorageKeys.cloudSyncedHouseholdID)
            }
            try await pullCloudAndMerge(context: context)
            if let s = UserDefaults.standard.string(forKey: AppStorageKeys.cloudSyncedHouseholdID),
               let id = UUID(uuidString: s) {
                PersistenceBootstrap.setActiveHouseholdID(id)
            }
            await registerChoreLogPushSubscriptionIfNeeded()
        } catch {
            NotificationCenter.default.post(name: .whosTurnCloudDataDidChange, object: nil)
        }
    }

    func ensureShare(for household: Household, context: ModelContext) async throws -> CKShare {
        let status = try await container.accountStatus()
        guard status == .available else { throw CloudKitSyncError.iCloudUnavailable }

        let zoneID = Self.zoneID(for: household.id)
        let db = container.privateCloudDatabase
        try await saveZone(CKRecordZone(zoneID: zoneID), database: db)
        try await pushAllRecords(for: household, zoneID: zoneID, database: db, context: context)

        if let existing = try await fetchExistingShare(zoneID: zoneID, database: db) {
            sharingRole = .owner
            persistZone(zoneID)
            UserDefaults.standard.set(household.id.uuidString, forKey: AppStorageKeys.cloudSyncedHouseholdID)
            await registerChoreLogPushSubscriptionIfNeeded()
            return existing
        }

        let rootID = CKRecord.ID(recordName: household.id.uuidString, zoneID: zoneID)
        let root = buildHouseholdRecord(household, recordID: rootID)
        let share = CKShare(rootRecord: root)
        share[CKShare.SystemFieldKey.title] = "Whose Turn?" as CKRecordValue
        share.publicPermission = .none
        try await modifyRecords(database: db, saving: [root, share], deleting: [])

        sharingRole = .owner
        persistZone(zoneID)
        UserDefaults.standard.set(household.id.uuidString, forKey: AppStorageKeys.cloudSyncedHouseholdID)
        await registerChoreLogPushSubscriptionIfNeeded()
        return share
    }

    func leaveSharedHousehold(context: ModelContext) throws {
        if let idString = UserDefaults.standard.string(forKey: AppStorageKeys.cloudSyncedHouseholdID) {
            if UserDefaults.standard.string(forKey: AppStorageKeys.activeHouseholdID) == idString {
                UserDefaults.standard.removeObject(forKey: AppStorageKeys.activeHouseholdID)
            }
            if let sharedID = UUID(uuidString: idString) {
                let sid = sharedID
                let d = FetchDescriptor<Household>(predicate: #Predicate<Household> { $0.id == sid })
                if let h = try context.fetch(d).first {
                    context.delete(h)
                }
            }
        }
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.cloudSharingRole)
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.cloudSyncedHouseholdID)
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.cloudZoneName)
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.cloudZoneOwnerName)
        _ = try PersistenceBootstrap.ensureHousehold(context: context)
        try context.save()
        NotificationCenter.default.post(name: .whosTurnCloudDataDidChange, object: nil)
    }

    func pullCloudAndMerge(context: ModelContext) async throws {
        guard sharingRole != .none, let zoneID = persistedZoneID() else { return }
        let beforeLogIDs: Set<UUID> = (try? Self.snapshotChoreLogIDs(in: context)) ?? []
        let hadLocalLogs = !beforeLogIDs.isEmpty
        let db = databaseForSync()
        let records = try await fetchAllRecords(zoneID: zoneID, database: db)
        try mergeRecords(records, into: context)
        try context.save()
        if hadLocalLogs {
            try await notifyIfHousemateCompletions(
                context: context,
                beforeLogIDs: beforeLogIDs
            )
        }
        NotificationCenter.default.post(name: .whosTurnCloudDataDidChange, object: nil)
    }

    // MARK: - Push subscription (ChoreLog inserts)

    /// Subscribes to new `WT_ChoreLog` records in the current zone so CloudKit can deliver silent pushes.
    func registerChoreLogPushSubscriptionIfNeeded() async {
        guard sharingRole != .none, let zoneID = persistedZoneID() else { return }
        let db = databaseForSync()
        let subID = "whoseturn-chorelog-v1-" + zoneID.zoneName
        let subscription = CKQuerySubscription(
            recordType: CloudRecordType.choreLog.rawValue,
            predicate: NSPredicate(value: true),
            subscriptionID: subID,
            options: .firesOnRecordCreation
        )
        subscription.zoneID = zoneID
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        do {
            try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
                let op = CKModifySubscriptionsOperation(
                    subscriptionsToSave: [subscription],
                    subscriptionIDsToDelete: nil
                )
                op.modifySubscriptionsResultBlock = { result in
                    switch result {
                    case .success:
                        c.resume()
                    case .failure(let err):
                        c.resume(throwing: err)
                    }
                }
                db.add(op)
            }
        } catch {
            // Duplicate subscription or transient CloudKit error — best-effort; sync still works without push.
        }
    }

    private static func snapshotChoreLogIDs(in context: ModelContext) throws -> Set<UUID> {
        let d = FetchDescriptor<ChoreLog>()
        let logs = try context.fetch(d)
        return Set(logs.map(\.id))
    }

    private func notifyIfHousemateCompletions(
        context: ModelContext,
        beforeLogIDs: Set<UUID>
    ) async throws {
        let enabled = UserDefaults.standard.object(forKey: AppStorageKeys.notifyHousemateCompletions) as? Bool ?? true
        guard enabled else { return }
        guard let myRaw = UserDefaults.standard.string(forKey: AppStorageKeys.myMemberID), !myRaw.isEmpty,
              let myMember = UUID(uuidString: myRaw) else { return }

        let d = FetchDescriptor<ChoreLog>()
        let all = try context.fetch(d)
        let newLogs = all.filter { !beforeLogIDs.contains($0.id) }
        for log in newLogs {
            guard log.memberID != myMember else { continue }
            let mid = log.memberID
            let mFetch = FetchDescriptor<Member>(predicate: #Predicate<Member> { $0.id == mid })
            let member = try context.fetch(mFetch).first
            let name = member?.name ?? String(localized: "Someone")
            let title = log.chore?.title ?? String(localized: "Chore")
            await NotificationScheduler.presentHousemateCompletionNotification(
                memberName: name,
                choreTitle: title,
                logID: log.id
            )
        }
    }

    // MARK: - CK operations

    private func accept(metadata: CKShare.Metadata) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let op = CKAcceptSharesOperation(shareMetadatas: [metadata])
            op.acceptSharesResultBlock = { result in
                switch result {
                case .success:
                    cont.resume()
                case .failure(let error):
                    cont.resume(throwing: error)
                }
            }
            container.add(op)
        }
    }

    private func saveZone(_ zone: CKRecordZone, database: CKDatabase) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let op = CKModifyRecordZonesOperation(recordZonesToSave: [zone])
            op.modifyRecordZonesResultBlock = { result in
                switch result {
                case .success:
                    cont.resume()
                case .failure(let error):
                    cont.resume(throwing: error)
                }
            }
            database.add(op)
        }
    }

    private func modifyRecords(database: CKDatabase, saving: [CKRecord], deleting: [CKRecord.ID]) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let op = CKModifyRecordsOperation(recordsToSave: saving, recordIDsToDelete: deleting)
            op.savePolicy = .changedKeys
            op.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    cont.resume()
                case .failure(let error):
                    cont.resume(throwing: error)
                }
            }
            database.add(op)
        }
    }

    private func fetchExistingShare(zoneID: CKRecordZone.ID, database: CKDatabase) async throws -> CKShare? {
        let query = CKQuery(recordType: "cloudkit.share", predicate: NSPredicate(value: true))
        let op = CKQueryOperation(query: query)
        op.zoneID = zoneID

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<CKShare?, Error>) in
            var found: CKShare?
            op.recordMatchedBlock = { (_: CKRecord.ID, result: Result<CKRecord, Error>) in
                if case .success(let record) = result, let share = record as? CKShare {
                    found = share
                }
            }
            op.queryResultBlock = { result in
                switch result {
                case .success:
                    cont.resume(returning: found)
                case .failure(let error):
                    cont.resume(throwing: error)
                }
            }
            database.add(op)
        }
    }

    private func fetchAllRecords(zoneID: CKRecordZone.ID, database: CKDatabase) async throws -> [CKRecord] {
        var all: [CKRecord] = []
        for type in [CloudRecordType.household, .member, .chore, .choreLog] {
            let query = CKQuery(recordType: type.rawValue, predicate: NSPredicate(value: true))
            let op = CKQueryOperation(query: query)
            op.zoneID = zoneID
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                op.recordMatchedBlock = { (_: CKRecord.ID, result: Result<CKRecord, Error>) in
                    if case .success(let record) = result {
                        all.append(record)
                    }
                }
                op.queryResultBlock = { result in
                    switch result {
                    case .success:
                        cont.resume()
                    case .failure(let error):
                        cont.resume(throwing: error)
                    }
                }
                database.add(op)
            }
        }
        return all
    }

    private func pushLocalThenPull(context: ModelContext) async {
        guard let idString = UserDefaults.standard.string(forKey: AppStorageKeys.cloudSyncedHouseholdID),
              let homeID = UUID(uuidString: idString),
              let zoneID = persistedZoneID()
        else { return }

        let uid = homeID
        let descriptor = FetchDescriptor<Household>(predicate: #Predicate<Household> { $0.id == uid })
        guard let household = try? context.fetch(descriptor).first else { return }
        let db = databaseForSync()
        do {
            try await pushAllRecords(for: household, zoneID: zoneID, database: db, context: context)
            try await pullCloudAndMerge(context: context)
        } catch {}
    }

    private func pushAllRecords(for household: Household, zoneID: CKRecordZone.ID, database: CKDatabase, context: ModelContext) async throws {
        var batch: [CKRecord] = []
        let rootID = CKRecord.ID(recordName: household.id.uuidString, zoneID: zoneID)
        batch.append(buildHouseholdRecord(household, recordID: rootID))
        for m in (household.members ?? []).sorted(by: { $0.sortIndex < $1.sortIndex }) {
            let id = CKRecord.ID(recordName: m.id.uuidString, zoneID: zoneID)
            batch.append(buildMemberRecord(m, recordID: id))
        }
        for c in household.chores ?? [] {
            let id = CKRecord.ID(recordName: c.id.uuidString, zoneID: zoneID)
            batch.append(buildChoreRecord(c, recordID: id))
            for l in c.logs ?? [] {
                let lid = CKRecord.ID(recordName: l.id.uuidString, zoneID: zoneID)
                batch.append(buildLogRecord(l, recordID: lid))
            }
        }
        try await modifyRecords(database: database, saving: batch, deleting: [])
    }

    // MARK: - CKRecord builders

    private func buildHouseholdRecord(_ h: Household, recordID: CKRecord.ID) -> CKRecord {
        let r = CKRecord(recordType: CloudRecordType.household.rawValue, recordID: recordID)
        r["name"] = h.name as CKRecordValue
        r["createdAt"] = h.createdAt as CKRecordValue
        r["modifiedAt"] = h.modifiedAt as CKRecordValue
        return r
    }

    private func buildMemberRecord(_ m: Member, recordID: CKRecord.ID) -> CKRecord {
        let r = CKRecord(recordType: CloudRecordType.member.rawValue, recordID: recordID)
        if let hid = m.household?.id.uuidString {
            r["householdID"] = hid as CKRecordValue
        }
        r["name"] = m.name as CKRecordValue
        r["colorHex"] = m.colorHex as CKRecordValue
        r["sortIndex"] = m.sortIndex as CKRecordValue
        r["modifiedAt"] = m.modifiedAt as CKRecordValue
        return r
    }

    private func buildChoreRecord(_ c: Chore, recordID: CKRecord.ID) -> CKRecord {
        let r = CKRecord(recordType: CloudRecordType.chore.rawValue, recordID: recordID)
        if let hid = c.household?.id.uuidString {
            r["householdID"] = hid as CKRecordValue
        }
        r["title"] = c.title as CKRecordValue
        r["notes"] = c.notes as CKRecordValue
        r["createdAt"] = c.createdAt as CKRecordValue
        if let last = c.lastCompletedAt {
            r["lastCompletedAt"] = last as CKRecordValue
        }
        if let aid = c.currentAssigneeID?.uuidString {
            r["currentAssigneeID"] = aid as CKRecordValue
        }
        r["cadenceJSON"] = c.cadenceJSON as CKRecordValue
        r["rotationOrderJSON"] = c.rotationOrderJSON as CKRecordValue
        r["modifiedAt"] = c.modifiedAt as CKRecordValue
        return r
    }

    private func buildLogRecord(_ l: ChoreLog, recordID: CKRecord.ID) -> CKRecord {
        let r = CKRecord(recordType: CloudRecordType.choreLog.rawValue, recordID: recordID)
        if let cid = l.chore?.id.uuidString {
            r["choreID"] = cid as CKRecordValue
        }
        r["memberID"] = l.memberID.uuidString as CKRecordValue
        r["completedAt"] = l.completedAt as CKRecordValue
        r["modifiedAt"] = l.modifiedAt as CKRecordValue
        return r
    }

    // MARK: - Merge

    private func mergeRecords(_ records: [CKRecord], into context: ModelContext) throws {
        let grouped = Dictionary(grouping: records, by: \.recordType)
        let households = grouped[CloudRecordType.household.rawValue] ?? []
        let members = grouped[CloudRecordType.member.rawValue] ?? []
        let chores = grouped[CloudRecordType.chore.rawValue] ?? []
        let logs = grouped[CloudRecordType.choreLog.rawValue] ?? []

        for rec in households {
            try mergeHousehold(rec, context: context)
        }
        for rec in members {
            try mergeMember(rec, context: context)
        }
        for rec in chores {
            try mergeChore(rec, context: context)
        }
        for rec in logs {
            try mergeLog(rec, context: context)
        }

        let choreDescriptor = FetchDescriptor<Chore>()
        let allChores = (try? context.fetch(choreDescriptor)) ?? []
        for c in allChores {
            c.recomputeAssigneeFromLogs()
        }
    }

    private func mergeHousehold(_ record: CKRecord, context: ModelContext) throws {
        guard let id = UUID(uuidString: record.recordID.recordName) else { return }
        let remoteMod = record["modifiedAt"] as? Date ?? .distantPast
        let uid = id
        let descriptor = FetchDescriptor<Household>(predicate: #Predicate<Household> { $0.id == uid })
        if let existing = try context.fetch(descriptor).first {
            guard remoteMod >= existing.modifiedAt else { return }
            existing.name = record["name"] as? String ?? existing.name
            existing.createdAt = record["createdAt"] as? Date ?? existing.createdAt
            existing.modifiedAt = remoteMod
        } else {
            let h = Household(
                id: id,
                name: record["name"] as? String ?? String(localized: "Home"),
                createdAt: record["createdAt"] as? Date ?? Date(),
                modifiedAt: remoteMod
            )
            context.insert(h)
        }
    }

    private func mergeMember(_ record: CKRecord, context: ModelContext) throws {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let householdIDString = record["householdID"] as? String,
              let householdID = UUID(uuidString: householdIDString)
        else { return }
        let remoteMod = record["modifiedAt"] as? Date ?? .distantPast

        let hid = householdID
        let homeDesc = FetchDescriptor<Household>(predicate: #Predicate<Household> { $0.id == hid })
        guard let home = try context.fetch(homeDesc).first else { return }

        let mid = id
        let descriptor = FetchDescriptor<Member>(predicate: #Predicate<Member> { $0.id == mid })
        if let existing = try context.fetch(descriptor).first {
            guard remoteMod >= existing.modifiedAt else { return }
            existing.name = record["name"] as? String ?? existing.name
            existing.colorHex = record["colorHex"] as? String ?? existing.colorHex
            existing.sortIndex = record["sortIndex"] as? Int ?? existing.sortIndex
            existing.household = home
            existing.modifiedAt = remoteMod
        } else {
            let m = Member(
                id: id,
                name: record["name"] as? String ?? "",
                colorHex: record["colorHex"] as? String ?? MemberPalette.color(at: 0),
                sortIndex: record["sortIndex"] as? Int ?? 0,
                household: home,
                modifiedAt: remoteMod
            )
            context.insert(m)
        }
    }

    private func mergeChore(_ record: CKRecord, context: ModelContext) throws {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let householdIDString = record["householdID"] as? String,
              let householdID = UUID(uuidString: householdIDString)
        else { return }
        let remoteMod = record["modifiedAt"] as? Date ?? .distantPast

        let hid = householdID
        let homeDesc = FetchDescriptor<Household>(predicate: #Predicate<Household> { $0.id == hid })
        guard let home = try context.fetch(homeDesc).first else { return }

        let cadenceJSON = record["cadenceJSON"] as? String ?? "{}"
        let rotationJSON = record["rotationOrderJSON"] as? String ?? "[]"
        let title = record["title"] as? String ?? ""
        let notes = record["notes"] as? String ?? ""

        let cid = id
        let descriptor = FetchDescriptor<Chore>(predicate: #Predicate<Chore> { $0.id == cid })
        if let existing = try context.fetch(descriptor).first {
            guard remoteMod >= existing.modifiedAt else { return }
            existing.title = title
            existing.notes = notes
            existing.createdAt = record["createdAt"] as? Date ?? existing.createdAt
            existing.lastCompletedAt = record["lastCompletedAt"] as? Date
            if let s = record["currentAssigneeID"] as? String, let u = UUID(uuidString: s) {
                existing.currentAssigneeID = u
            }
            existing.cadenceJSON = cadenceJSON
            existing.rotationOrderJSON = rotationJSON
            existing.household = home
            existing.modifiedAt = remoteMod
        } else {
            let cadence = (try? ChoreCadence.decode(json: cadenceJSON)) ?? .dailyDefault
            let rotation = Chore.decodeRotation(rotationJSON)
            let c = Chore(
                id: id,
                title: title,
                notes: notes,
                createdAt: record["createdAt"] as? Date ?? Date(),
                lastCompletedAt: record["lastCompletedAt"] as? Date,
                currentAssigneeID: (record["currentAssigneeID"] as? String).flatMap(UUID.init(uuidString:)),
                cadence: cadence,
                rotationMemberIDs: rotation,
                household: home,
                modifiedAt: remoteMod
            )
            context.insert(c)
        }
    }

    private func mergeLog(_ record: CKRecord, context: ModelContext) throws {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let choreIDString = record["choreID"] as? String,
              let choreID = UUID(uuidString: choreIDString),
              let memberIDString = record["memberID"] as? String,
              let memberUUID = UUID(uuidString: memberIDString)
        else { return }
        let remoteMod = record["modifiedAt"] as? Date ?? .distantPast

        let cid = choreID
        let choreDesc = FetchDescriptor<Chore>(predicate: #Predicate<Chore> { $0.id == cid })
        guard let chore = try context.fetch(choreDesc).first else { return }

        let lid = id
        let descriptor = FetchDescriptor<ChoreLog>(predicate: #Predicate<ChoreLog> { $0.id == lid })
        if let existing = try context.fetch(descriptor).first {
            guard remoteMod >= existing.modifiedAt else { return }
            existing.completedAt = record["completedAt"] as? Date ?? existing.completedAt
            existing.memberID = memberUUID
            existing.chore = chore
            existing.modifiedAt = remoteMod
        } else {
            let log = ChoreLog(
                id: id,
                completedAt: record["completedAt"] as? Date ?? Date(),
                memberID: memberUUID,
                chore: chore,
                modifiedAt: remoteMod
            )
            context.insert(log)
        }
    }

}

// MARK: - Plan-facing alias

typealias CloudSharingService = HouseholdCloudKitStore

enum CloudKitConstants {
    static let containerIdentifier = "iCloud.com.csmith.LaunchBox"
}
