import Foundation
import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CosechiOsModel")

        // Ajustar store (inMemory para tests)
        if inMemory {
            let desc = NSPersistentStoreDescription()
            desc.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [desc]
        }

        // Habilitar history tracking para facilitar merges y futuras migraciones
        container.persistentStoreDescriptions.forEach { desc in
            desc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Error cargando persistent store: \(error.localizedDescription)")
            }
        }

        // Merge automático de cambios provenientes de contextos de fondo
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // Crear contexto de fondo para escrituras intensivas
    func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return ctx
    }

    // Save helper (seguros y con manejo de errores)
    func saveContext(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }

    // MARK: - Backup / Export como JSON (seguro entre dispositivos sin nube)
    /// Exporta un snapshot JSON con entidades principales: Users, Crops, Tasks, Steps, UserCollections, Config
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
            // Relaciones opcionales (guardar ids referenciales)
            for (rname, rel) in obj.entity.relationshipsByName {
                if rel.isToMany {
                    let set = obj.mutableSetValue(forKey: rname)
                    let ids = set.allObjects.compactMap { ($0 as? NSManagedObject)?.value(forKey: "cropID") ?? ($0 as? NSManagedObject)?.value(forKey: "userID") }
                    d[rname] = ids
                } else {
                    if let tgt = obj.value(forKey: rname) as? NSManagedObject {
                        d[rname] = tgt.value(forKey: "cropID") ?? tgt.value(forKey: "userID") ?? nil
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

        let data = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
        return data
    }

    // IMPORT sencillo: la implementación depende del schema y de cómo quieras reconciliar. Aquí solo dejo un placeholder
    func importBackupJSON(_ data: Data, mergePolicy: MergePolicy = .createNew) throws {
        // parsear JSON e insertar en context background (evitar duplicados basados en UUIDs)
        // Implementación personalizada según tu estrategia de merge.
        // Puedes pedirme que genere un importador robusto si quieres.
    }

    enum MergePolicy {
        case createNew
        case preferLocal
        case preferIncoming
    }
}

