import Foundation
import UserNotifications
import CoreData

/// NotificationHelper avanzado:
/// - Soporta recordatorios relativos (N días antes)
/// - Soporta recurrencias simples: daily, weekly, monthly
struct NotificationHelper {

    /// Cancela notificación pendiente por taskID
    static func cancelNotification(for task: TaskEntity) {
        guard let id = task.taskID?.uuidString else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Programa notificación basada en la configuración de la task (dueDate, relativeDays, recurrenceRule).
    /// Si la tarea no tiene dueDate no hace nada.
    static func scheduleNotification(for task: TaskEntity) {
        guard let id = task.taskID?.uuidString,
              let title = task.title,
              let dueDate = task.dueDate else {
            return
        }

        // Primero cancelar cualquier pending con el mismo id (reprogramación segura)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])

        // Calcular fecha objetivo aplicando relativeDays (si existe)
        let relativeDays = Int(task.relativeDays) // 0 por defecto si nil -> cuidado, property es Int16 no optional aquí si lo añadiste
        var targetDate = Calendar.current.startOfDay(for: dueDate)
        if relativeDays > 0 {
            // restar días
            if let newDate = Calendar.current.date(byAdding: .day, value: -relativeDays, to: targetDate) {
                targetDate = newDate
            }
        } else {
            // si relativeDays == 0, usamos dueDate tal cual (con hora)
            // Para mantener la hora original de dueDate:
            targetDate = dueDate
        }

        // Contenido localizable: puedes usar Localizable.strings clave "task_reminder_body" o construir body desde task
        let content = UNMutableNotificationContent()
        content.title = "🌱 \(title)"
        // usa detalles si hay
        if let details = task.details, !details.isEmpty {
            content.body = details
        } else {
            content.body = NSLocalizedString("task_reminder_body", comment: "Recordatorio de tarea")
        }
        content.sound = .default

        // Decidir trigger según recurrenceRule
        let rule = task.recurrenceRule ?? "none"

        let trigger: UNNotificationTrigger

        switch rule {
        case "daily":
            // activar a la hora de targetDate cada día
            let comps = Calendar.current.dateComponents([.hour, .minute], from: targetDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        case "weekly":
            // activar el mismo weekday y hora cada semana
            let comps = Calendar.current.dateComponents([.weekday, .hour, .minute], from: targetDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        case "monthly":
            // activar el mismo day (día del mes) y hora cada mes
            let comps = Calendar.current.dateComponents([.day, .hour, .minute], from: targetDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        default:
            // one-shot: usar fecha completa (a la hora indicada) sin repeats
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: targetDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        }

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification \(id): \(error.localizedDescription)")
            } else {
                print("✅ Notificación programada \(id) rule=\(rule) date=\(targetDate)")
            }
        }
    }

    /// Utilidad: reprograma la notificación (cancela + schedule)
    static func reschedule(for task: TaskEntity) {
        cancelNotification(for: task)
        scheduleNotification(for: task)
    }
}
