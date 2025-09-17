// DebugPreviewData.swift
import Foundation
import CoreData

struct DebugPreviewData {
    @discardableResult
    static func populateIfNeeded(context: NSManagedObjectContext) -> UUID? {
        // Si ya hay al menos una tarea, no hacemos nada.
        let fr: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fr.fetchLimit = 1
        do {
            let count = try context.count(for: fr)
            if count > 0 { return nil }
        } catch {
            print("⚠️ DebugPreviewData: error al contar TaskEntity: \(error)")
            return nil
        }

        // Crear usuario demo
        let user = User(context: context)
        let userID = UUID()
        user.userID = userID
        user.username = "Demo User"
        user.email = "demo@local"
        user.createdAt = Date()
        user.updatedAt = Date()

        // Crear algunas tareas demo (pending, completed, overdue)
        func makeTask(title: String, status: String, daysOffset: Int) -> TaskEntity {
            let t = TaskEntity(context: context)
            t.taskID = UUID()
            t.title = title
            t.status = status
            t.dueDate = Calendar.current.date(byAdding: .day, value: daysOffset, to: Date())
            t.user = user
            t.createdAt = Date()
            t.updatedAt = Date()
            return t
        }

        _ = makeTask(title: "Regar tomates (demo)", status: "pending", daysOffset: 1)
        _ = makeTask(title: "Fertilizar albahaca (demo)", status: "completed", daysOffset: -3)
        _ = makeTask(title: "Cosechar fresas (demo)", status: "pending", daysOffset: -1) // overdue

        // Crear progress logs demo (varias fechas)
        for i in 0..<6 {
            let pl = ProgressLog(context: context)
            pl.progressID = UUID()
            pl.user = user
            pl.date = Calendar.current.date(byAdding: .day, value: -i, to: Date())
            pl.note = "Registro demo \(i)"
            pl.createdAt = Date()
        }

        // Crear algunos notification logs demo (acciones y tips) y asociarlos al usuario demo
        let nl1 = NotificationLog(context: context)
        nl1.id = UUID()
        nl1.title = "Recordatorio demo"
        nl1.body = "Tarea pendiente (demo)"
        nl1.type = "action:COMPLETE_TASK"
        nl1.date = Date()
        nl1.createdAt = Date()
        nl1.user = user

        let nl2 = NotificationLog(context: context)
        nl2.id = UUID()
        nl2.title = "Consejo demo"
        nl2.body = "Tip de riego (demo)"
        nl2.type = "tip:seasonal"
        nl2.date = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        nl2.createdAt = Date()
        nl2.user = user

        do {
            try context.save()
            print("✅ DebugPreviewData: datos demo insertados")
            return userID
        } catch {
            print("❌ DebugPreviewData error saving demo data: \(error.localizedDescription)")
            context.rollback()
            return nil
        }
    }
}
