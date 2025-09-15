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
                    let dates = groupedDates
                    ForEach(dates, id: \.self) { date in
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
                    NavigationLink(destination: AddTaskView().environment(\.managedObjectContext, viewContext)) {
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
        for index in offsets {
            let task = tasksForSection[index]
            TaskHelper.deleteTask(with: task.objectID, context: viewContext) {
                // nothing
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { loadTasks() }
    }

    private func loadTasks() {
        let fr: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)]
        do {
            let all = try viewContext.fetch(fr)
            guard let uid = appState.currentUserID else { tasks = []; return }

            // Filtrar: tareas que pertenecen al user OR tareas attachadas a crops en su colección
            // 1) obtener cropIDs de la colección
            let ucFR: NSFetchRequest<UserCollection> = UserCollection.fetchRequest()
            ucFR.predicate = NSPredicate(format: "user.userID == %@", uid as CVarArg)
            let userCollections = (try? viewContext.fetch(ucFR)) ?? []
            let cropIDsInCollection = Set(userCollections.compactMap { $0.crop?.cropID })

            // 2) filtrar
            tasks = all.filter { task in
                if let tUserID = task.user?.userID, tUserID == uid { return true }
                if let cID = task.crop?.cropID, cropIDsInCollection.contains(cID) { return true }
                return false
            }
            print("📋 TaskCalendarView.loadTasks -> \(tasks.count) tasks for user \(uid)")
        } catch {
            print("❌ TaskCalendarView.loadTasks fetch error: \(error)")
            tasks = []
        }
    }
}
