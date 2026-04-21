//
//  PersistenceBootstrap.swift
//  LaunchBox
//

import Foundation
import SwiftData

enum PersistenceBootstrap {
    /// Sets which household the app shows; persisted in `UserDefaults`.
    @MainActor
    static func setActiveHouseholdID(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: AppStorageKeys.activeHouseholdID)
    }

    /// All households in the store (for the switcher UI).
    @MainActor
    static func allHouseholds(context: ModelContext) throws -> [Household] {
        var d = FetchDescriptor<Household>()
        d.sortBy = [SortDescriptor(\.name)]
        return try context.fetch(d)
    }

    /// The selected household, if that id still exists.
    @MainActor
    static func activeHousehold(context: ModelContext) throws -> Household? {
        guard let s = UserDefaults.standard.string(forKey: AppStorageKeys.activeHouseholdID),
              let uid = UUID(uuidString: s)
        else { return nil }
        let id = uid
        let d = FetchDescriptor<Household>(predicate: #Predicate<Household> { $0.id == id })
        return try context.fetch(d).first
    }

    /// Ensures at least one household exists and returns the **active** one (or the first / a new default).
    @MainActor
    static func ensureHousehold(context: ModelContext) throws -> Household {
        if let active = try activeHousehold(context: context) {
            return active
        }

        var d = FetchDescriptor<Household>()
        d.fetchLimit = 1
        let any = try context.fetch(d)
        if let h = any.first {
            setActiveHouseholdID(h.id)
            return h
        }

        let home = Household(name: String(localized: "Home"))
        context.insert(home)
        try context.save()
        setActiveHouseholdID(home.id)
        return home
    }
}
