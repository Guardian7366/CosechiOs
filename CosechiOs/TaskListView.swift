import SwiftUI
import CoreData

// Wrapper para poder usar NSManagedObjectID con .sheet(item:)
struct ManagedObjectIDWrapper: Identifiable, Hashable {
    let id: NSManagedObjectID
}

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @State private var tasks: [TaskEntity] = []
    @State private var filter: String = "pending" // "pending", "completed", "all"
    @State private var showEditSheet = false
    @State private var selectedTaskID: ManagedObjectIDWrapper? = nil

    private var today: Date { Calendar.current.startOfDay(for: Date()) }

    var body: some View {
        VStack {
            Picker("Filtro", selection: $filter) {
                Text("Pendientes").tag("pending")
                Text("Completadas").tag("completed")
                Text("Todas").tag("all")
            }
            .pickerStyle(.segmented)
            .padding()

            List {
                // HOY
                let todayTasks = filteredTasks.filter {
                    $0.dueDate != nil && Calendar.current.isDateInToday($0.dueDate!)
                }
                if !todayTasks.isEmpty {
                    Section(header: Text("Hoy")) {
                        ForEach(todayTasks) { task in
                            taskCard(task)
                        }
                    }
                }

                // PRÓXIMAS
                let upcoming = filteredTasks.filter {
                    $0.dueDate != nil && $0.dueDate! > today
                }
                if !upcoming.isEmpty {
                    Section(header: Text("Próximas")) {
                        ForEach(upcoming) { task in
                            taskCard(task)
                        }
                    }
                }

                // COMPLETADAS
                let completed = filteredTasks.filter { $0.status == "completed" }
                if !completed.isEmpty {
                    Section(header: Text("Completadas")) {
                        ForEach(completed) { task in
                            taskCard(task)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Todas mis tareas")
        .onAppear(perform: loadTasks)
        .sheet(item: $selectedTaskID) { wrapper in
            EditTaskView(taskID: wrapper.id)
                .environment(\.managedObjectContext, viewContext)
                .onDisappear(perform: loadTasks)
        }
    }

    // MARK: - Helpers

    private var filteredTasks: [TaskEntity] {
        switch filter {
        case "pending": return tasks.filter { $0.status == "pending" }
        case "completed": return tasks.filter { $0.status == "completed" }
        default: return tasks
        }
    }

    /// Tarjeta con detalles + fila de botones de acción
    @ViewBuilder
    private func taskCard(_ task: TaskEntity) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Info principal
            Text(task.title ?? "Sin título")
                .font(.headline)
                .strikethrough(task.status == "completed")

            if let due = task.dueDate {
                Text("⏰ \(due.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let crop = task.crop {
                Text("🌱 Cultivo: \(crop.name ?? "-")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Acciones en fila
            HStack {
                // ✅ Completar
                Button {
                    TaskHelper.completeTask(task, context: viewContext)
                    loadTasks()
                } label: {
                    Label("Completar", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .disabled(task.status == "completed")

                Spacer()

                // ✏️ Editar
                Button {
                    selectedTaskID = ManagedObjectIDWrapper(id: task.objectID)
                        showEditSheet = true
                } label: {
                    Label("Editar", systemImage: "pencil")
                        .foregroundColor(.blue)
                }

                Spacer()

                // 🗑 Eliminar
                Button(role: .destructive) {
                    NotificationHelper.cancelNotification(for: task)
                    viewContext.delete(task)
                    try? viewContext.save()
                    loadTasks()
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            }
            .font(.caption) // botones más compactos
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func loadTasks() {
        guard let userID = appState.currentUserID else { tasks = []; return }
        let fr: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fr.predicate = NSPredicate(format: "user.userID == %@", userID as CVarArg)
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)]

        if let results = try? viewContext.fetch(fr) {
            self.tasks = results
            print("📋 Cargadas \(results.count) tareas")
        } else {
            self.tasks = []
        }
    }
}
