import SwiftUI
import CoreData

struct TaskCalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @State private var tasks: [TaskEntity] = []
    @State private var showingEditTaskID: ManagedObjectIDWrapper?

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
                    NavigationLink(destination: AddTaskView().environmentObject(appState)) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $showingEditTaskID) { (wrapper: ManagedObjectIDWrapper) in
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

    private func toggleTaskCompletion(_ task: TaskEntity) {
        task.status = (task.status == "completed") ? "pending" : "completed"
        task.updatedAt = Date()
        try? viewContext.save()

        if task.status == "completed" {
            NotificationHelper.cancelNotification(for: task)
        } else if task.status == "pending", task.reminder {
            TaskHelper.scheduleNotification(for: task)
        }
        loadTasks()
    }

    private func deleteTask(at offsets: IndexSet, in tasksForSection: [TaskEntity]) {
        for index in offsets {
            let task = tasksForSection[index]
            NotificationHelper.cancelNotification(for: task)
            viewContext.delete(task)
        }
        try? viewContext.save()
        loadTasks()
    }

    private func taskRow(_ task: TaskEntity) -> some View {
        HStack {
            Button(action: { toggleTaskCompletion(task) }) {
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
                showingEditTaskID = ManagedObjectIDWrapper(id: task.objectID)
            } label: {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
        }
    }

    // MARK: - Carga de datos

    private func loadTasks() {
        let fr: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)]
        let all = (try? viewContext.fetch(fr)) ?? []

        guard let uid = appState.currentUserID else {
            tasks = []
            return
        }

        // cultivos del usuario
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
