import SwiftUI
import CoreData

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @State private var tasks: [TaskEntity] = []
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
                let todayTasks = filteredTasks.filter { $0.dueDate != nil && Calendar.current.isDateInToday($0.dueDate!) }
                if !todayTasks.isEmpty {
                    Section(header: Text("Hoy")) {
                        ForEach(todayTasks, id: \.objectID) { task in
                            taskRow(task)
                        }
                    }
                }

                // PRÓXIMAS
                let upcoming = filteredTasks.filter { $0.dueDate != nil && $0.dueDate! > today }
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
        .onAppear(perform: loadTasks)
        // abrir editor pasando objectID
        .sheet(item: $selectedTaskID) { wrapper in
            EditTaskView(taskID: wrapper.id)
                .environment(\.managedObjectContext, viewContext)
                .onDisappear(perform: loadTasks)
        }
        // confirm delete alert (opcional)
        .alert(item: $showDeleteAlertFor) { wrapper in
            Alert(title: Text("Eliminar tarea"),
                  message: Text("¿Eliminar esta tarea? Esta acción es irreversible."),
                  primaryButton: .destructive(Text("Eliminar")) {
                      deleteTask(by: wrapper.id)
                  },
                  secondaryButton: .cancel()
            )
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

            // ✅ Completar tarea (solo cambia estado aquí)
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

            // ✏️ Editar (sheet por objectID)
            Button {
                selectedTaskID = ManagedObjectIDWrapper(id: task.objectID)
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.plain)

            // 🗑 Eliminar (confirmación)
            Button(role: .destructive) {
                showDeleteAlertFor = ManagedObjectIDWrapper(id: task.objectID)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    // marca como completada y guarda de forma segura
    private func completeTask(_ task: TaskEntity) {
        viewContext.perform {
            task.status = "completed"
            task.updatedAt = Date()
            NotificationHelper.cancelNotification(for: task)
            do {
                try viewContext.save()
            } catch {
                print("❌ Error guardando completion: \(error)")
            }
            DispatchQueue.main.async {
                loadTasks()
            }
        }
    }

    // elimina una tarea por objectID (seguro)
    private func deleteTask(by objectID: NSManagedObjectID) {
        viewContext.perform {
            do {
                let obj = try viewContext.existingObject(with: objectID)
                if let t = obj as? TaskEntity {
                    NotificationHelper.cancelNotification(for: t)
                    viewContext.delete(t)
                    try viewContext.save()
                    print("🗑️ Tarea eliminada: \(t.title ?? "—")")
                } else {
                    print("⚠️ object for id is not TaskEntity: \(objectID)")
                }
            } catch {
                print("❌ Error al eliminar tarea por id: \(error)")
                viewContext.rollback()
            }
            DispatchQueue.main.async {
                loadTasks()
                // DEBUG: mostrar counts para ver si se borró algo más
                debugPrintCounts()
            }
        }
    }

    private func debugPrintCounts() {
        // Sólo para debug: imprime conteos
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

    // Cargar tareas visibles para el usuario (propias + de crops en su colección)
    private func loadTasks() {
        guard let uid = appState.currentUserID else {
            tasks = []
            return
        }

        let fr: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)]
        let all = (try? viewContext.fetch(fr)) ?? []

        // obtener cropIDs de la colección del usuario
        let ucFR: NSFetchRequest<UserCollection> = UserCollection.fetchRequest()
        ucFR.predicate = NSPredicate(format: "user.userID == %@", uid as CVarArg)
        let userCollections = (try? viewContext.fetch(ucFR)) ?? []
        let cropIDsInCollection = Set(userCollections.compactMap { $0.crop?.cropID })

        tasks = all.filter { task in
            if let tUserID = task.user?.userID, tUserID == uid { return true }
            if let cID = task.crop?.cropID, cropIDsInCollection.contains(cID) { return true }
            return false
        }
    }
}
