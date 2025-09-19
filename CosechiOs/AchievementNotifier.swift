// AchievementNotifier.swift
import Foundation
import UserNotifications
import CoreData
import UIKit

final class AchievementNotifier {
    /// Debe invocarse en el arranque (por ejemplo en App init / Scene) para registrar observador
    /// context: el NSManagedObjectContext para consultas si quieres más info (puede ser viewContext)
    static func startObserving(context: NSManagedObjectContext) {
        // Request permission proactively (optional)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                // no-op
            }
        }

        NotificationCenter.default.addObserver(forName: .didUpdateAchievements, object: nil, queue: .main) { note in
            handle(note: note, context: context)
        }
    }

    static func stopObserving() {
        NotificationCenter.default.removeObserver(self, name: .didUpdateAchievements, object: nil)
    }

    private static func handle(note: Notification, context: NSManagedObjectContext) {
        guard let info = note.userInfo else { return }
        guard let userID = info["userID"] as? UUID else { return }
        let leveledUp = (info["leveledUp"] as? Bool) ?? false
        let newBadges = (info["newBadges"] as? [String]) ?? []

        // If leveled up, schedule local notification and ask UI to show confetti
        if leveledUp {
            // schedule local notification
            let level = info["level"] as? Int ?? 0
            scheduleLevelUpNotification(level: level)
            // notify UI to show confetti (with short payload)
            NotificationCenter.default.post(name: .didUnlockAchievementUI, object: nil, userInfo: ["type": "level", "level": level, "userID": userID])
            return
        }

        // If new badges exist, schedule a single notification summarizing them and notify UI
        if !newBadges.isEmpty {
            scheduleBadgeNotification(badgeIDs: newBadges)
            NotificationCenter.default.post(name: .didUnlockAchievementUI, object: nil, userInfo: ["type": "badge", "badges": newBadges, "userID": userID])
        }
    }

    private static func scheduleLevelUpNotification(level: Int) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notif_level_up_title", comment: "Level up")
        content.body = String(format: NSLocalizedString("notif_level_up_body", comment: "You reached level %d"), level)
        content.sound = .default

        let req = UNNotificationRequest(identifier: "ach_levelup_\(UUID().uuidString)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }

    private static func scheduleBadgeNotification(badgeIDs: [String]) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notif_badge_unlocked_title", comment: "Badge unlocked")
        // Use first badge title if available
        let first = badgeIDs.first ?? ""
        let btitle = AchievementManager.badgeDefinitions[first]?.titleKey ?? first
        content.body = String(format: NSLocalizedString("notif_badge_unlocked_body", comment: "Unlocked: %@"), NSLocalizedString(btitle, comment: ""))
        content.sound = .default

        let req = UNNotificationRequest(identifier: "ach_badge_\(UUID().uuidString)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }
}

