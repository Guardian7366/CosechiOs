// AchievementManager.swift
import Foundation
import CoreData

/// Resultado al otorgar XP
public struct AchievementResult {
    public let xp: Int
    public let level: Int
    public let leveledUp: Bool
    public let newBadges: [String]
}

/// Acciones que otorgan XP
public enum AchievementAction {
    case createTask
    case addProgressLog
    case acceptRecommendation

    var xpValue: Int {
        switch self {
        case .createTask: return 50
        case .addProgressLog: return 30
        case .acceptRecommendation: return 20
        }
    }

    var analyticsKey: String {
        switch self {
        case .createTask: return "create_task"
        case .addProgressLog: return "add_progress_log"
        case .acceptRecommendation: return "accept_recommendation"
        }
    }
}

public final class AchievementManager {
    private static let keyPrefix = "ach_"

    // MARK: - Storage keys
    private static func xpKey(for userID: UUID) -> String { "\(keyPrefix)xp_\(userID.uuidString)" }
    private static func badgesKey(for userID: UUID) -> String { "\(keyPrefix)badges_\(userID.uuidString)" }

    // MARK: - XP / badges basic ops
    public static func getXP(for userID: UUID) -> Int {
        UserDefaults.standard.integer(forKey: xpKey(for: userID))
    }

    private static func setXP(_ xp: Int, for userID: UUID) {
        UserDefaults.standard.set(xp, forKey: xpKey(for: userID))
    }

    public static func getBadges(for userID: UUID) -> [String] {
        UserDefaults.standard.stringArray(forKey: badgesKey(for: userID)) ?? []
    }

    @discardableResult
    public static func addBadge(_ badgeID: String, for userID: UUID) -> Bool {
        var badges = getBadges(for: userID)
        if badges.contains(badgeID) { return false }
        badges.append(badgeID)
        UserDefaults.standard.set(badges, forKey: badgesKey(for: userID))
        return true
    }

    // MARK: - Level formula
    /// xp needed for level L is: (L-1)^2 * 100
    public static func xpForLevel(_ level: Int) -> Int {
        ((level - 1) * (level - 1)) * 100
    }

    public static func level(forXP xp: Int) -> Int {
        // floor(sqrt(xp/100)) + 1
        let base = max(0, Double(xp) / 100.0)
        let lv = Int(floor(sqrt(base))) + 1
        return max(1, lv)
    }

    public static func progressToNextLevel(for userID: UUID) -> Double {
        let xp = getXP(for: userID)
        let currentLevel = level(forXP: xp)
        let curLevelXP = xpForLevel(currentLevel)
        let nextLevelXP = xpForLevel(currentLevel + 1)
        let denom = Double(max(1, nextLevelXP - curLevelXP))
        return Double(xp - curLevelXP) / denom
    }

    // MARK: - Badge definitions (id -> metadata)
    public static let badgeDefinitions: [String: (titleKey: String, descKey: String, symbol: String)] = [
        "first_task":      ("badge_first_task_title", "badge_first_task_desc", "checkmark.seal.fill"),
        "task_collector":  ("badge_task_collector_title", "badge_task_collector_desc", "tray.full.fill"),
        "logger_novice":   ("badge_logger_novice_title", "badge_logger_novice_desc", "book.fill"),
        "logger_master":   ("badge_logger_master_title", "badge_logger_master_desc", "book.circle.fill"),
        "explorer":        ("badge_explorer_title", "badge_explorer_desc", "leaf.fill"),
        "level_milestone": ("badge_level_milestone_title", "badge_level_milestone_desc", "star.fill")
    ]

    // MARK: - Award flow
    /// Otorga XP por una acción y evalúa nivel y badges.
    /// - Parameters:
    ///   - action: acción realizada
    ///   - userID: id del usuario
    ///   - context: optional NSManagedObjectContext para contar tareas / logs si se quiere (seguro pasar viewContext)
    /// - Returns: AchievementResult con info de XP, nivel y badges nuevas
    @discardableResult
    public static func award(action: AchievementAction, to userID: UUID, context: NSManagedObjectContext? = nil) -> AchievementResult {
        let amount = action.xpValue
        let oldXP = getXP(for: userID)
        let newXP = oldXP + amount
        setXP(newXP, for: userID)

        let oldLevel = level(forXP: oldXP)
        let newLevel = level(forXP: newXP)
        var newBadges: [String] = []

        // Level-up badge simple: milestone at levels divisible by 3
        if newLevel > oldLevel {
            if newLevel % 3 == 0 {
                if addBadge("level_milestone", for: userID) {
                    newBadges.append("level_milestone")
                }
            }
        }

        // Badges basados en conteos (si context disponible)
        if let ctx = context {
            // count tasks for user
            do {
                let taskReq: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
                taskReq.predicate = NSPredicate(format: "user.userID == %@", userID as CVarArg)
                let taskCount = try ctx.count(for: taskReq)

                if taskCount >= 1 && addBadge("first_task", for: userID) {
                    newBadges.append("first_task")
                }
                if taskCount >= 10 && addBadge("task_collector", for: userID) {
                    newBadges.append("task_collector")
                }
            } catch {
                // ignore
            }

            // count progress logs
            do {
                let plReq: NSFetchRequest<ProgressLog> = ProgressLog.fetchRequest()
                plReq.predicate = NSPredicate(format: "user.userID == %@", userID as CVarArg)
                let logsCount = try ctx.count(for: plReq)

                if logsCount >= 5 && addBadge("logger_novice", for: userID) {
                    newBadges.append("logger_novice")
                }
                if logsCount >= 50 && addBadge("logger_master", for: userID) {
                    newBadges.append("logger_master")
                }
            } catch {
                // ignore
            }

            // If action is acceptRecommendation, simple explorer badge
            if action == .acceptRecommendation {
                if addBadge("explorer", for: userID) {
                    newBadges.append("explorer")
                }
            }
        } else {
            // If no context: still add "explorer" for acceptRecommendation once
            if action == .acceptRecommendation {
                if addBadge("explorer", for: userID) {
                    newBadges.append("explorer")
                }
            }
        }

        let result = AchievementResult(xp: newXP, level: newLevel, leveledUp: newLevel > oldLevel, newBadges: newBadges)
        // Optionally post Notification for UI to refresh
        NotificationCenter.default.post(name: .didUpdateAchievements, object: nil, userInfo: ["userID": userID])
        return result
    }
}

// Notification name for UI updates
public extension Notification.Name {
    static let didUpdateAchievements = Notification.Name("didUpdateAchievements")
}
