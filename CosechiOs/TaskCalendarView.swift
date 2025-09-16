import SwiftUI
import CoreData

struct TaskCalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    // FetchRequest en vivo: cualquier cambio en Core Data actualizará esta colección.
    @FetchRequest(
        entity: TaskEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)],
        animation: .default
    )
    private var allTasks: FetchedResults<TaskEntity>

    @State private var showingEditTaskID: ManagedObjectIDWrapper? = nil

    var body: some View {
        NavigationStack {
            VStack {
                TaskSummaryView()
                    .environment(\.managedObjectContext, viewContext)
                    .padding(.horizontal)

                List {
                    ForEach(groupedDates, id: \.self) { date in
                        Section(header: Text(formattedDate(date))) {
                            let items = groupedTasks[date] ?? []
                            ForEach(items, id: \.objectID) { task in
                                taskRow(task)
                            }
                            .onDelete { offsets in
                                deleteTask(at: offsets, in: items)
                            }
                        }
                    }
                }
            }
            .navigationTitle("menu_tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(
                        destination: AddTaskView()
                            .environment(\.managedObjectContext, viewContext)
                            .environmentObject(appState)
                    ) {
                        Image(systemName: "plus")
                    }
                }
            }
            // editar tarea
            .sheet(item: $showingEditTaskID) { wrapper in
                EditTaskView(taskID: wrapper.id)
                    .environment(\.managedObjectContext, viewContext)
                    .onDisappear {
                        // no suele ser necesario, FetchRequest se actualiza automáticamente,
                        // pero forzamos pequeño refresco visual por si acaso
                        DispatchQueue.main.async { /* noop */ }
                    }
            }
            .onAppear {
                // Si quieres forzar carga inicial (no estrictamente necesario)
                print("TaskCalendarView appear, total fetched tasks: \(allTasks.count)")
            }
            // cuando cambia de usuario, SwiftUI reevaluará las computed props y la lista
            .onChange(of: appState.currentUserID) { _ in
                // no-op: kept for clarity; fetch request + computed properties handle updates
            }
        }
    }

    // MARK: - Computed helpers using live fetched results

    /// tareas filtradas por usuario actual (las que el usuario creó)
    private var tasksForUser: [TaskEntity] {
        guard let uid = appState.currentUserID else { return [] }
        return allTasks.filter { $0.user?.userID == uid }
    }

    private var groupedDates: [Date] {
        groupedTasks.keys.sorted()
    }

    private var groupedTasks: [Date: [TaskEntity]] {
        Dictionary(grouping: tasksForUser) { task in
            Calendar.current.startOfDay(for: task.dueDate ?? Date())
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .full
        df.timeStyle = .none
        return df.string(from: date)
    }

    private func taskRow(_ task: TaskEntity) -> some View {
        HStack {
            // completar (toggle) — TaskHelper hace save en background; FetchRequest actualizará la UI
            Button(action: {
                TaskHelper.toggleCompletion(for: task.objectID, context: viewContext) {
                    // nada extra necesario: FetchRequest actualizará vista cuando Core Data cambie.
                    // si quieres animación:
                    DispatchQueue.main.async {
                        withAnimation { /* noop to hint update */ }
                    }
                }
            }) {
                Image(systemName: task.status == "completed" ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.status == "completed" ? .green : .gray)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading) {
                Text(task.title ?? NSLocalizedString("task_no_title", comment: ""))
                    .strikethrough(task.status == "completed")
                    .font(.body)
                if let details = task.details, !details.isEmpty {
                    Text(details).font(.caption).foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                showingEditTaskID = ManagedObjectIDWrapper(id: task.objectID)
            } label: {
                Image(systemName: "pencil").foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
    }

    private func deleteTask(at offsets: IndexSet, in tasksForSection: [TaskEntity]) {
        let toDelete = offsets.compactMap { index -> TaskEntity? in
            guard index < tasksForSection.count else { return nil }
            return tasksForSection[index]
        }

        guard !toDelete.isEmpty else { return }

        viewContext.perform {
            for t in toDelete {
                NotificationHelper.cancelNotification(for: t)
                viewContext.delete(t)
            }
            do {
                try viewContext.save()
            } catch {
                print("❌ Error al eliminar tasks: \(error)")
                viewContext.rollback()
            }
        }
    }
}
