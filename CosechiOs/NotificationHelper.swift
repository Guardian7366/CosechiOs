import Foundation
import UserNotifications
import CoreData

struct NotificationHelper {
    /// Programa una notificación local para una tarea
    static func scheduleNotification(for task: TaskEntity) {
        guard let id = task.taskID?.uuidString,
              let title = task.title,
              let dueDate = task.dueDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🌱 \(title)"
        content.body = "task_reminder_body"
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Cancela una notificación por ID
    static func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
