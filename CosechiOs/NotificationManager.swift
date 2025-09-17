import Foundation
import UserNotifications
import CoreData

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
    }

    func configure() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // Acciones rápidas
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_TASK",
            title: NSLocalizedString("notif_action_complete", comment: "Complete"),
            options: [.authenticationRequired]
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_TASK",
            title: NSLocalizedString("notif_action_snooze", comment: "Snooze"),
            options: []
        )

        let viewCropAction = UNNotificationAction(
            identifier: "VIEW_CROP",
            title: NSLocalizedString("notif_action_view_crop", comment: "View crop"),
            options: [.foreground]
        )

        let viewTipsAction = UNNotificationAction(
            identifier: "VIEW_TIPS",
            title: NSLocalizedString("notif_action_view_tips", comment: "View tips"),
            options: [.foreground]
        )

        // Categorías
        let taskCategory = UNNotificationCategory(
            identifier: "task_reminder",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        let cropCategory = UNNotificationCategory(
            identifier: "crop_tip",
            actions: [viewCropAction],
            intentIdentifiers: [],
            options: []
        )

        let tipsCategory = UNNotificationCategory(
            identifier: "tips_category",
            actions: [viewTipsAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([taskCategory, cropCategory, tipsCategory])
    }

    // MARK: - Delegate
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {

        let id = response.notification.request.identifier

        switch response.actionIdentifier {
        case "COMPLETE_TASK":
            handleCompleteTask(id: id)

        case "SNOOZE_TASK":
            handleSnoozeTask(id: id)

        case "VIEW_CROP":
            print("🔎 Abrir detalle de cultivo \(id)")

        case "VIEW_TIPS":
            print("💡 Abrir sección de tips")

        default:
            break
        }

        completionHandler()
    }

    private func handleCompleteTask(id: String) {
        let context = PersistenceController.shared.container.viewContext
        let fetch: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fetch.predicate = NSPredicate(format: "taskID == %@", UUID(uuidString: id) as CVarArg? ?? "")
        if let task = try? context.fetch(fetch).first {
            TaskHelper.completeTask(task, context: context)
            print("✅ Tarea completada desde notificación: \(task.title ?? "")")
        }
    }

    private func handleSnoozeTask(id: String) {
        let context = PersistenceController.shared.container.viewContext
        if let uuid = UUID(uuidString: id) {
            let fetch: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
            fetch.predicate = NSPredicate(format: "taskID == %@", uuid as CVarArg)
            if let task = try? context.fetch(fetch).first {
                let newDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())
                task.dueDate = newDate
                try? context.save()
                NotificationHelper.reschedule(for: task)
                print("⏰ Tarea pospuesta 15 minutos: \(task.title ?? "")")
            }
        }
    }
}
