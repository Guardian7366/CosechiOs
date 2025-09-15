import SwiftUI
import CoreData

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @State private var tasks: [TaskEntity] = []
    @State private var filter: String = "pending" // "pending", "completed", "all"
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

    @ViewBuilder
    private func taskRow(_ task: TaskEntity) -> some View {
        HStack(spacing: 12) {
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
                    Text("🌱 \(crop.name ?? "-")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // ✅ Completar (toggle) — NO abre sheet
            Button {
                TaskHelper.toggleCompletion(for: task.objectID, context: viewContext) {
                    // reload UI once finished
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { loadTasks() }
                }
            } label: {
                Image(systemName: task.status == "completed" ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.status == "completed" ? .green : .gray)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 6)

            // ✏️ Editar (abre sheet)
            Button {
                selectedTaskID = ManagedObjectIDWrapper(id: task.objectID)
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.plain)
            .padding(.trailing, 6)

            // 🗑 Eliminar (seguro)
            Button(role: .destructive) {
                TaskHelper.deleteTask(with: task.objectID, context: viewContext) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { loadTasks() }
                }
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }

    private func loadTasks() {
        guard let userID = appState.currentUserID else { tasks = []; return }
        let fr: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fr.predicate = NSPredicate(format: "user.userID == %@", userID as CVarArg)
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)]

        do {
            let results = try viewContext.fetch(fr)
            self.tasks = results
            print("📋 TaskListView.loadTasks -> \(results.count) tasks for user \(userID)")
        } catch {
            print("❌ TaskListView.loadTasks fetch error: \(error)")
            self.tasks = []
        }
    }
}
