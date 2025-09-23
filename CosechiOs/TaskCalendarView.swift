// TaskCalendarView.swift
import SwiftUI
import CoreData

struct TaskCalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @FetchRequest(
        entity: TaskEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)],
        animation: .default
    )
    private var allTasks: FetchedResults<TaskEntity>

    @State private var showingEditTaskID: ManagedObjectIDWrapper? = nil

    var body: some View {
        FrutigerAeroBackground {
            VStack(spacing: 16) {
                // 🔹 Resumen directamente con su propio estilo
                TaskSummaryView()
                    .environment(\.managedObjectContext, viewContext)
                    .padding(.horizontal)

                // 🔹 Lista de tareas agrupadas
                List {
                    ForEach(groupedDates, id: \.self) { date in
                        Section(header: Text(formattedDate(date))
                            .font(.headline)
                            .foregroundColor(.white)) {

                            let items = groupedTasks[date] ?? []
                            ForEach(items, id: \.objectID) { task in
                                taskRow(task)
                                    .listRowBackground(Color.clear)
                            }
                            .onDelete { offsets in
                                deleteTask(at: offsets, in: items)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
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
                        .foregroundColor(.white)
                        .aeroIcon(size: 20)
                }
            }
        }
        .sheet(item: $showingEditTaskID) { wrapper in
            EditTaskView(taskID: wrapper.id)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    // MARK: - Helpers
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
        return df.string(from: date)
    }

    // MARK: - Row
    private func taskRow(_ task: TaskEntity) -> some View {
        GlassCard {
            HStack {
                Button {
                    TaskHelper.toggleCompletion(for: task.objectID, context: viewContext) {
                        DispatchQueue.main.async { withAnimation {} }
                    }
                } label: {
                    Image(systemName: task.status == "completed" ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.status == "completed" ? .green : .gray)
                        .aeroIcon(size: 22)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title ?? NSLocalizedString("task_no_title", comment: ""))
                        .strikethrough(task.status == "completed")
                        .foregroundColor(.primary)
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
                        .aeroIcon(size: 18)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Delete
    private func deleteTask(at offsets: IndexSet, in tasksForSection: [TaskEntity]) {
        let toDelete = offsets.compactMap { index in
            index < tasksForSection.count ? tasksForSection[index] : nil
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
