// DashboardView.swift
import SwiftUI
import CoreData
import UIKit

/// Dashboard principal - resumen y accesos rápidos para el usuario.
struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    // FetchRequests generales
    @FetchRequest(entity: TaskEntity.entity(), sortDescriptors: [NSSortDescriptor(key: "dueDate", ascending: true)])
    private var allTasks: FetchedResults<TaskEntity>
    @FetchRequest(entity: UserCollection.entity(), sortDescriptors: [NSSortDescriptor(key: "addedAt", ascending: false)])
    private var allUserCollections: FetchedResults<UserCollection>
    @FetchRequest(entity: Crop.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
    private var allCrops: FetchedResults<Crop>
    @FetchRequest(entity: ProgressLog.entity(), sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)])
    private var allProgressLogs: FetchedResults<ProgressLog>
    @FetchRequest(entity: User.entity(), sortDescriptors: [])
    private var allUsers: FetchedResults<User>

    @State private var showAddTask = false
    @State private var showExplore = false
    @State private var showDebugMenu = false

    // Recomendaciones
    @State private var recommendations: [CropRecommendation] = []
    @State private var isLoadingRecommendations = false
    @State private var recMessage: String? = nil

    var body: some View {
        NavigationStack {
            FrutigerAeroBackground {
                ScrollView {
                    VStack(spacing: 16) {
                        headerView

                        GlassCard { summaryCardContent }
                            .padding(.horizontal)

                        GlassCard { metricsCardContent }
                            .padding(.horizontal)

                        GlassCard { quickActions }
                            .padding(.horizontal)

                        sectionTitle("recommendations_title")
                            .padding(.horizontal)
                            .padding(.top, 6)

                        recommendationsStrip

                        sectionTitle("dashboard_upcoming_tasks")
                            .padding(.horizontal)
                            .padding(.top, 6)

                        upcomingTasksList

                        sectionTitle("dashboard_my_crops")
                            .padding(.horizontal)
                            .padding(.top, 12)

                        cropsCollectionStrip

                        sectionTitle("dashboard_recent_progress")
                            .padding(.horizontal)
                            .padding(.top, 12)

                        recentProgressList

                        Spacer(minLength: 24)
                    }
                    .padding(.top)
                    .frame(maxWidth: .infinity) // 🔹 opcional, ayuda a centrar
                }
                .navigationTitle(LocalizedStringKey("dashboard_title"))
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(LocalizedStringKey("dashboard_title"))
                            .font(.headline)
                            .onTapGesture(count: 3) { showDebugMenu = true }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 12) {
                            Button { showAddTask = true } label: {
                                Image(systemName: "plus")
                            }
                            NavigationLink(destination: UserProfileView()) {
                                Image(systemName: "person.crop.circle")
                            }
                        }
                    }
                }
                .sheet(isPresented: $showAddTask) {
                    AddTaskView()
                        .environment(\.managedObjectContext, viewContext)
                        .environmentObject(appState)
                }
                .onAppear { loadRecommendations() }
                .onChange(of: appState.currentUserID) { _ in loadRecommendations() }
            }
        }
        .navigationDestination(isPresented: $showDebugMenu) {
            DebugNotificationsView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(appState)
        }
    }

    // MARK: - Data filtrada
    private var currentUser: User? {
        guard let uid = appState.currentUserID else { return nil }
        return allUsers.first { $0.userID == uid }
    }
    private var cropsInCollection: [Crop] {
        guard let uid = appState.currentUserID else { return [] }
        let collections = allUserCollections.filter { $0.user?.userID == uid }
        return collections.compactMap { $0.crop }
    }
    private var tasksRelevant: [TaskEntity] {
        guard let uid = appState.currentUserID else { return [] }
        return Array(allTasks).filter { $0.user?.userID == uid }
    }
    private var upcomingTasks: [TaskEntity] {
        let now = Date()
        return tasksRelevant.filter {
            ($0.status ?? "pending") != "completed" && ($0.dueDate ?? .distantFuture) >= now
        }
        .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }
    private var totalTasksCount: Int { tasksRelevant.count }
    private var completedTasksCount: Int { tasksRelevant.filter { $0.status == "completed" }.count }
    private var pendingTasksCount: Int { tasksRelevant.filter { $0.status == "pending" }.count }
    private var overdueCount: Int {
        let now = Date()
        return tasksRelevant.filter { ($0.status ?? "") != "completed" && ($0.dueDate ?? Date()) < now }.count
    }
    private var recentProgress: [ProgressLog] {
        guard let uid = appState.currentUserID else { return [] }
        return allProgressLogs.filter { $0.user?.userID == uid }
    }
    private var progressLogsCount: Int { recentProgress.count }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let user = currentUser {
                    Text("\(LocalizationHelper.shared.localized("dashboard_greeting")) \(user.username ?? "")")
                        .font(.title2).bold()
                        .minimumScaleFactor(0.9)
                        .lineLimit(1)
                } else {
                    Text(LocalizationHelper.shared.localized("dashboard_greeting"))
                        .font(.title2).bold()
                }
                Text(LocalizationHelper.shared.localized("dashboard_subtitle"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: - Summary
    private var summaryCardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(LocalizationHelper.shared.localized("dashboard_summary"))
                        .font(.headline)
                    Text("\(totalTasksCount) " + LocalizationHelper.shared.localized("dashboard_tasks"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(completedTasksCount)/\(totalTasksCount)")
                        .font(.title3).bold()
                    Text(LocalizationHelper.shared.localized("dashboard_completed"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if totalTasksCount > 0 {
                ProgressView(value: Double(completedTasksCount), total: Double(max(totalTasksCount, 1)))
                    .progressViewStyle(.linear)
            } else {
                Text(LocalizationHelper.shared.localized("dashboard_no_tasks"))
                    .foregroundColor(.secondary)
            }

            if overdueCount > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
                    Text(String(format: LocalizationHelper.shared.localized("dashboard_overdue_count"), overdueCount))
                        .font(.caption).foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Metrics
    private var metricsCardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizationHelper.shared.localized("dashboard_metrics_title"))
                .font(.headline)
            HStack(spacing: 16) {
                metricColumn(color: .green, value: completedTasksCount, key: "dashboard_metrics_completed")
                metricColumn(color: .blue, value: pendingTasksCount, key: "dashboard_metrics_pending")
                metricColumn(color: .red, value: overdueCount, key: "dashboard_metrics_overdue")
            }
            Divider()
            HStack {
                Image(systemName: "chart.bar.fill").foregroundColor(.blue)
                Text("\(progressLogsCount) " + LocalizationHelper.shared.localized("dashboard_metrics_progresslogs"))
                    .font(.subheadline).foregroundColor(.secondary)
            }
        }
    }
    private func metricColumn(color: Color, value: Int, key: String) -> some View {
        VStack {
            Text("\(value)").font(.title2).bold().foregroundColor(color)
            Text(LocalizationHelper.shared.localized(key))
                .font(.caption).foregroundColor(.secondary)
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private var quickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                NavigationLink(destination: AddTaskView().environment(\.managedObjectContext, viewContext)) {
                    QuickActionButton(icon: "plus.circle.fill", titleKey: "dashboard_action_add_task", color: .green)
                }
                NavigationLink(destination: ExploreCropsView().environment(\.managedObjectContext, viewContext)) {
                    QuickActionButton(icon: "leaf.circle.fill", titleKey: "dashboard_action_explore", color: .blue)
                }
                NavigationLink(destination: MyCropsView().environment(\.managedObjectContext, viewContext)) {
                    QuickActionButton(icon: "tray.full.fill", titleKey: "dashboard_action_my_crops", color: .teal)
                }
                NavigationLink(destination: UserProfileView().environmentObject(appState)) {
                    QuickActionButton(icon: "person.crop.circle.fill", titleKey: "dashboard_action_profile", color: .gray)
                }
                NavigationLink(destination: StatisticsView().environment(\.managedObjectContext, viewContext).environmentObject(appState)) {
                    QuickActionButton(icon: "chart.bar.fill", titleKey: "dashboard_action_statistics", color: .purple)
                }
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: 110) // 🔹 asegura que no se recorte verticalmente
    }
    
    // MARK: - Recommendations
    private var recommendationsStrip: some View {
        VStack(spacing: 8) {
            if isLoadingRecommendations {
                ProgressView().padding(.horizontal)
            } else if recommendations.isEmpty {
                Text(LocalizationHelper.shared.localized("recommendations_no_results"))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(recommendations.prefix(4)) { rec in
                            GlassCard{
                                VStack(alignment: .leading, spacing: 6) {
                                    if let data = rec.crop.imageData, let ui = UIImage(data: data) {
                                        Image(uiImage: ui)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 140, height: 80)
                                            .clipped()
                                            .cornerRadius(8)
                                    } else if let imgName = rec.crop.imageName, !imgName.isEmpty, UIImage(named: imgName) != nil {
                                        Image(imgName)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 140, height: 80)
                                            .clipped()
                                            .cornerRadius(8)
                                    } else {
                                        ZStack {
                                            Color.green.opacity(0.18)
                                            Image(systemName: "leaf.fill")
                                                .font(.largeTitle).foregroundColor(.white)
                                        }
                                        .frame(width: 140, height: 80)
                                        .cornerRadius(8)
                                    }

                                    Text(LocalizationHelper.shared.localized(rec.crop.name ?? "crop_default"))
                                        .font(.subheadline).bold()
                                        .lineLimit(1).minimumScaleFactor(0.9)
                                    Text(LocalizationHelper.shared.localized(rec.crop.category ?? ""))
                                        .font(.caption2).foregroundColor(.secondary)

                                    HStack {
                                        Button {
                                            addCropToCollection(rec.crop)
                                        } label: {
                                            Text(LocalizedStringKey("recommendations_add"))
                                                .font(.caption2)
                                        }
                                        .buttonStyle(.borderedProminent)

                                        Spacer()

                                        Text("\(Int(rec.score))")
                                            .font(.caption2)
                                            .padding(6)
                                            .background(Color.white.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                }
                                
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.green.opacity(0.06))
                                    )
                            }
                            .frame(minWidth: 140, maxWidth: 160)
                        }

                        NavigationLink(destination: RecommendedCropsView().environmentObject(appState)) {
                            VStack {
                                ZStack {
                                    Circle().fill(Color.green.opacity(0.2)).frame(width: 64, height: 64)
                                    Image(systemName: "chevron.right").foregroundColor(.green)
                                }
                                Text(LocalizedStringKey("recommendations_title"))
                                    .font(.caption2)
                            }
                            .frame(width: 120, height: 120)
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false) // 🔹 evita desbordamiento
                    .padding(.horizontal)
                }
                .frame(minHeight: 160) // 🔹 asegura altura suficiente para cards
            }
        }
    }

    // MARK: - Upcoming tasks list
    private var upcomingTasksList: some View {
        VStack(spacing: 8) {
            if upcomingTasks.isEmpty {
                Text(LocalizationHelper.shared.localized("dashboard_no_upcoming"))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(upcomingTasks.prefix(5), id: \.objectID) { task in
                    NavigationLink(destination: destinationForTask(task)) {
                        TaskRowCompact(task: task) {
                            TaskHelper.completeTask(task, context: viewContext)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Crops in collection strip
    private var cropsCollectionStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if cropsInCollection.isEmpty {
                    Text(LocalizationHelper.shared.localized("dashboard_no_crops"))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                } else {
                    ForEach(cropsInCollection, id: \.objectID) { crop in
                        NavigationLink(destination: CropDetailView(crop: crop)
                                        .environment(\.managedObjectContext, viewContext)
                                        .environmentObject(appState)
                        ) {
                            CropCardView(crop: crop)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .fixedSize(horizontal: true, vertical: false) // 🔹 asegura que no se desborde
            .padding(.horizontal)
        }
        .frame(minHeight: 170) // 🔹 evita recortes en cultivos
    }

    // MARK: - Recent progress list
    private var recentProgressList: some View {
        VStack(spacing: 10) {
            if recentProgress.isEmpty {
                Text(LocalizationHelper.shared.localized("dashboard_no_progress"))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(recentProgress.prefix(6), id: \.objectID) { log in
                    ProgressLogRow(log: log)
                        .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Helper UI components (internos)

    @ViewBuilder
    private func sectionTitle(_ key: String) -> some View {
        HStack {
            Text(LocalizationHelper.shared.localized(key))
                .font(.headline)
            Spacer()
        }
    }

    private func destinationForTask(_ task: TaskEntity) -> some View {
        if let crop = task.crop {
            return AnyView(CropDetailView(crop: crop)
                            .environment(\.managedObjectContext, viewContext)
                            .environmentObject(appState))
        } else {
            return AnyView(EditTaskView(taskID: task.objectID ))
        }
    }

    // Compact task row
    private func TaskRowCompact(task: TaskEntity, onComplete: @escaping () -> Void) -> some View {
        HStack {
            Button(action: onComplete) {
                Image(systemName: task.status == "completed" ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.status == "completed" ? .green : .gray)
            }

            VStack(alignment: .leading) {
                Text(task.title ?? "")
                    .font(.subheadline)
                    .strikethrough(task.status == "completed")
                if let d = task.dueDate {
                    Text(d, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if let crop = task.crop {
                Text(LocalizationHelper.shared.localized(crop.name ?? ""))
                    .font(.caption2)
                    .padding(6)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.02), radius: 1, x: 0, y: 1)
    }

    private func CropCardView(crop: Crop) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let data = crop.imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 90)
                    .clipped()
                    .cornerRadius(8)
            } else if let imgName = crop.imageName, !imgName.isEmpty, UIImage(named: imgName) != nil {
                Image(imgName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 90)
                    .clipped()
                    .cornerRadius(8)
            } else {
                ZStack {
                    Color(.systemGray5)
                    Image(systemName: "leaf.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }
                .frame(width: 140, height: 90)
                .cornerRadius(8)
            }

            // Localización para nombre y categoría
            Text(LocalizationHelper.shared.localized(crop.name ?? ""))
                .font(.subheadline).bold()
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text(LocalizationHelper.shared.localized(crop.category ?? ""))
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(minWidth: 120, maxWidth: 140)
        .padding(8)
        .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.06)) // mismo estilo verdoso Frutigero Aero
                )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }

    private func ProgressLogRow(log: ProgressLog) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if let data = log.imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 60)
                    .overlay(Image(systemName: "photo.on.rectangle.angled").foregroundColor(.white))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(LocalizationHelper.shared.localized(log.crop?.name ?? "dashboard_progress_log_no_crop"))
                        .font(.subheadline).bold()
                    Spacer()
                    Text(log.date ?? Date(), style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if let note = log.note {
                    Text(note).font(.caption)
                } else {
                    Text(LocalizedStringKey("dashboard_progress_no_note"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    // MARK: - Recomendaciones: funciones (lógica intacta)
    private func loadRecommendations() {
        isLoadingRecommendations = true
        DispatchQueue.global(qos: .userInitiated).async {
            let recs = RecommendationHelper.recommendCrops(
                context: viewContext,
                forUserID: appState.currentUserID,
                maxResults: 8
            )
            DispatchQueue.main.async {
                self.recommendations = recs
                self.isLoadingRecommendations = false
                // analytics: marcar mostradas
                recs.forEach { if let id = $0.crop.cropID { RecommendationAnalytics.logShown(cropID: id) } }
            }
        }
    }

    private func addCropToCollection(_ crop: Crop) {
        guard let uid = appState.currentUserID else {
            recMessage = NSLocalizedString("recommendations_error_not_logged", comment: "")
            return
        }
        do {
            let added = try RecommendationHelper.addCropToUserCollection(
                crop: crop,
                userID: uid,
                context: viewContext
            )
            if added {
                recMessage = NSLocalizedString("recommendations_added", comment: "")
                if let id = crop.cropID { RecommendationAnalytics.logAccepted(cropID: id) }
                // --- Otorgar XP por aceptar recomendación
                AchievementManager.award(action: .acceptRecommendation, to: uid, context: viewContext)
            } else {
                recMessage = NSLocalizedString("recommendations_in_collection", comment: "")
            }
            // recarga recomendaciones y notifica otras vistas
            loadRecommendations()
        } catch {
            recMessage = error.localizedDescription
        }
    }

    // MARK: - QuickActionButton
        private struct QuickActionButton: View {
            let icon: String
            let titleKey: String
            let color: Color
            var body: some View {
                VStack {
                    ZStack {
                        Circle().fill(color.opacity(0.18)).frame(width: 48, height: 48)
                        Image(systemName: icon).font(.title2).foregroundColor(color)
                    }
                    Text(LocalizationHelper.shared.localized(titleKey))
                        .font(.caption2).lineLimit(1).minimumScaleFactor(0.85)
                }
                .frame(width: 70)
            }
        }
    }

    // MARK: - Preview
    #Preview {
        DashboardView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            .environmentObject(AppState())
            .environmentObject(AeroTheme(variant: .soft))
    }
