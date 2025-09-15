import Foundation
import CoreData
import UIKit

struct ProgressLogHelper {
    /// Crear una nueva entrada de progreso
    static func addLog(for crop: Crop, user: User, note: String?, image: UIImage?, category: String?, context: NSManagedObjectContext) {
        let log = ProgressLog(context: context)
        log.progressID = UUID()
        log.date = Date()
        log.note = note
        log.category = category
        if let img = image, let data = img.jpegData(compressionQuality: 0.8) {
            log.imageData = data
        }
        log.crop = crop
        log.user = user
        
        try? context.save()
    }
    
    /// Editar log existente
    static func editLog(_ log: ProgressLog, note: String?, image: UIImage?, category: String?, context: NSManagedObjectContext) {
        log.note = note
        log.category = category
        log.date = Date() // actualizar fecha de última edición
        if let img = image, let data = img.jpegData(compressionQuality: 0.8) {
            log.imageData = data
        } else {
            log.imageData = nil
        }
        try? context.save()
    }
    
    /// Obtener logs de un cultivo
    static func fetchLogs(for crop: Crop, context: NSManagedObjectContext) -> [ProgressLog] {
        let fr: NSFetchRequest<ProgressLog> = ProgressLog.fetchRequest()
        fr.predicate = NSPredicate(format: "crop == %@", crop)
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \ProgressLog.date, ascending: false)]
        return (try? context.fetch(fr)) ?? []
    }
    
    /// Eliminar log (safe): primero nullifica relaciones para evitar cascadas accidentales
    static func deleteLog(_ log: ProgressLog, context: NSManagedObjectContext) {
        // Nullificar relaciones de forma explícita
        log.crop = nil
        log.user = nil
        
        context.delete(log)
        try? context.save()
    }
}

