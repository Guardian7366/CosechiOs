import SwiftUI
import CoreData

struct TaskSummaryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @FetchRequest(
        entity: TaskEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)],
        animation: .default
    )
    private var allTasks: FetchedResults<TaskEntity>

    private var filteredTasks: [TaskEntity] {
        guard let uid = appState.currentUserID else { return [] }
        return allTasks.filter { $0.user?.userID == uid }
    }

    private var pendingTasks: Int {
        filteredTasks.filter { $0.status == "pending" }.count
    }

    private var completedTasks: Int {
        filteredTasks.filter { $0.status == "completed" }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Resumen de tareas")
                .font(.headline)

            HStack {
                Text("Pendientes: \(pendingTasks)")
                    .foregroundColor(.orange)
                Spacer()
                Text("Completadas: \(completedTasks)")
                    .foregroundColor(.green)
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
