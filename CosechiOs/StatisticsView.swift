// StatisticsView.swift
import SwiftUI
import CoreData
import Charts

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @FetchRequest(entity: TaskEntity.entity(), sortDescriptors: [])
    private var allTasks: FetchedResults<TaskEntity>

    @FetchRequest(entity: ProgressLog.entity(), sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)])
    private var allProgressLogs: FetchedResults<ProgressLog>

    @FetchRequest(entity: NotificationLog.entity(), sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)])
    private var allNotifLogs: FetchedResults<NotificationLog>

    private var userTasks: [TaskEntity] {
        guard let uid = appState.currentUserID else { return [] }
        return allTasks.filter { $0.user?.userID == uid }
    }

    private var userLogs: [ProgressLog] {
        guard let uid = appState.currentUserID else { return [] }
        return allProgressLogs.filter { $0.user?.userID == uid }
    }

    private var userNotifs: [NotificationLog] {
        Array(allNotifLogs)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(LocalizedStringKey("statistics_title"))
                    .font(.title)
                    .bold()
                    .padding(.horizontal)

                // 1. Tareas completadas vs pendientes vs atrasadas
                section("statistics_tasks") {
                    Chart {
                        BarMark(x: .value("Type", NSLocalizedString("statistics_label_completed", comment: "")),
                                y: .value("Count", completedCount))
                            .foregroundStyle(.green)
                        BarMark(x: .value("Type", NSLocalizedString("statistics_label_pending", comment: "")),
                                y: .value("Count", pendingCount))
                            .foregroundStyle(.blue)
                        BarMark(x: .value("Type", NSLocalizedString("statistics_label_overdue", comment: "")),
                                y: .value("Count", overdueCount))
                            .foregroundStyle(.red)
                    }
                    .frame(height: 220)
                }

                // 2. Evolución de logs de progreso (conteo por día)
                section("statistics_progress") {
                    if userLogs.isEmpty {
                        Text(LocalizedStringKey("statistics_no_progress"))
                            .foregroundColor(.secondary)
                    } else {
                        Chart {
                            ForEach(aggregateProgressByDay(logs: userLogs), id: \.date) { point in
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("Count", point.count)
                                )
                                PointMark(
                                    x: .value("Date", point.date),
                                    y: .value("Count", point.count)
                                )
                            }
                        }
                        .frame(height: 200)
                    }
                }

                // 3. Acciones rápidas usadas en notificaciones
                section("statistics_notifications") {
                    let counts = actionCounts
                    if counts.isEmpty {
                        Text(LocalizedStringKey("statistics_no_notifications_actions"))
                            .foregroundColor(.secondary)
                    } else {
                        Chart {
                            ForEach(counts.keys.sorted(), id: \.self) { action in
                                BarMark(
                                    x: .value("Action", action),
                                    y: .value("Count", counts[action] ?? 0)
                                )
                            }
                        }
                        .frame(height: 200)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(LocalizedStringKey("statistics_title"))
    }

    // MARK: - Métricas calculadas
    private var completedCount: Int {
        userTasks.filter { $0.status == "completed" }.count
    }
    private var pendingCount: Int {
        userTasks.filter { $0.status == "pending" }.count
    }
    private var overdueCount: Int {
        let now = Date()
        return userTasks.filter { ($0.status ?? "") != "completed" && ($0.dueDate ?? now) < now }.count
    }

    private var actionCounts: [String: Int] {
        var dict: [String: Int] = [:]
        for log in userNotifs {
            if let type = log.type, type.hasPrefix("action:") {
                let key = type.replacingOccurrences(of: "action:", with: "")
                dict[key, default: 0] += 1
            }
        }
        return dict
    }

    // MARK: - Utilidades para el gráfico de progreso
    private func aggregateProgressByDay(logs: [ProgressLog]) -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        var map: [Date: Int] = [:]
        for log in logs {
            let day = calendar.startOfDay(for: log.date ?? Date())
            map[day, default: 0] += 1
        }
        let sorted = map.map { (date: $0.key, count: $0.value) }.sorted { $0.date < $1.date }
        return sorted
    }

    // MARK: - Sección con título
    @ViewBuilder
    private func section(_ key: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey(key))
                .font(.headline)
                .padding(.horizontal)
            content()
                .padding(.horizontal)
        }
    }
}

// MARK: - Preview (contenedor en memoria con datos de ejemplo)
struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        // Crear contenedor en memoria (no afecta datos reales)
        let container = NSPersistentContainer(name: "CosechiOsModel")
        let desc = NSPersistentStoreDescription()
        desc.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [desc]
        var loadError: Error?
        container.loadPersistentStores { _, error in
            if let error = error { loadError = error }
        }
        if let e = loadError {
            fatalError("Error loading in-memory store for preview: \(e)")
        }
        let context = container.viewContext

        // Insertar datos de prueba
        let user = User(context: context)
        let userID = UUID()
        user.userID = userID
        user.username = "Preview User"
        user.email = "preview@example.com"
        user.createdAt = Date()
        user.updatedAt = Date()

        // Tasks
        let t1 = TaskEntity(context: context)
        t1.taskID = UUID()
        t1.title = "Regar tomates"
        t1.status = "pending"
        t1.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        t1.user = user

        let t2 = TaskEntity(context: context)
        t2.taskID = UUID()
        t2.title = "Fertilizar albahaca"
        t2.status = "completed"
        t2.dueDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())
        t2.user = user

        let t3 = TaskEntity(context: context)
        t3.taskID = UUID()
        t3.title = "Cosechar fresas"
        t3.status = "pending"
        t3.dueDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        t3.user = user

        // Progress logs (varias fechas)
        for i in 0..<6 {
            let log = ProgressLog(context: context)
            log.progressID = UUID()
            log.user = user
            log.date = Calendar.current.date(byAdding: .day, value: -i, to: Date())
            log.note = "Registro \(i)"
            // opcional: asociar crop
        }

        // Notification logs (acciones rápidas)
        let nl1 = NotificationLog(context: context)
        nl1.id = UUID()
        nl1.title = "Recordatorio tarea"
        nl1.body = "Tarea pendiente"
        nl1.type = "action:COMPLETE_TASK"
        nl1.date = Date()

        let nl2 = NotificationLog(context: context)
        nl2.id = UUID()
        nl2.title = "Consejo"
        nl2.body = "Tip sobre riego"
        nl2.type = "tip:seasonal"
        nl2.date = Calendar.current.date(byAdding: .day, value: -1, to: Date())

        let nl3 = NotificationLog(context: context)
        nl3.id = UUID()
        nl3.title = "Recordatorio tarea"
        nl3.body = "Tarea completada"
        nl3.type = "action:COMPLETE_TASK"
        nl3.date = Calendar.current.date(byAdding: .day, value: -2, to: Date())

        try? context.save()

        let appState = AppState()
        appState.currentUserID = userID

        return NavigationStack {
            StatisticsView()
                .environment(\.managedObjectContext, context)
                .environmentObject(appState)
        }
    }
}
