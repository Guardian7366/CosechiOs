import Foundation
import CoreData

struct StepProgressHelper {
    /// Obtiene (o crea si no existe) el progreso de un step para un usuario
    static func getOrCreateProgress(for step: Step, userID: UUID, context: NSManagedObjectContext) -> StepProgress {
        let fr: NSFetchRequest<StepProgress> = StepProgress.fetchRequest()
        fr.predicate = NSPredicate(format: "user.userID == %@ AND step == %@", userID as CVarArg, step)
        fr.fetchLimit = 1

        if let existing = try? context.fetch(fr).first {
            return existing
        }

        // Crear si no existe
        let sp = StepProgress(context: context)
        sp.progressID = UUID()
        sp.isCompleted = false
        sp.step = step

        // Vincular al usuario
        let frUser: NSFetchRequest<User> = User.fetchRequest()
        frUser.predicate = NSPredicate(format: "userID == %@", userID as CVarArg)
        if let user = try? context.fetch(frUser).first {
            sp.user = user
        }

        try? context.save()
        return sp
    }

    /// Marca un step como completado o no
    static func toggleStep(_ step: Step, userID: UUID, context: NSManagedObjectContext) {
        let sp = getOrCreateProgress(for: step, userID: userID, context: context)
        sp.isCompleted.toggle()
        sp.completedAt = sp.isCompleted ? Date() : nil
        try? context.save()
    }

    /// Verifica si un step está completado
    static func isCompleted(_ step: Step, userID: UUID, context: NSManagedObjectContext) -> Bool {
        let sp = getOrCreateProgress(for: step, userID: userID, context: context)
        return sp.isCompleted
    }
}

