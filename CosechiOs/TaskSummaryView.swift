import SwiftUI
import CoreData

struct TaskSummaryView: View {
    @FetchRequest(
        entity: TaskEntity.entity(),
        sortDescriptors: [NSSortDescriptor(key: "dueDate", ascending: true)]
    )
    private var tasks: FetchedResults<TaskEntity>
    
    private var total: Int { tasks.count }
    private var completed: Int { tasks.filter { $0.status == "completed" }.count }
    private var pending: Int { tasks.filter { $0.status != "completed" && ($0.dueDate ?? Date()) >= Date() }.count }
    private var overdue: Int { tasks.filter { $0.status != "completed" && ($0.dueDate ?? Date()) < Date() }.count }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("task_summary_title")
                .font(.headline)
            
            HStack {
                summaryItem(color: .green, count: completed, label: "task_completed")
                summaryItem(color: .orange, count: pending, label: "task_pending")
                summaryItem(color: .red, count: overdue, label: "task_overdue")
            }
            
            if total > 0 {
                ProgressView(value: Double(completed), total: Double(total)) {
                    Text("task_progress")
                }
                .progressViewStyle(.linear)
                .padding(.top, 8)
            } else {
                Text("task_no_tasks")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func summaryItem(color: Color, count: Int, label: LocalizedStringKey) -> some View {
        VStack {
            Text("\(count)")
                .font(.title2)
                .bold()
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TaskSummaryView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
