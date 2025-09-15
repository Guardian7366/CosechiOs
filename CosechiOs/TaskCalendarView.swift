import SwiftUI
import CoreData

struct TaskCalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState
    
    @State private var tasks: [TaskEntity] = []
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
            .navigationTitle("calendar_tasks")
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
            .sheet(item: $showingEditTaskID) { wrapper in
                EditTaskView(taskID: wrapper.id)
                    .environment(\.managedObjectContext, viewContext)
                    .onDisappear(perform: loadTasks)
            }
            .onAppear(perform: loadTasks)
            .onChange(of: appState.currentUserID) { _ in loadTasks() }
        }
    }
    
    // MARK: - Helpers
    
    private var groupedDates: [Date] {
        groupedTasks.keys.sorted()
    }
    
    private var groupedTasks: [Date: [TaskEntity]] {
        Dictionary(grouping: tasks) { task in
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
            Button(action: {
                TaskHelper.toggleCompletion(for: task.objectID, context: viewContext) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { loadTasks() }
                }
            }) {
                Image(systemName: task.status == "completed" ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.status == "completed" ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading) {
                Text(task.title ?? "")
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
                DispatchQueue.main.async {
                    loadTasks()
                }
            } catch {
                print("❌ Error al eliminar tasks: \(error)")
                viewContext.rollback()
            }
        }
    }
    
    private func loadTasks() {
        let fr: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)]
        do {
            let all = try viewContext.fetch(fr)
            guard let uid = appState.currentUserID else { tasks = []; return }

            // Sólo tareas creadas por este usuario
            tasks = all.filter { $0.user?.userID == uid }
            print("📋 TaskCalendarView.loadTasks -> \(tasks.count) tasks for user \(uid)")
        } catch {
            print("❌ TaskCalendarView.loadTasks fetch error: \(error)")
            tasks = []
        }
    }

}
