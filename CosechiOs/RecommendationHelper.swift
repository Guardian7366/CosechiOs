import Foundation
import CoreData
import SwiftUI

public struct CropRecommendation: Identifiable {
    public let id: UUID
    public let crop: Crop
    public let score: Double
    public let reasons: [String]
    public init(crop: Crop, score: Double, reasons: [String]) {
        self.crop = crop
        self.score = score
        self.reasons = reasons
        self.id = crop.cropID ?? UUID()
    }
}

public struct RecommendationHelper {
    /// Devuelve estación simple: "spring","summer","autumn","winter"
    public static func currentSeasonKey(date: Date = Date()) -> String {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 3...5: return "spring"
        case 6...8: return "summer"
        case 9...11: return "autumn"
        default: return "winter"
        }
    }

    private static let seasonMatchMap: [String: [String]] = [
        "spring": ["spring", "primavera"],
        "summer": ["summer", "verano"],
        "autumn": ["autumn", "otoño", "otono"],
        "winter": ["winter", "invierno"]
    ]

    private static func difficultyLevel(from raw: String?) -> Int {
        guard let r = raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !r.isEmpty else { return 2 }
        if ["muy fácil","muy facil","facil","fácil","easy"].contains(where: { r.contains($0) }) { return 1 }
        if ["media","intermedio","intermediate","medium"].contains(where: { r.contains($0) }) { return 2 }
        if ["difícil","dificil","dificultad alta","hard"].contains(where: { r.contains($0) }) { return 3 }
        return 2
    }

    private static func userLevel(from raw: String?) -> Int? {
        guard let r = raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !r.isEmpty else { return nil }
        if ["beginner","principiante","novato"].contains(where: { r.contains($0) }) { return 1 }
        if ["intermediate","intermedio"].contains(where: { r.contains($0) }) { return 2 }
        if ["advanced","avanzado","experto"].contains(where: { r.contains($0) }) { return 3 }
        return nil
    }

    /// Comprueba si un crop contiene la temporada indicada (soporta ES/EN)
    private static func matchesSeason(_ crop: Crop, seasonKey: String) -> Bool {
        guard let rawSeasons = crop.recommendedSeasons as? [String], !rawSeasons.isEmpty else { return false }
        let possible = seasonMatchMap[seasonKey] ?? [seasonKey]
        for s in rawSeasons {
            // normalizar
            let low = s.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current) // quita tildes
            for candidate in possible {
                if low.contains(candidate) { return true }
            }
        }
        return false
    }

    /// Recomendaciones principales
    public static func recommendCrops(context: NSManagedObjectContext, forUserID: UUID?, maxResults: Int = 8) -> [CropRecommendation] {
        do {
            let cr: NSFetchRequest<Crop> = Crop.fetchRequest()
            cr.sortDescriptors = [NSSortDescriptor(keyPath: \Crop.name, ascending: true)]
            let crops = try context.fetch(cr)

            var cropIDsInCollection = Set<UUID>()
            if let uid = forUserID {
                let ucfr: NSFetchRequest<UserCollection> = UserCollection.fetchRequest()
                ucfr.predicate = NSPredicate(format: "user.userID == %@", uid as CVarArg)
                let userCollections = (try? context.fetch(ucfr)) ?? []
                cropIDsInCollection = Set(userCollections.compactMap { $0.crop?.cropID })
            }

            var userExpertiseLevel: Int? = nil
            if let uid = forUserID {
                let ufr: NSFetchRequest<User> = User.fetchRequest()
                ufr.predicate = NSPredicate(format: "userID == %@", uid as CVarArg)
                ufr.fetchLimit = 1
                if let user = try context.fetch(ufr).first {
                    userExpertiseLevel = userLevel(from: user.expertiseLevel)
                }
            }

            let seasonKey = currentSeasonKey()
            var recommendations: [CropRecommendation] = []

            for c in crops {
                var score: Double = 0
                var reasons: [String] = []

                if matchesSeason(c, seasonKey: seasonKey) {
                    score += 50
                    let seasonDisplay = seasonDisplayNameForKey(seasonKey)
                    reasons.append(String(format: NSLocalizedString("recommendations_reason_season", comment: ""), seasonDisplay))
                }

                if forUserID != nil {
                    if let cid = c.cropID, !cropIDsInCollection.contains(cid) {
                        score += 25
                        reasons.append(NSLocalizedString("recommendations_reason_new", comment: ""))
                    } else {
                        score -= 8
                    }
                }

                let cropLevel = difficultyLevel(from: c.difficulty)
                if let userLevel = userExpertiseLevel {
                    if cropLevel <= userLevel {
                        score += 20
                        reasons.append(String(format: NSLocalizedString("recommendations_reason_difficulty", comment: ""), c.difficulty ?? NSLocalizedString("recommendations_reason_difficulty_default", comment: "")))
                    } else {
                        score -= 6
                    }
                }

                if let desc = c.cropDescription, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    score += 2
                }

                score += Double.random(in: 0..<4)
                recommendations.append(CropRecommendation(crop: c, score: score, reasons: reasons))
            }

            let sorted = recommendations.sorted { $0.score > $1.score }
            return Array(sorted.prefix(maxResults))
        } catch {
            print("❌ RecommendationHelper.recommendCrops fetch error: \(error)")
            return []
        }
    }

    /// Añade crop a la colección del usuario (si no existe)
    @discardableResult
    public static func addCropToUserCollection(crop: Crop, userID: UUID, context: NSManagedObjectContext) throws -> Bool {
        guard let cropID = crop.cropID else {
            throw NSError(domain: "RecommendationHelper", code: 2, userInfo: [NSLocalizedDescriptionKey: "Crop has no cropID"])
        }

        let ucfr: NSFetchRequest<UserCollection> = UserCollection.fetchRequest()
        ucfr.predicate = NSPredicate(format: "user.userID == %@ AND crop.cropID == %@", userID as CVarArg, cropID as CVarArg)
        ucfr.fetchLimit = 1
        if let found = try? context.fetch(ucfr), found.first != nil { return false }

        let ufr: NSFetchRequest<User> = User.fetchRequest()
        ufr.predicate = NSPredicate(format: "userID == %@", userID as CVarArg)
        ufr.fetchLimit = 1
        guard let user = try context.fetch(ufr).first else {
            throw NSError(domain: "RecommendationHelper", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }

        let uc = UserCollection(context: context)
        uc.collectionID = UUID()
        uc.addedAt = Date()
        uc.user = user
        uc.crop = crop

        try context.save()
        NotificationCenter.default.post(name: .userCollectionsChanged, object: nil)
        return true
    }

    private static func seasonDisplayNameForKey(_ key: String) -> String {
        switch key {
        case "spring": return NSLocalizedString("season_spring", comment: "Spring")
        case "summer": return NSLocalizedString("season_summer", comment: "Summer")
        case "autumn": return NSLocalizedString("season_autumn", comment: "Autumn")
        default: return NSLocalizedString("season_winter", comment: "Winter")
        }
    }
}
