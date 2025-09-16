import Foundation

struct RecommendationAnalytics {
    private static let shownKey = "rec_analytics_shown_v1"
    private static let acceptedKey = "rec_analytics_accepted_v1"

    static func logShown(cropID: UUID) {
        var arr = (UserDefaults.standard.array(forKey: shownKey) as? [String]) ?? []
        arr.append(cropID.uuidString)
        UserDefaults.standard.set(arr, forKey: shownKey)
    }

    static func logAccepted(cropID: UUID) {
        var arr = (UserDefaults.standard.array(forKey: acceptedKey) as? [String]) ?? []
        arr.append(cropID.uuidString)
        UserDefaults.standard.set(arr, forKey: acceptedKey)
    }

    static func getShownCount() -> Int {
        (UserDefaults.standard.array(forKey: shownKey) as? [String])?.count ?? 0
    }

    static func getAcceptedCount() -> Int {
        (UserDefaults.standard.array(forKey: acceptedKey) as? [String])?.count ?? 0
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: shownKey)
        UserDefaults.standard.removeObject(forKey: acceptedKey)
    }
}

