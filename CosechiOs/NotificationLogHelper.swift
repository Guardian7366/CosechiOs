// NotificationLogHelper.swift
import Foundation
import CoreData

/// NotificationLog helper: ahora permite asociar el log a un usuario opcionalmente.
struct NotificationLogHelper {
    /// Registra una notificación en la BD. Si `userID` está presente, intentará vincular el log al User correspondiente.
    static func logNotification(title: String, body: String, type: String, userID: UUID? = nil, context: NSManagedObjectContext) {
        let log = NotificationLog(context: context)
        log.id = UUID()
        log.title = title
        log.body = body
        log.type = type
        log.date = Date()
        // Si añadiste createdAt a la entidad, asegurar su asignación
        if log.responds(to: Selector(("setCreatedAt:"))) {
            log.setValue(Date(), forKey: "createdAt")
        } else {
            log.createdAt = Date()
        }

        // Intentar asociar usuario si userID fue provisto
        if let uid = userID {
            let fr: NSFetchRequest<User> = User.fetchRequest()
            fr.predicate = NSPredicate(format: "userID == %@", uid as CVarArg)
            fr.fetchLimit = 1
            if let user = try? context.fetch(fr).first {
                log.user = user
            }
        }

        do {
            try context.save()
        } catch {
            print("❌ Error saving NotificationLog: \(error.localizedDescription)")
            context.rollback()
        }
    }
}
