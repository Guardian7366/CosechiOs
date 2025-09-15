import SwiftUI
import CoreData

struct TaskCalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @State private var tasks: [TaskEntity] = []              // ahora manual
    @State private var showingEditTask: TaskEntity?

    var body: some View {
        NavigationStack {
            VStack {
                // 🔹 Resumen de tareas
                TaskSummaryView()
                    .environment(\.managedObjectContext, viewContext)
                    .padding(.horizontal)

                List {
                    // Obtener las fechas ordenadas (keys)
                    let dates = groupedTasks.keys.sorted()

                    ForEach(dates, id: \.self) { date in
                        Section(header: Text(formattedDate(date))) {
                            // Items para esta fecha
                            let items = groupedTasks[date] ?? []

                            ForEach(items, id: \.objectID) { task in
                                taskRow(task)
                            }
                            // swipe-to-delete en la lista de items de la sección
                            .onDelete { offsets in
                                deleteTask(at: offsets, in: items)
                            }
                        }
                    }
                }
            }
            .navigationTitle("calendar_tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AddTaskView().environmentObject(appState)) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $showingEditTask) { task in
                EditTaskView(task: task)
                    .environment(\.managedObjectContext, viewContext)
            }
            .onAppear(perform: loadTasks)
            .onChange(of: appState.currentUserID) { _ in loadTasks() } // recargar si cambia user
        }
    }

    // MARK: - Helpers

    /// Agrupa las tareas por fecha (startOfDay)
    private var groupedTasks: [Date: [TaskEntity]] {
        let arr = tasks
        return Dictionary(grouping: arr) { task in
            Calendar.current.startOfDay(for: task.dueDate ?? Date())
        }
    }

    /// Formatea la fecha para el header de la sección
    private func formattedDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .full
        df.timeStyle = .none
        return df.string(from: date)
    }

    /// Alterna el estado completado/pending
    private func toggleTaskCompletion(_ task: TaskEntity) {
        task.status = (task.status == "completed") ? "pending" : "completed"
        task.updatedAt = Date()
        try? viewContext.save()
        // cancelar o reprogramar notificación si hace falta
        if task.status == "completed" {
            NotificationHelper.cancelNotification(for: task)
        } else if task.status == "pending", task.reminder {
            TaskHelper.scheduleNotification(for: task)
        }
        loadTasks() // refrescar
    }

    /// Elimina tareas a partir de offsets dentro del array `tasksForSection`
    private func deleteTask(at offsets: IndexSet, in tasksForSection: [TaskEntity]) {
        for index in offsets {
            let task = tasksForSection[index]
            NotificationHelper.cancelNotification(for: task)
            viewContext.delete(task)
        }
        try? viewContext.save()
        loadTasks()
    }

    /// Vista de una fila de tarea
    private func taskRow(_ task: TaskEntity) -> some View {
        HStack {
            Button(action: {
                toggleTaskCompletion(task)
            }) {
                Image(systemName: task.status == "completed" ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.status == "completed" ? .green : .gray)
            }

            VStack(alignment: .leading) {
                Text(task.title ?? "")
                    .strikethrough(task.status == "completed")
                    .font(.body)
                if let details = task.details, !details.isEmpty {
                    Text(details)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                showingEditTask = task
            } label: {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
        }
    }

    // MARK: - Carga de datos

    /// Carga y filtra tareas respetando el usuario actual.
    private func loadTasks() {
        // obtener todas las tareas (ordenadas)
        let fr: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)]
        let all = (try? viewContext.fetch(fr)) ?? []

        guard let uid = appState.currentUserID else {
            // si no hay usuario, dejamos lista vacía (o podrías decidir mostrar sólo tareas sin user)
            tasks = []
            return
        }

        // 1) cultivos en la colección del usuario (por cropID)
        let ucFR: NSFetchRequest<UserCollection> = UserCollection.fetchRequest()
        ucFR.predicate = NSPredicate(format: "user.userID == %@", uid as CVarArg)
        let userCollections = (try? viewContext.fetch(ucFR)) ?? []
        let cropIDsInCollection = Set(userCollections.compactMap { $0.crop?.cropID })

        // 2) Filtrar: tareas del propio usuario O tareas que pertenecen a un crop dentro de la colección
        tasks = all.filter { task in
            if let tUserID = task.user?.userID, tUserID == uid { return true }
            if let cID = task.crop?.cropID, cropIDsInCollection.contains(cID) { return true }
            return false
        }
    }
}
