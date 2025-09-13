import SwiftUI
import CoreData

struct TaskCalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    // Uso explícito de entity(...) para evitar problemas de inferencia del compilador
    @FetchRequest(
        entity: TaskEntity.entity(),
        sortDescriptors: [NSSortDescriptor(key: "dueDate", ascending: true)]
    )
    private var tasks: FetchedResults<TaskEntity>

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
                    NavigationLink(destination: AddTaskView()) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $showingEditTask) { task in
                EditTaskView(task: task)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    // MARK: - Helpers

    /// Agrupa las tareas por fecha (startOfDay)
    private var groupedTasks: [Date: [TaskEntity]] {
        let arr = Array(tasks) // forzar arreglo para evitar inferencia compleja
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
        if task.status == "completed", let id = task.taskID?.uuidString {
            NotificationHelper.cancelNotification(id: id)
        } else if task.status == "pending", task.reminder {
            TaskHelper.scheduleNotification(for: task)
        }
    }

    /// Elimina tareas a partir de offsets dentro del array `tasksForSection`
    private func deleteTask(at offsets: IndexSet, in tasksForSection: [TaskEntity]) {
        for index in offsets {
            let task = tasksForSection[index]
            if let id = task.taskID?.uuidString {
                NotificationHelper.cancelNotification(id: id)
            }
            viewContext.delete(task)
        }
        try? viewContext.save()
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
}

// MARK: - Preview
#Preview {
    TaskCalendarView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(AppState())
}
