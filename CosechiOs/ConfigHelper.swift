import Foundation
import CoreData

/// Helpers para leer/crear Config asociada a un usuario.
/// Se asume la entidad Config con atributos:
/// - configID: UUID
/// - language: String
/// - notificationsEnabled: Bool
/// - theme: String
/// Relación: Config.user -> User (to-one)
struct ConfigHelper {
    /// Obtener o crear Config para un userID
    static func getOrCreateConfig(for userID: UUID, context: NSManagedObjectContext) -> Config? {
        // Buscar config existente vinculada al usuario
        let fr: NSFetchRequest<Config> = Config.fetchRequest()
        fr.predicate = NSPredicate(format: "user.userID == %@", userID as CVarArg)
        fr.fetchLimit = 1
        if let found = try? context.fetch(fr).first {
            return found
        }

        // Crear config nueva y vincular a user
        let userFR: NSFetchRequest<User> = User.fetchRequest()
        userFR.predicate = NSPredicate(format: "userID == %@", userID as CVarArg)
        userFR.fetchLimit = 1
        guard let user = try? context.fetch(userFR).first else { return nil }

        let cfg = Config(context: context)
        cfg.configID = UUID()
        
        // Si existe idioma en UserDefaults, usarlo, sino default español
        let savedLang = UserDefaults.standard.string(forKey: "appLanguage") ?? "es"
        cfg.language = savedLang
        
        cfg.notificationsEnabled = true // default ON
        cfg.theme = "Auto" // Auto | Light | Dark
        cfg.user = user

        try? context.save()
        return cfg
    }

    /// Guardar cambios en la config
    static func save(_ config: Config, context: NSManagedObjectContext) throws {
        config.user?.updatedAt = Date()
        try context.save()
    }
}

