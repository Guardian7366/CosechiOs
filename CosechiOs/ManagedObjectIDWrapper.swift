import Foundation
import CoreData

/// Wrapper para presentar sheets con un NSManagedObjectID (Identifiable)
struct ManagedObjectIDWrapper: Identifiable, Hashable {
    let id: NSManagedObjectID
}
