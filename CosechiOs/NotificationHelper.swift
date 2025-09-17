import Foundation
import UserNotifications
import CoreData

/// NotificationHelper avanzado:
/// - Recordatorios de tareas con recurrencia
/// - Recordatorios de cultivos (riego, fertilización, cosecha)
/// - Reprogramación masiva
/// - Mini API local para tips dinámicos
struct NotificationHelper {

    // MARK: - Tareas

    static func cancelNotification(for task: TaskEntity) {
        guard let id = task.taskID?.uuidString else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    static func scheduleNotification(for task: TaskEntity) {
        guard let id = task.taskID?.uuidString,
              let title = task.title,
              let dueDate = task.dueDate else {
            return
        }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])

        let relativeDays = Int(task.relativeDays)
        var targetDate = Calendar.current.startOfDay(for: dueDate)
        if relativeDays > 0 {
            if let newDate = Calendar.current.date(byAdding: .day, value: -relativeDays, to: targetDate) {
                targetDate = newDate
            }
        } else {
            targetDate = dueDate
        }

        let content = UNMutableNotificationContent()
        content.title = "🌱 \(title)"
        if let details = task.details, !details.isEmpty {
            content.body = details
        } else {
            content.body = NSLocalizedString("task_reminder_body", comment: "Task reminder")
        }
        content.sound = .default
        content.categoryIdentifier = "task_reminder" // importante para acciones rápidas

        let rule = task.recurrenceRule ?? "none"
        let trigger: UNNotificationTrigger

        switch rule {
        case "daily":
            let comps = Calendar.current.dateComponents([.hour, .minute], from: targetDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        case "weekly":
            let comps = Calendar.current.dateComponents([.weekday, .hour, .minute], from: targetDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        case "monthly":
            let comps = Calendar.current.dateComponents([.day, .hour, .minute], from: targetDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        default:
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: targetDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        }

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification \(id): \(error.localizedDescription)")
            } else {
                print("✅ Task notification scheduled \(id) rule=\(rule) date=\(targetDate)")
            }
        }
    }

    static func reschedule(for task: TaskEntity) {
        cancelNotification(for: task)
        scheduleNotification(for: task)
    }

    // MARK: - Cultivos

    static func scheduleCropNotification(crop: Crop, type: String, daysOffset: Int = 0) {
        guard let cid = crop.cropID else { return }

        var targetDate = Calendar.current.startOfDay(for: Date())
        if let date = Calendar.current.date(byAdding: .day, value: daysOffset, to: targetDate) {
            targetDate = date
        }

        let content = UNMutableNotificationContent()
        switch type {
        case "watering":
            content.title = "💧 \(crop.name ?? "Cultivo")"
            content.body = NSLocalizedString("crop_reminder_watering", comment: "Watering reminder")
        case "fertilize":
            content.title = "🌿 \(crop.name ?? "Cultivo")"
            content.body = NSLocalizedString("crop_reminder_fertilize", comment: "Fertilization reminder")
        case "harvest":
            content.title = "🍓 \(crop.name ?? "Cultivo")"
            content.body = NSLocalizedString("crop_reminder_harvest", comment: "Harvest reminder")
        default:
            content.title = "🌱 \(crop.name ?? "Cultivo")"
            content.body = NSLocalizedString("crop_reminder_generic", comment: "Crop reminder")
        }

        content.sound = .default
        content.categoryIdentifier = "crop_tip"

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: targetDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let request = UNNotificationRequest(identifier: cid.uuidString + "_" + type, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling crop notification: \(error.localizedDescription)")
            } else {
                print("✅ Crop notification scheduled for \(crop.name ?? "") type=\(type)")
            }
        }
    }

    // MARK: - Reprogramación masiva

    static func rescheduleAll(forUser user: User, context: NSManagedObjectContext) {
        let fetch: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fetch.predicate = NSPredicate(format: "user == %@", user)
        if let tasks = try? context.fetch(fetch) {
            for task in tasks {
                scheduleNotification(for: task)
            }
        }
        print("🔄 Rescheduled all notifications for user \(user.username ?? "")")
    }

    // MARK: - Mini API Local

    static func scheduleSeasonalTip(for crop: Crop) {
        guard let name = crop.name else { return }

        let content = UNMutableNotificationContent()
        content.title = "🌞 Tip de temporada"
        content.body = String(format: NSLocalizedString("crop_season_tip", comment: ""), name)
        content.sound = .default
        content.categoryIdentifier = "tips_category"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15, repeats: false)
        let request = UNNotificationRequest(identifier: "season_tip_" + (crop.cropID?.uuidString ?? ""), content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling seasonal tip: \(error.localizedDescription)")
            } else {
                print("✅ Seasonal tip scheduled for \(name)")
            }
        }
    }
}
