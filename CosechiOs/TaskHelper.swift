import Foundation
import CoreData

struct TaskHelper {
    /// Devuelve las tareas asociadas a un cultivo
    static func fetchTasks(for crop: Crop, context: NSManagedObjectContext) -> [TaskEntity] {
        let fr: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fr.predicate = NSPredicate(format: "crop == %@", crop)
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)]
        return (try? context.fetch(fr)) ?? []
    }

    /// Marca una tarea como completada
    static func completeTask(_ task: TaskEntity, context: NSManagedObjectContext) {
        task.status = "completed"
        task.updatedAt = Date()
        try? context.save()
        if let id = task.taskID?.uuidString {
            NotificationHelper.cancelNotification(id: id)
        }
    }

    /// Elimina una tarea
    static func deleteTask(_ task: TaskEntity, context: NSManagedObjectContext) {
        context.delete(task)
        try? context.save()
        if let id = task.taskID?.uuidString {
            NotificationHelper.cancelNotification(id: id)
        }
    }
}
