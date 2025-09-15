
import Foundation
import CoreData

struct TaskHelper {
    // MARK: - Toggle completion
    
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
    
    // MARK: - Complete
    
    /// Marca la tarea como completada (usando objectID)
    static func completeTask(_ objectID: NSManagedObjectID, context: NSManagedObjectContext, completion: (() -> Void)? = nil) {
        context.perform {
            do {
                guard let t = try context.existingObject(with: objectID) as? TaskEntity else {
                    DispatchQueue.main.async { completion?() }; return
                }
                t.status = "completed"
                t.updatedAt = Date()
                NotificationHelper.cancelNotification(for: t)
                try context.save()
                print("✅ TaskHelper.completeTask(objectID): \(t.title ?? "no title")")
                DispatchQueue.main.async { completion?() }
            } catch {
                print("❌ TaskHelper.completeTask(objectID) error: \(error)")
                DispatchQueue.main.async { completion?() }
            }
        }
    }
    
    /// Marca la tarea como completada (usando TaskEntity directo)
    static func completeTask(_ task: TaskEntity, context: NSManagedObjectContext) {
        context.perform {
            task.status = "completed"
            task.updatedAt = Date()
            NotificationHelper.cancelNotification(for: task)
            do {
                try context.save()
                print("✅ TaskHelper.completeTask(entity): \(task.title ?? "—")")
            } catch {
                print("❌ TaskHelper.completeTask(entity) error: \(error)")
                context.rollback()
            }
        }
    }
    
    // MARK: - Delete
    
    /// Borra la tarea de forma segura (cancela notificación primero)
    static func deleteTask(with objectID: NSManagedObjectID, context: NSManagedObjectContext, completion: (() -> Void)? = nil) {
        context.perform {
            do {
                guard let obj = try? context.existingObject(with: objectID) else {
                    DispatchQueue.main.async { completion?() }; return
                }
                if let t = obj as? TaskEntity {
                    NotificationHelper.cancelNotification(for: t)
                    print("🗑️ TaskHelper.deleteTask deleting task: \(t.title ?? "no title")")
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
    
    // MARK: - Create
    
    /// Crea una tarea y la guarda
    static func createTask(title: String,
                           details: String?,
                           dueDate: Date?,
                           reminder: Bool,
                           recurrence: String?,
                           relativeDays: Int16,
                           crop: Crop?,
                           user: User?,
                           context: NSManagedObjectContext) {
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
                context.rollback()
            }
        }
    }
    
    // MARK: - Fetch
    
    /// Devuelve las tareas para un crop PERO filtradas por el userID (privadas)
    static func fetchTasks(for crop: Crop, userID: UUID, context: NSManagedObjectContext) -> [TaskEntity] {
        let fr: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fr.predicate = NSPredicate(format: "crop == %@ AND user.userID == %@", crop, userID as CVarArg)
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)]
        return (try? context.fetch(fr)) ?? []
    }
    
    /// Fetch de tareas filtradas por usuario y opcionalmente por crop
    static func fetchTasks(for crop: Crop?, userID: UUID?, context: NSManagedObjectContext) -> [TaskEntity] {
        guard let uid = userID else { return [] }
        
        let fr: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        var preds: [NSPredicate] = []
        
        preds.append(NSPredicate(format: "user.userID == %@", uid as CVarArg))
        
        if let crop = crop {
            preds.append(NSPredicate(format: "crop == %@", crop))
        }
        
        fr.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: preds)
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)]
        
        return (try? context.fetch(fr)) ?? []
    }
    
    // MARK: - Notifications
    
    /// Wrapper para programar notificaciones
    static func scheduleNotification(for task: TaskEntity) {
        NotificationHelper.scheduleNotification(for: task)
    }
}
