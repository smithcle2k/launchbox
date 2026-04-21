//
//  Secrets.swift
//  LaunchBox
//
//  Copy Resources/Secrets.sample.plist to Resources/Secrets.plist and fill in values.
//  Secrets.plist is git-ignored; never commit real keys.
//

import Foundation

enum Secrets {
    private static let dict: [String: Any] = {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            return [:]
        }
        return plist
    }()

    static var apiBaseURL: URL {
        let raw = dict["API_BASE_URL"] as? String ?? "https://api.example.com"
        return URL(string: raw) ?? URL(string: "https://api.example.com")!
    }

    static var oneSignalAppID: String {
        (dict["ONE_SIGNAL_APP_ID"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    static var privacyPolicyURL: URL {
        let raw = dict["PRIVACY_POLICY_URL"] as? String ?? "https://example.com/privacy"
        return URL(string: raw) ?? URL(string: "https://example.com/privacy")!
    }

    static var termsURL: URL {
        let raw = dict["TERMS_URL"] as? String ?? "https://example.com/terms"
        return URL(string: raw) ?? URL(string: "https://example.com/terms")!
    }
}
