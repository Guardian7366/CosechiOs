import Foundation
import CoreData

struct TaskHelper {
    /// Marca la tarea como completed/pending (toggle) usando objectID y el contexto que se pasa.
    static func toggleCompletion(for objectID: NSManagedObjectID, context: NSManagedObjectContext, completion: (() -> Void)? = nil) {
        context.perform {
            do {
                guard let t = try context.existingObject(with: objectID) as? TaskEntity else {
                    print("⚠️ TaskHelper.toggleCompletion: object is not TaskEntity")
                    DispatchQueue.main.async { completion?() }
                    return
                }
                t.status = (t.status == "completed") ? "pending" : "completed"
                t.updatedAt = Date()
                try context.save()
                print("✅ TaskHelper.toggleCompletion: \(String(describing: t.title)) -> \(t.status ?? "")")
                DispatchQueue.main.async { completion?() }
            } catch {
                print("❌ TaskHelper.toggleCompletion error: \(error)")
                DispatchQueue.main.async { completion?() }
            }
        }
    }

    /// Marca la tarea como completada (idempotente)
    static func completeTask(_ objectID: NSManagedObjectID, context: NSManagedObjectContext, completion: (() -> Void)? = nil) {
        context.perform {
            do {
                guard let t = try context.existingObject(with: objectID) as? TaskEntity else {
                    DispatchQueue.main.async { completion?() }; return
                }
                t.status = "completed"
                t.updatedAt = Date()
                try context.save()
                print("✅ TaskHelper.completeTask: \(t.title ?? "no title")")
                DispatchQueue.main.async { completion?() }
            } catch {
                print("❌ TaskHelper.completeTask error: \(error)")
                DispatchQueue.main.async { completion?() }
            }
        }
    }

    /// Borra la tarea de forma segura (cancela notificación primero)
    static func deleteTask(with objectID: NSManagedObjectID, context: NSManagedObjectContext, completion: (() -> Void)? = nil) {
        context.perform {
            do {
                guard let obj = try? context.existingObject(with: objectID) else {
                    DispatchQueue.main.async { completion?() }; return
                }
                if let t = obj as? TaskEntity {
                    // cancelar notificación (NotificationHelper usa solo lectura)
                    NotificationHelper.cancelNotification(for: t)
                    print("🗑️ TaskHelper.deleteTask cancelling and deleting task: \(t.title ?? "no title")")
                } else {
                    print("⚠️ TaskHelper.deleteTask: object is not TaskEntity")
                }
                context.delete(obj)
                try context.save()
                DispatchQueue.main.async { completion?() }
            } catch {
                print("❌ TaskHelper.deleteTask error: \(error)")
                DispatchQueue.main.async { completion?() }
            }
        }
    }

    /// Crea una tarea y la guarda (opcional helper)
    static func createTask(title: String, details: String?, dueDate: Date?, reminder: Bool, recurrence: String?, relativeDays: Int16, crop: Crop?, user: User?, context: NSManagedObjectContext) {
        context.perform {
            let t = TaskEntity(context: context)
            t.taskID = UUID()
            t.title = title
            t.details = details
            t.dueDate = dueDate
            t.reminder = reminder
            t.recurrenceRule = recurrence
            t.relativeDays = relativeDays
            t.status = "pending"
            t.createdAt = Date()
            t.updatedAt = Date()
            if let c = crop { t.crop = c }
            if let u = user { t.user = u }
            do {
                try context.save()
                if reminder { NotificationHelper.scheduleNotification(for: t) }
                print("✅ TaskHelper.createTask saved: \(title)")
            } catch {
                print("❌ TaskHelper.createTask saving error: \(error)")
            }
        }
    }
    
    static func fetchTasks(for crop: Crop, context: NSManagedObjectContext) -> [TaskEntity] {
            let fr: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
            fr.predicate = NSPredicate(format: "crop == %@", crop)
            fr.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)]
            return (try? context.fetch(fr)) ?? []
        }

        static func completeTask(_ task: TaskEntity, context: NSManagedObjectContext) {
            task.status = "completed"
            task.updatedAt = Date()
            NotificationHelper.cancelNotification(for: task)
            try? context.save()
        }
}
