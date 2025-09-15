import SwiftUI
import CoreData

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @FetchRequest(
        entity: TaskEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)],
        animation: .default
    )
    private var allTasks: FetchedResults<TaskEntity>

    @State private var filter: String = "pending" // "pending", "completed", "all"
    @State private var selectedTaskID: ManagedObjectIDWrapper? = nil
    @State private var showDeleteAlertFor: ManagedObjectIDWrapper? = nil

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
                        ForEach(todayTasks, id: \.objectID) { task in
                            taskRow(task)
                        }
                    }
                }

                // PRÓXIMAS
                let upcoming = filteredTasks.filter {
                    $0.dueDate != nil && $0.dueDate! > today
                }
                if !upcoming.isEmpty {
                    Section(header: Text("Próximas")) {
                        ForEach(upcoming, id: \.objectID) { task in
                            taskRow(task)
                        }
                    }
                }

                // COMPLETADAS
                let completed = filteredTasks.filter { $0.status == "completed" }
                if !completed.isEmpty {
                    Section(header: Text("Completadas")) {
                        ForEach(completed, id: \.objectID) { task in
                            taskRow(task)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Todas mis tareas")
        // abrir editor pasando objectID
        .sheet(item: $selectedTaskID) { wrapper in
            EditTaskView(taskID: wrapper.id)
                .environment(\.managedObjectContext, viewContext)
        }
        // confirm delete alert
        .alert(item: $showDeleteAlertFor) { wrapper in
            Alert(title: Text("Eliminar tarea"),
                  message: Text("¿Eliminar esta tarea?"),
                  primaryButton: .destructive(Text("Eliminar")) {
                      deleteTask(by: wrapper.id)
                  },
                  secondaryButton: .cancel()
            )
        }
    }

    // MARK: - Helpers

    /// Filtrado por usuario actual (ya NO por crops compartidos)
    private var filteredTasks: [TaskEntity] {
        guard let uid = appState.currentUserID else { return [] }

        return allTasks.filter { task in
            // Solo mostrar tareas creadas por este usuario
            task.user?.userID == uid
        }
        .filter { task in
            switch filter {
            case "pending": return task.status == "pending"
            case "completed": return task.status == "completed"
            default: return true
            }
        }
    }

    @ViewBuilder
    private func taskRow(_ task: TaskEntity) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
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
            }
            Spacer()

            // ✅ Completar
            if task.status == "pending" {
                Button {
                    completeTask(task)
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.gray)
            }

            // ✏️ Editar
            Button {
                selectedTaskID = ManagedObjectIDWrapper(id: task.objectID)
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.plain)

            // 🗑 Eliminar
            Button(role: .destructive) {
                showDeleteAlertFor = ManagedObjectIDWrapper(id: task.objectID)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    // marcar como completada
    private func completeTask(_ task: TaskEntity) {
        task.status = "completed"
        task.updatedAt = Date()
        NotificationHelper.cancelNotification(for: task)
        do {
            try viewContext.save()
        } catch {
            print("❌ Error guardando completion: \(error)")
            viewContext.rollback()
        }
    }

    // eliminar una tarea segura
    private func deleteTask(by objectID: NSManagedObjectID) {
        viewContext.perform {
            do {
                if let t = try viewContext.existingObject(with: objectID) as? TaskEntity {
                    NotificationHelper.cancelNotification(for: t)
                    viewContext.delete(t)
                    try viewContext.save()
                    print("🗑️ Tarea eliminada: \(t.title ?? "—")")
                }
            } catch {
                print("❌ Error al eliminar tarea: \(error)")
                viewContext.rollback()
            }
            debugPrintCounts()
        }
    }

    private func debugPrintCounts() {
        let tfr: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        let ufr: NSFetchRequest<User> = User.fetchRequest()
        let cfr: NSFetchRequest<Crop> = Crop.fetchRequest()
        let ucfr: NSFetchRequest<UserCollection> = UserCollection.fetchRequest()
        let tcount = (try? viewContext.count(for: tfr)) ?? -1
        let ucount = (try? viewContext.count(for: ufr)) ?? -1
        let ccount = (try? viewContext.count(for: cfr)) ?? -1
        let uccount = (try? viewContext.count(for: ucfr)) ?? -1
        print("DEBUG counts -> Tasks:\(tcount) Users:\(ucount) Crops:\(ccount) UserCollections:\(uccount)")
    }
}
