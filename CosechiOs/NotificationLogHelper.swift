// NotificationLogHelper.swift
import CoreData
import UserNotifications

struct NotificationLogHelper {
    /// Registra cuando se programa o recibe una notificación
    static func logNotification(title: String, body: String, type: String, context: NSManagedObjectContext) {
        let log = NotificationLog(context: context)
        log.id = UUID()
        log.title = title
        log.body = body
        log.type = type
        log.date = Date()
        saveContext(context)
    }

    /// Registra cuando el usuario realiza una acción rápida
    static func logAction(action: String, notificationID: String, context: NSManagedObjectContext) {
        let log = NotificationLog(context: context)
        log.id = UUID()
        log.title = NSLocalizedString("notif_log_action_title", comment: "Notification action")
        log.body = String(format: NSLocalizedString("notif_log_action_body", comment: "User performed action %@ on notification"), action)
        log.type = "action:\(action)"
        log.date = Date()
        saveContext(context)
    }

    private static func saveContext(_ context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            print("❌ Error saving NotificationLog: \(error.localizedDescription)")
        }
    }
}
