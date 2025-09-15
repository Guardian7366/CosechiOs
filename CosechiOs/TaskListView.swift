import SwiftUI
import CoreData

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState
    
    @State private var tasks: [TaskEntity] = []
    @State private var filter: String = "pending" // "pending", "completed", "all"
    @State private var selectedTask: TaskEntity? = nil
    @State private var showingEdit = false
    
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
                        ForEach(todayTasks) { taskRow($0) }
                    }
                }
                
                // PRÓXIMAS
                let upcoming = filteredTasks.filter { $0.dueDate != nil && $0.dueDate! > today }
                if !upcoming.isEmpty {
                    Section(header: Text("Próximas")) {
                        ForEach(upcoming) { taskRow($0) }
                    }
                }
                
                // COMPLETADAS
                let completed = filteredTasks.filter { $0.status == "completed" }
                if !completed.isEmpty {
                    Section(header: Text("Completadas")) {
                        ForEach(completed) { taskRow($0) }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Todas mis tareas")
        .onAppear(perform: loadTasks)
        .sheet(item: $selectedTask) { task in
            EditTaskView(task: task)
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
            
            if task.status == "pending" {
                Button {
                    TaskHelper.completeTask(task, context: viewContext)
                    loadTasks()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            } else {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.gray)
            }
            
            Button {
                selectedTask = task
            } label: {
                Image(systemName: "pencil")
            }
            
            Button(role: .destructive) {
                viewContext.delete(task)
                try? viewContext.save()
                loadTasks()
            } label: {
                Image(systemName: "trash")
            }
        }
        .padding(.vertical, 4)
    }
    
    private func loadTasks() {
        guard let userID = appState.currentUserID else { return }
        let fr: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        
        // ✅ Solo tareas del usuario actual (más simple y seguro)
        fr.predicate = NSPredicate(format: "user.userID == %@", userID as CVarArg)
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)]
        
        if let results = try? viewContext.fetch(fr) {
            self.tasks = results
            print("📋 Cargadas \(results.count) tareas")
        }
    }
}
