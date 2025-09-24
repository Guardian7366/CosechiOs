// TaskListView.swift
import SwiftUI
import CoreData

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState
    
    @FetchRequest(
        entity: TaskEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)],
        animation: .default
    )
    private var allTasks: FetchedResults<TaskEntity>

    @State private var filter: String = "pending" // "pending", "completed", "all"
    @State private var selectedTaskID: ManagedObjectIDWrapper? = nil
    @State private var showDeleteAlertFor: ManagedObjectIDWrapper? = nil

    private var today: Date { Calendar.current.startOfDay(for: Date()) }

    var body: some View {
        FrutigerAeroBackground {
            VStack {
                // 🔹 Filtro de tareas
                Picker("task_filter", selection: $filter) {
                    Text("task_pending").tag("pending")
                    Text("task_completed").tag("completed")
                    Text("task_all").tag("all")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.12))
                )
                .padding(.top, 12)
                .accessibilityLabel(Text("task_filter"))
                .accessibilityHint(Text("Selecciona un filtro de tareas"))

                // 🔹 Lista de tareas
                List {
                    // HOY
                    let todayTasks = filteredTasks.filter {
                        $0.dueDate != nil && Calendar.current.isDateInToday($0.dueDate!)
                    }
                    if !todayTasks.isEmpty {
                        Section(header: Text("task_today").font(.headline)) {
                            ForEach(todayTasks, id: \.objectID) { task in
                                taskRow(task)
                            }
                            .listRowBackground(Color.clear)
                        }
                        .accessibilityLabel(Text("task_today"))
                    }

                    // PRÓXIMAS
                    let upcoming = filteredTasks.filter {
                        $0.dueDate != nil && $0.dueDate! > today
                    }
                    if !upcoming.isEmpty {
                        Section(header: Text("task_upcoming").font(.headline)) {
                            ForEach(upcoming, id: \.objectID) { task in
                                taskRow(task)
                            }
                            .listRowBackground(Color.clear)
                        }
                        .accessibilityLabel(Text("task_upcoming"))
                    }

                    // COMPLETADAS
                    let completed = filteredTasks.filter { $0.status == "completed" }
                    if !completed.isEmpty {
                        Section(header: Text("task_completed").font(.headline)) {
                            ForEach(completed, id: \.objectID) { task in
                                taskRow(task)
                            }
                            .listRowBackground(Color.clear)
                        }
                        .accessibilityLabel(Text("task_completed"))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden) // 👈 elimina fondo gris por defecto
            }
        }
        .navigationTitle("menu_all_tasks")
        .sheet(item: $selectedTaskID) { wrapper in
            EditTaskView(taskID: wrapper.id)
                .environment(\.managedObjectContext, viewContext)
        }
        .alert(item: $showDeleteAlertFor) { wrapper in
            Alert(
                title: Text("task_delete_title"),
                message: Text("task_delete_message"),
                primaryButton: .destructive(Text("delete")) {
                    deleteTask(by: wrapper.id)
                },
                secondaryButton: .cancel(Text("cancel"))
            )
        }
    }

    // MARK: - Helpers

    private var filteredTasks: [TaskEntity] {
        guard let uid = appState.currentUserID else { return [] }

        return allTasks.filter { task in
            task.user?.userID == uid
        }
        .filter { task in
            switch filter {
            case "pending": return task.status == "pending"
            case "completed": return task.status == "completed"
            default: return true
            }
        }
    }

    @ViewBuilder
    private func taskRow(_ task: TaskEntity) -> some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title ?? NSLocalizedString("task_no_title", comment: ""))
                        .font(.headline)
                        .foregroundColor(.primary)
                        .strikethrough(task.status == "completed")

                    if let due = task.dueDate {
                        Text("task_due_prefix \(due.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let crop = task.crop {
                        Text("\(NSLocalizedString("task_crop_prefix", comment: "")) \(crop.name ?? "-")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()

                if task.status == "pending" {
                    Button {
                        completeTask(task)
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .aeroIcon(size: 22)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Marcar como completada"))
                    .accessibilityHint(Text("Completa esta tarea"))
                } else {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.gray)
                        .aeroIcon(size: 22)
                        .accessibilityLabel(Text("Tarea completada"))
                }

                Button {
                    selectedTaskID = ManagedObjectIDWrapper(id: task.objectID)
                } label: {
                    Image(systemName: "pencil")
                        .aeroIcon(size: 20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Editar tarea"))

                Button(role: .destructive) {
                    showDeleteAlertFor = ManagedObjectIDWrapper(id: task.objectID)
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .aeroIcon(size: 20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Eliminar tarea"))
                .accessibilityHint(Text("Muestra una alerta para confirmar eliminación"))
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(task.title ?? NSLocalizedString("task_no_title", comment: "")))
        .accessibilityValue(Text(task.status == "completed" ? "Completada" : "Pendiente"))
    }

    private func completeTask(_ task: TaskEntity) {
        task.status = "completed"
        task.updatedAt = Date()
        NotificationHelper.cancelNotification(for: task)
        do {
            try viewContext.save()
        } catch {
            print("❌ Error guardando completion: \(error)")
            viewContext.rollback()
        }
    }

    private func deleteTask(by objectID: NSManagedObjectID) {
        viewContext.perform {
            do {
                if let t = try viewContext.existingObject(with: objectID) as? TaskEntity {
                    NotificationHelper.cancelNotification(for: t)
                    viewContext.delete(t)
                    try viewContext.save()
                    print("🗑️ Tarea eliminada: \(t.title ?? "—")")
                }
            } catch {
                print("❌ Error al eliminar tarea: \(error)")
                viewContext.rollback()
            }
            debugPrintCounts()
        }
    }

    private func debugPrintCounts() {
        let tfr: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        let ufr: NSFetchRequest<User> = User.fetchRequest()
        let cfr: NSFetchRequest<Crop> = Crop.fetchRequest()
        let ucfr: NSFetchRequest<UserCollection> = UserCollection.fetchRequest()
        let tcount = (try? viewContext.count(for: tfr)) ?? -1
        let ucount = (try? viewContext.count(for: ufr)) ?? -1
        let ccount = (try? viewContext.count(for: cfr)) ?? -1
        let uccount = (try? viewContext.count(for: ucfr)) ?? -1
        print("DEBUG counts -> Tasks:\(tcount) Users:\(ucount) Crops:\(ccount) UserCollections:\(uccount)")
    }
}
