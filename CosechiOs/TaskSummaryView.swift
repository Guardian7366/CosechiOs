// TaskSummaryView.swift
import SwiftUI
import CoreData

struct TaskSummaryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: AeroTheme

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
        VStack(alignment: .leading, spacing: 8) {
            Text("task_summary_title")
                .font(.headline)
                .foregroundColor(.white)
                .accessibilityLabel(NSLocalizedString("task_summary_title", comment: ""))

            HStack {
                Text("\(NSLocalizedString("task_pending", comment: "")): \(pendingTasks)")
                    .foregroundColor(theme.accent)
                    .accessibilityLabel("\(NSLocalizedString("task_pending", comment: "")): \(pendingTasks)")
                Spacer()
                Text("\(NSLocalizedString("task_completed", comment: "")): \(completedTasks)")
                    .foregroundColor(theme.mint)
                    .accessibilityLabel("\(NSLocalizedString("task_completed", comment: "")): \(completedTasks)")
            }
            .font(.subheadline).bold()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityHint(NSLocalizedString("task_summary_hint", comment: ""))
    }
}
