import Foundation
import CoreData

struct UserCollectionHelper {
    /// Agrega un cultivo a la colección de un usuario
    static func addCrop(_ crop: Crop, for userID: UUID, context: NSManagedObjectContext) throws {
        // Buscar el usuario
        let fr: NSFetchRequest<User> = User.fetchRequest()
        fr.predicate = NSPredicate(format: "userID == %@", userID as CVarArg)
        guard let user = try context.fetch(fr).first else { return }

        // Verificar si ya existe en la colección
        if let collections = user.collections as? Set<UserCollection>,
           collections.contains(where: { $0.crop == crop }) {
            return // Ya está agregado
        }

        // Crear nueva relación UserCollection
        let entity = UserCollection(context: context)
        entity.collectionID = UUID()
        entity.addedAt = Date()
        entity.user = user
        entity.crop = crop

        try context.save()
    }

    /// Elimina un cultivo de la colección del usuario
    static func removeCrop(_ crop: Crop, for userID: UUID, context: NSManagedObjectContext) throws {
        let fr: NSFetchRequest<UserCollection> = UserCollection.fetchRequest()
        fr.predicate = NSPredicate(format: "user.userID == %@ AND crop == %@", userID as CVarArg, crop)
        let results = try context.fetch(fr)
        for item in results {
            context.delete(item)
        }
        try context.save()
    }

    /// Verifica si un cultivo ya está en la colección del usuario
    static func isInCollection(_ crop: Crop, for userID: UUID, context: NSManagedObjectContext) -> Bool {
        let fr: NSFetchRequest<UserCollection> = UserCollection.fetchRequest()
        fr.predicate = NSPredicate(format: "user.userID == %@ AND crop == %@", userID as CVarArg, crop)
        let count = (try? context.count(for: fr)) ?? 0
        return count > 0
    }
}

