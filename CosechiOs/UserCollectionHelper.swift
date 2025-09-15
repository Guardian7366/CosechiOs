import Foundation
import CoreData

enum UserCollectionError: Error {
    case userNotFound
    case cropNotFound
    case alreadyInCollection
    case saveFailed(Error)
}

struct UserCollectionHelper {
    /// Añade un cultivo a la colección del usuario.
    static func addCrop(cropID: UUID, for userID: UUID, context: NSManagedObjectContext) throws -> Bool {
        return try context.performAndWaitWithReturn {
            // 1. Buscar usuario
            let ufr: NSFetchRequest<User> = User.fetchRequest()
            ufr.predicate = NSPredicate(format: "userID == %@", userID as CVarArg)
            guard let user = try context.fetch(ufr).first else { throw UserCollectionError.userNotFound }
            
            // 2. Buscar crop
            let cfr: NSFetchRequest<Crop> = Crop.fetchRequest()
            cfr.predicate = NSPredicate(format: "cropID == %@", cropID as CVarArg)
            guard let crop = try context.fetch(cfr).first else { throw UserCollectionError.cropNotFound }
            
            // 3. Verificar duplicados
            let existsFR: NSFetchRequest<UserCollection> = UserCollection.fetchRequest()
            existsFR.predicate = NSPredicate(format: "user == %@ AND crop == %@", user, crop)
            existsFR.fetchLimit = 1
            if try context.fetch(existsFR).first != nil {
                return false // ya está en la colección
            }
            
            // 4. Crear relación
            let uc = UserCollection(context: context)
            uc.collectionID = UUID()
            uc.addedAt = Date()
            uc.user = user
            uc.crop = crop
            
            try context.save()
            print("✅ Crop \(crop.name ?? "nil") añadido para usuario \(userID)")
            return true
        }
    }
    
    /// Elimina un cultivo de la colección del usuario.
    static func removeCrop(cropID: UUID, for userID: UUID, context: NSManagedObjectContext) throws {
        try context.performAndWaitWithReturnVoid {
            let ufr: NSFetchRequest<User> = User.fetchRequest()
            ufr.predicate = NSPredicate(format: "userID == %@", userID as CVarArg)
            guard let user = try context.fetch(ufr).first else { throw UserCollectionError.userNotFound }
            
            let fr: NSFetchRequest<UserCollection> = UserCollection.fetchRequest()
            fr.predicate = NSPredicate(format: "user == %@ AND crop.cropID == %@", user, cropID as CVarArg)
            if let uc = try context.fetch(fr).first {
                context.delete(uc)
                try context.save()
                print("🗑️ Eliminado cropID=\(cropID) de la colección del usuario \(userID)")
            }
        }
    }
    
    /// Verifica si un cultivo está en la colección del usuario.
    static func isInCollection(cropID: UUID, for userID: UUID, context: NSManagedObjectContext) -> Bool {
        return (try? context.performAndWaitWithReturn {
            let ufr: NSFetchRequest<User> = User.fetchRequest()
            ufr.predicate = NSPredicate(format: "userID == %@", userID as CVarArg)
            guard let user = try context.fetch(ufr).first else { return false }
            
            let fr: NSFetchRequest<UserCollection> = UserCollection.fetchRequest()
            fr.predicate = NSPredicate(format: "user == %@ AND crop.cropID == %@", user, cropID as CVarArg)
            fr.fetchLimit = 1
            return try context.fetch(fr).first != nil
        }) ?? false
    }
}

// MARK: - Helpers para ejecutar performAndWait con retorno
fileprivate extension NSManagedObjectContext {
    func performAndWaitWithReturn<T>(_ block: () throws -> T) throws -> T {
        var result: Result<T, Error>!
        performAndWait {
            do {
                result = .success(try block())
            } catch {
                result = .failure(error)
            }
        }
        switch result! {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    func performAndWaitWithReturnVoid(_ block: () throws -> Void) throws {
        var result: Result<Void, Error>!
        performAndWait {
            do {
                try block()
                result = .success(())
            } catch {
                result = .failure(error)
            }
        }
        switch result! {
        case .success: return
        case .failure(let error): throw error
        }
    }
}
