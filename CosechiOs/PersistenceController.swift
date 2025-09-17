import Foundation
import CoreData
import UIKit

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CosechiOsModel")

        // Si pedimos inMemory (para tests) sustituimos la descripción por una en memoria
        if inMemory {
            let desc = NSPersistentStoreDescription()
            desc.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [desc]
        }

        // Opciones de migración ligera + history tracking
        container.persistentStoreDescriptions.forEach { desc in
            // Migración automática (lightweight)
            desc.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            desc.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

            // History tracking
            desc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

            // WAL journal mode -> tiene que ser diccionario
            desc.setOption(["journal_mode": "WAL"] as NSDictionary, forKey: NSSQLitePragmasOption)
        }

        // Cargar stores
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("❌ Error cargando persistent store: \(error), \(error.userInfo)")
            } else {
                print("✅ Loaded persistent store: \(storeDescription.url?.lastPathComponent ?? storeDescription.type)")
            }
        }

        // Merge automático y políticas para evitar conflictos
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.shouldDeleteInaccessibleFaults = true

        // Observador opcional
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(contextDidSavePrivateContext(_:)),
                                               name: .NSManagedObjectContextDidSave,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Background context factory
    func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        ctx.automaticallyMergesChangesFromParent = true
        return ctx
    }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask { ctx in
            ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            block(ctx)
            if ctx.hasChanges {
                do {
                    try ctx.save()
                } catch {
                    print("⚠️ Error saving background context: \(error.localizedDescription)")
                    ctx.rollback()
                }
            }
        }
    }

    // MARK: - Save helper
    func saveContext(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }

    // Listener opcional
    @objc private func contextDidSavePrivateContext(_ note: Notification) {
        guard let ctx = note.object as? NSManagedObjectContext else { return }
        if ctx !== container.viewContext {
            // Debug: podrías mergear si lo deseas
        }
    }

    // MARK: - Export / Import
    func exportBackupJSON() throws -> Data {
        let context = container.viewContext

        // Define fetch requests
        let userReq = NSFetchRequest<NSManagedObject>(entityName: "User")
        let cropReq = NSFetchRequest<NSManagedObject>(entityName: "Crop")
        let taskReq = NSFetchRequest<NSManagedObject>(entityName: "TaskEntity")
        let stepReq = NSFetchRequest<NSManagedObject>(entityName: "Step")
        let ucReq = NSFetchRequest<NSManagedObject>(entityName: "UserCollection")
        let cfgReq = NSFetchRequest<NSManagedObject>(entityName: "Config")

        let users = try context.fetch(userReq)
        let crops = try context.fetch(cropReq)
        let tasks = try context.fetch(taskReq)
        let steps = try context.fetch(stepReq)
        let ucs = try context.fetch(ucReq)
        let cfgs = try context.fetch(cfgReq)

        func dict(from obj: NSManagedObject) -> [String: Any] {
            var d: [String: Any] = [:]
            for (name, _) in obj.entity.attributesByName {
                if let v = obj.value(forKey: name) {
                    if let date = v as? Date {
                        d[name] = ISO8601DateFormatter().string(from: date)
                    } else if let data = v as? Data {
                        d[name] = data.base64EncodedString()
                    } else {
                        d[name] = v
                    }
                }
            }
            for (rname, rel) in obj.entity.relationshipsByName {
                if rel.isToMany {
                    let set = obj.mutableSetValue(forKey: rname)
                    let ids = set.allObjects.compactMap {
                        ($0 as? NSManagedObject)?.value(forKey: "cropID")
                        ?? ($0 as? NSManagedObject)?.value(forKey: "userID")
                    }
                    d[rname] = ids
                } else {
                    if let tgt = obj.value(forKey: rname) as? NSManagedObject {
                        d[rname] = tgt.value(forKey: "cropID")
                        ?? tgt.value(forKey: "userID")
                        ?? NSNull()
                    }
                }
            }
            return d
        }

        let payload: [String: Any] = [
            "users": users.map(dict),
            "crops": crops.map(dict),
            "tasks": tasks.map(dict),
            "steps": steps.map(dict),
            "userCollections": ucs.map(dict),
            "configs": cfgs.map(dict)
        ]

        return try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
    }

    func importBackupJSON(_ data: Data, mergePolicy: MergePolicy = .createNew) throws {
        // TODO: implementar import robusto según reglas de negocio
    }

    enum MergePolicy {
        case createNew
        case preferLocal
        case preferIncoming
    }

    // MARK: - Debug helpers
    func resetDemoData() {
        performBackgroundTask { ctx in
            let fr: NSFetchRequest<User> = User.fetchRequest()
            fr.predicate = NSPredicate(format: "email == %@", "demo@local")
            if let demoUsers = try? ctx.fetch(fr), !demoUsers.isEmpty {
                demoUsers.forEach { ctx.delete($0) }
                do {
                    try ctx.save()
                    print("🧹 Demo user(s) removed")
                } catch {
                    print("⚠️ Error removing demo user: \(error.localizedDescription)")
                }
            }
        }
    }
}
