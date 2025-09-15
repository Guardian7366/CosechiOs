import Foundation
import CoreData
import UserNotifications

struct TaskHelper {
    static func scheduleNotification(for task: TaskEntity) {
        guard task.reminder, let id = task.taskID?.uuidString else { return }

        let content = UNMutableNotificationContent()
        content.title = task.title ?? "Tarea"
        content.body = task.details ?? "Tienes una tarea pendiente"
        content.sound = .default

        var triggerDate = task.dueDate ?? Date()

        // Si se configuró "x días antes"
        if task.relativeDays > 0 {
            triggerDate = Calendar.current.date(byAdding: .day, value: -Int(task.relativeDays), to: triggerDate) ?? triggerDate
        }

        // Convertir fecha en trigger
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: triggerDate),
            repeats: task.recurrenceRule != "none"
        )

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error programando notificación: \(error.localizedDescription)")
            } else {
                print("📌 Notificación programada para \(task.title ?? "Tarea")")
            }
        }
    }

    static func cancelNotification(for task: TaskEntity) {
        if let id = task.taskID?.uuidString {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
            print("🗑️ Notificación cancelada para tarea \(task.title ?? "")")
        }
    }

    static func reschedule(for task: TaskEntity) {
        cancelNotification(for: task)
        scheduleNotification(for: task)
    }

    static func completeTask(_ task: TaskEntity, context: NSManagedObjectContext) {
        task.status = "completed"
        task.updatedAt = Date()
        cancelNotification(for: task)
        try? context.save()
    }

    static func fetchTasks(for crop: Crop?, context: NSManagedObjectContext) -> [TaskEntity] {
        let fr: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        if let crop = crop {
            fr.predicate = NSPredicate(format: "crop == %@", crop)
        }
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)]
        return (try? context.fetch(fr)) ?? []
    }
}
