import Foundation

/// Reads/writes the blocked-word list in the shared App Group UserDefaults.
/// Compiled into BOTH the host app and the Safari extension.
enum SharedStore {
    static let baseGroup = "group.com.keywordblocker.shared"
    static let keywordsKey = "blockedKeywords"

    /// AltStore / SideStore rewrite the App Group id (they append the Team ID) when they
    /// re-sign with a free account, and publish the new id in the Info.plist key
    /// `ALTAppGroups`. We prefer that value and fall back to the plain id otherwise.
    static var groupIdentifier: String {
        if let groups = Bundle.main.object(forInfoDictionaryKey: "ALTAppGroups") as? [String] {
            if let match = groups.first(where: { $0.hasPrefix(baseGroup) }) { return match }
            if let first = groups.first { return first }
        }
        return baseGroup
    }

    /// False when the App Group container is not available (e.g. signing dropped the entitlement).
    static var isGroupAvailable: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) != nil
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: groupIdentifier) ?? .standard
    }

    static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func load() -> [String] {
        defaults.stringArray(forKey: keywordsKey) ?? []
    }

    static func save(_ keywords: [String]) {
        defaults.set(keywords, forKey: keywordsKey)
    }
}
