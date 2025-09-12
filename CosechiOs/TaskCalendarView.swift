import SwiftUI
import CoreData

struct TasksCalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: TaskEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)],
        predicate: NSPredicate(format: "status == %@", "pending"),
        animation: .default
    ) private var tasks: FetchedResults<TaskEntity>

    var body: some View {
        List {
            ForEach(tasks) { task in
                VStack(alignment: .leading) {
                    Text(task.title ?? "Tarea")
                        .font(.headline)
                    if let details = task.details, !details.isEmpty {
                        Text(details)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    if let date = task.dueDate {
                        Text("⏰ \(date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle("Calendario de Tareas")
    }
}

