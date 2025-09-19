// AchievementManager.swift
import Foundation
import CoreData

public struct AchievementResult {
    public let xp: Int
    public let level: Int
    public let leveledUp: Bool
    public let newBadges: [String]
}

public enum AchievementAction: Equatable {
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

    // MARK: - Level formula
    public static func xpForLevel(_ level: Int) -> Int {
        ((level - 1) * (level - 1)) * 100
    }

    public static func level(forXP xp: Int) -> Int {
        let base = max(0, Double(xp) / 100.0)
        let lv = Int(floor(sqrt(base))) + 1
        return max(1, lv)
    }

    // MARK: - Badge definitions
    public static let badgeDefinitions: [String: (titleKey: String, descKey: String, symbol: String)] = [
        "first_task":      ("badge_first_task_title", "badge_first_task_desc", "checkmark.seal.fill"),
        "task_collector":  ("badge_task_collector_title", "badge_task_collector_desc", "tray.full.fill"),
        "logger_novice":   ("badge_logger_novice_title", "badge_logger_novice_desc", "book.fill"),
        "logger_master":   ("badge_logger_master_title", "badge_logger_master_desc", "book.circle.fill"),
        "explorer":        ("badge_explorer_title", "badge_explorer_desc", "leaf.fill"),
        "level_milestone": ("badge_level_milestone_title", "badge_level_milestone_desc", "star.fill")
    ]

    // MARK: - Public helpers (Core Data backed)
    public static func getXP(for userID: UUID, context: NSManagedObjectContext) -> Int {
        guard let user = fetchUser(userID: userID, context: context) else { return 0 }
        if let statsObj = user.value(forKey: "stats") as? NSManagedObject,
           let xp = statsObj.value(forKey: "xp") as? Int64 {
            return Int(xp)
        }
        return 0
    }

    public static func getLevel(for userID: UUID, context: NSManagedObjectContext) -> Int {
        guard let user = fetchUser(userID: userID, context: context) else { return 1 }
        if let statsObj = user.value(forKey: "stats") as? NSManagedObject,
           let level = statsObj.value(forKey: "level") as? Int16 {
            return Int(level)
        }
        let xp = getXP(for: userID, context: context)
        return level(forXP: xp)
    }

    public static func progressToNextLevel(for userID: UUID, context: NSManagedObjectContext) -> Double {
        let xp = getXP(for: userID, context: context)
        let currentLevel = level(forXP: xp)
        let curLevelXP = xpForLevel(currentLevel)
        let nextLevelXP = xpForLevel(currentLevel + 1)
        let denom = Double(max(1, nextLevelXP - curLevelXP))
        return Double(xp - curLevelXP) / denom
    }

    public static func getBadges(for userID: UUID, context: NSManagedObjectContext) -> [String] {
        guard let user = fetchUser(userID: userID, context: context) else { return [] }
        let req = NSFetchRequest<NSManagedObject>(entityName: "UserAchievement")
        req.predicate = NSPredicate(format: "user == %@", user)
        req.sortDescriptors = [NSSortDescriptor(key: "unlockedAt", ascending: true)]
        if let results = try? context.fetch(req) {
            return results.compactMap { $0.value(forKey: "type") as? String }
        }
        return []
    }

    // MARK: - Award XP & evaluate badges
    @discardableResult
    public static func award(action: AchievementAction, to userID: UUID, context: NSManagedObjectContext) -> AchievementResult {
        guard let user = fetchUser(userID: userID, context: context) else {
            return AchievementResult(xp: 0, level: 1, leveledUp: false, newBadges: [])
        }

        // Obtener/crear stats
        var statsObj: NSManagedObject?
        if let existing = user.value(forKey: "stats") as? NSManagedObject {
            statsObj = existing
        } else if let ent = NSEntityDescription.entity(forEntityName: "UserStats", in: context) {
            let created = NSManagedObject(entity: ent, insertInto: context)
            created.setValue(UUID(), forKey: "statsID")
            created.setValue(Int64(0), forKey: "xp")
            created.setValue(Int16(1), forKey: "level")
            created.setValue(user, forKey: "user")
            user.setValue(created, forKey: "stats")
            statsObj = created
        }

        let oldXP = (statsObj?.value(forKey: "xp") as? Int64).flatMap { Int($0) } ?? 0
        let oldLevel = (statsObj?.value(forKey: "level") as? Int16).flatMap { Int($0) } ?? level(forXP: oldXP)

        let newXP = oldXP + action.xpValue
        statsObj?.setValue(Int64(newXP), forKey: "xp")

        let newLevel = level(forXP: newXP)
        let leveledUp = newLevel > oldLevel
        statsObj?.setValue(Int16(newLevel), forKey: "level")

        var newBadges: [String] = []

        if leveledUp && newLevel % 3 == 0 {
            if addBadge("level_milestone", to: user, context: context) {
                newBadges.append("level_milestone")
            }
        }

        let taskCount = countTasks(for: user, context: context)
        if taskCount >= 1 {
            if addBadge("first_task", to: user, context: context) { newBadges.append("first_task") }
        }
        if taskCount >= 10 {
            if addBadge("task_collector", to: user, context: context) { newBadges.append("task_collector") }
        }

        let logsCount = countLogs(for: user, context: context)
        if logsCount >= 5 {
            if addBadge("logger_novice", to: user, context: context) { newBadges.append("logger_novice") }
        }
        if logsCount >= 50 {
            if addBadge("logger_master", to: user, context: context) { newBadges.append("logger_master") }
        }

        if action == .acceptRecommendation {
            if addBadge("explorer", to: user, context: context) { newBadges.append("explorer") }
        }

        do {
            try context.save()
        } catch {
            context.rollback()
        }

        let result = AchievementResult(
            xp: newXP,
            level: newLevel,
            leveledUp: leveledUp,
            newBadges: newBadges
        )

        NotificationCenter.default.post(
            name: .didUpdateAchievements,
            object: nil,
            userInfo: [
                "userID": userID,
                "xp": result.xp,
                "level": result.level,
                "leveledUp": result.leveledUp,
                "newBadges": result.newBadges
            ]
        )

        return result
    }

    // MARK: - Internals
    private static func addBadge(_ badgeID: String, to user: NSManagedObject, context: NSManagedObjectContext) -> Bool {
        let req = NSFetchRequest<NSManagedObject>(entityName: "UserAchievement")
        req.predicate = NSPredicate(format: "user == %@ AND type == %@", user, badgeID)
        req.fetchLimit = 1
        if let found = try? context.fetch(req), !found.isEmpty { return false }

        guard let ent = NSEntityDescription.entity(forEntityName: "UserAchievement", in: context) else { return false }
        let newObj = NSManagedObject(entity: ent, insertInto: context)
        newObj.setValue(UUID(), forKey: "achievementID")
        newObj.setValue(badgeID, forKey: "type")
        newObj.setValue(Date(), forKey: "unlockedAt")
        newObj.setValue(user, forKey: "user")

        if let set = user.mutableSetValue(forKey: "achievements") as NSMutableSet? {
            set.add(newObj)
        }
        return true
    }

    private static func countTasks(for user: NSManagedObject, context: NSManagedObjectContext) -> Int {
        let req: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        req.predicate = NSPredicate(format: "user == %@", user)
        return (try? context.count(for: req)) ?? 0
    }

    private static func countLogs(for user: NSManagedObject, context: NSManagedObjectContext) -> Int {
        let req: NSFetchRequest<ProgressLog> = ProgressLog.fetchRequest()
        req.predicate = NSPredicate(format: "user == %@", user)
        return (try? context.count(for: req)) ?? 0
    }

    private static func fetchUser(userID: UUID, context: NSManagedObjectContext) -> NSManagedObject? {
        let freq: NSFetchRequest<User> = User.fetchRequest()
        freq.predicate = NSPredicate(format: "userID == %@", userID as CVarArg)
        freq.fetchLimit = 1
        return (try? context.fetch(freq))?.first
    }
}

// MARK: - Notifications
public extension Notification.Name {
    static let didUpdateAchievements = Notification.Name("didUpdateAchievements")
    static let didUnlockAchievementUI = Notification.Name("didUnlockAchievementUI")
}
