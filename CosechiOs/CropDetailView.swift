
// CropDetailView.swift
import SwiftUI
import CoreData
import UIKit
import Foundation

extension Notification.Name {
    static let userCollectionsChanged = Notification.Name("userCollectionsChanged")
}
struct CropDetailView: View {
    let crop: Crop
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) private var viewContext

    @State private var isInCollection = false
    @State private var showingTaskSheet = false
    @State private var stepProgress: [UUID: Bool] = [:]

    // Historial de progreso
    @State private var progressLogs: [ProgressLog] = []
    @State private var showingAddProgress = false
    @State private var selectedLog: ProgressLog? = nil

    // FetchRequest para tareas (se filtra por user + crop en computed)
    @FetchRequest private var fetchedTasks: FetchedResults<TaskEntity>

    init(crop: Crop) {
        self.crop = crop
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)]
        _fetchedTasks = FetchRequest(fetchRequest: request)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                Divider()
                seasonsSection
                Divider()
                collectionButtons
                Divider()
                tasksSection
                Divider()
                stepsSection
                Divider()
                progressSection
            }
            .padding()
        }
        .navigationTitle(crop.name ?? NSLocalizedString("crop_default", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { onAppearActions() }
        // sheet para añadir tarea
        .sheet(isPresented: $showingTaskSheet) {
            AddTaskView(crop: crop)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(appState)
        }
        // sheet para añadir progreso
        .sheet(isPresented: $showingAddProgress) {
            AddProgressLogView(crop: crop)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(appState)
                .onDisappear { loadProgressLogs() }
        }
        // sheet para editar progreso
        .sheet(item: $selectedLog) { log in
            EditProgressLogView(log: log)
                .environment(\.managedObjectContext, viewContext)
                .onDisappear { loadProgressLogs() }
        }
    }
}

// MARK: - UI Sections & Helpers
extension CropDetailView {
    @ViewBuilder private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(crop.name ?? NSLocalizedString("crop_default", comment: ""))
                    .font(.largeTitle)
                    .bold()

                if let desc = crop.cropDescription {
                    Text(desc)
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                // Category (mostramos tal cual pero localizable si es una key)
                if let cat = crop.category {
                    Text(localizedCategory(cat))
                        .font(.caption)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }

            Spacer()

            // Badge: dificultad
            VStack {
                Text(localizedDifficulty(crop.difficulty ?? ""))
                    .font(.caption2)
                    .bold()
                    .padding(8)
                    .background(difficultyColor(crop.difficulty ?? ""))
                    .cornerRadius(10)
                    .foregroundColor(.white)

                // Recomendado ahora?
                if isRecommendedNow() {
                    Text(LocalizedStringKey("crop_recommended_now"))
                        .font(.caption2)
                        .padding(6)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(8)
                }
            }
        }
    }

    @ViewBuilder private var seasonsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey("crop_seasons"))
                .font(.headline)

            if let stored = crop.recommendedSeasons as? [String], !stored.isEmpty {
                // Muestra icono + nombre localizado por cada season key (o si la seed tenía strings, los usa)
                HStack(spacing: 12) {
                    ForEach(stored, id: \.self) { s in
                        let display = seasonDisplayString(for: s)
                        HStack {
                            Text(seasonEmoji(for: s))
                            Text(display)
                                .font(.subheadline)
                        }
                        .padding(6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            } else {
                Text(LocalizedStringKey("crop_seasons_none"))
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder private var collectionButtons: some View {
        Button(action: toggleCollection) {
            Label(
                isInCollection ? LocalizedStringKey("crop_remove_my") : LocalizedStringKey("crop_add_my"),
                systemImage: isInCollection ? "minus.circle.fill" : "plus.circle.fill"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(isInCollection ? .red : .green)

        if isInCollection {
            Button {
                showingTaskSheet = true
            } label: {
                Label(LocalizedStringKey("crop_add_task"), systemImage: "calendar.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
    }

    @ViewBuilder private var tasksSection: some View {
        let tasksForUser = filteredTasks
        if !tasksForUser.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("crop_tasks_title"))
                    .font(.headline)

                ForEach(tasksForUser) { task in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title ?? NSLocalizedString("task_default", comment: ""))
                                .font(.subheadline)
                                .strikethrough(task.status == "completed")

                            if let date = task.dueDate {
                                Text("⏰ \(date.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if task.status == "pending" {
                            Button {
                                TaskHelper.completeTask(task, context: viewContext)
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        } else {
                            Text("✔️")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    @ViewBuilder private var stepsSection: some View {
        if let stepsSet = crop.steps as? Set<Step>, !stepsSet.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("crop_steps"))
                    .font(.headline)

                let sortedSteps: [Step] = stepsSet.sorted { $0.order < $1.order }
                let total = sortedSteps.count
                let completed = sortedSteps.filter { step in
                    if let sid = step.stepID { return stepProgress[sid] ?? false }
                    return false
                }.count

                ProgressView(value: Double(completed), total: Double(total))
                    .padding(.vertical, 4)

                ForEach(sortedSteps, id: \.self) { step in
                    if let stepID = step.stepID {
                        HStack {
                            Button {
                                toggleStep(step)
                            } label: {
                                Image(systemName: stepProgress[stepID] == true ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(stepProgress[stepID] == true ? .green : .gray)
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading) {
                                Text(step.title ?? NSLocalizedString("step_default", comment: ""))
                                    .strikethrough(stepProgress[stepID] == true)
                                if step.estimateDuration > 0 {
                                    Text("\(step.estimateDuration) " + NSLocalizedString("days_abbr", comment: "days"))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                if let sd = step.stepDescription, !sd.isEmpty {
                                    Text(sd).font(.caption2).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey("crop_progress_title"))
                .font(.headline)

            if progressLogs.isEmpty {
                Text(LocalizedStringKey("crop_progress_empty"))
                    .foregroundColor(.secondary)
            } else {
                ForEach(progressLogs as [ProgressLog], id: \.progressID) { log in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(log.date ?? Date(), style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if let category = log.category {
                                Text(category)
                                    .font(.caption2)
                                    .padding(4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(6)
                            }

                            Spacer()

                            Button { selectedLog = log } label: {
                                Image(systemName: "pencil")
                            }

                            Button(role: .destructive) {
                                ProgressLogHelper.deleteLog(log, context: viewContext)
                                loadProgressLogs()
                            } label: {
                                Image(systemName: "trash")
                            }
                        }

                        if let note = log.note {
                            Text(note)
                        }

                        if let data = log.imageData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Button {
                showingAddProgress = true
            } label: {
                Label(LocalizedStringKey("crop_add_progress"), systemImage: "plus.circle")
            }
        }
    }

    // MARK: - Helpers & logic

    private func onAppearActions() {
        if let userID = appState.currentUserID {
            if let cid = crop.cropID {
                isInCollection = UserCollectionHelper.isInCollection(cropID: cid, for: userID, context: viewContext)
            }
            loadStepProgress(for: userID)
        }
        loadProgressLogs()
    }

    // Filtrado por user + crop (FetchRequest trae todo; filtramos aquí)
    private var filteredTasks: [TaskEntity] {
        guard let uid = appState.currentUserID else { return [] }
        return fetchedTasks.filter { task in
            task.crop == crop && task.user?.userID == uid
        }
    }

    private func loadStepProgress(for userID: UUID) {
        if let steps = crop.steps as? Set<Step> {
            var map: [UUID: Bool] = [:]
            for step in steps {
                if let sid = step.stepID {
                    let completed = StepProgressHelper.isCompleted(step, userID: userID, context: viewContext)
                    map[sid] = completed
                }
            }
            stepProgress = map
        }
    }

    private func loadProgressLogs() {
        guard let uid = appState.currentUserID else {
            progressLogs = []
            return
        }
        progressLogs = ProgressLogHelper.fetchLogs(for: crop, userID: uid, context: viewContext)
    }

    private func toggleStep(_ step: Step) {
        guard let userID = appState.currentUserID else { return }
        StepProgressHelper.toggleStep(step, userID: userID, context: viewContext)
        loadStepProgress(for: userID)
    }

    private func toggleCollection() {
        guard let userID = appState.currentUserID else { return }
        guard let cid = crop.cropID else {
            print("❌ toggleCollection: crop.cropID es nil")
            return
        }

        do {
            if UserCollectionHelper.isInCollection(cropID: cid, for: userID, context: viewContext) {
                try UserCollectionHelper.removeCrop(cropID: cid, for: userID, context: viewContext)
                isInCollection = false
            } else {
                let added = try UserCollectionHelper.addCrop(cropID: cid, for: userID, context: viewContext)
                isInCollection = added
            }

            // Refrescar estado desde Core Data
            isInCollection = UserCollectionHelper.isInCollection(cropID: cid, for: userID, context: viewContext)

            // Forzar recarga de UI en otras pantallas
            NotificationCenter.default.post(name: .userCollectionsChanged, object: nil)

        } catch {
            print("❌ toggleCollection error: \(error.localizedDescription)")
        }
    }

    // MARK: - Localization + UI helpers

    /// Si crop.category es una key conocida, la traducimos; si no, devolvemos tal cual.
    private func localizedCategory(_ raw: String) -> String {
        // Si deseas manejar categories como keys en el futuro, añade condiciones aquí.
        // Por ahora devolvemos directamente (manteniendo compatibilidad con lo existente)
        return raw
    }

    private func localizedDifficulty(_ raw: String) -> LocalizedStringKey {
        switch raw.lowercased() {
        case "muy fácil", "muy facil", "very easy":
            return LocalizedStringKey("crop_difficulty_very_easy")
        case "fácil", "facil", "easy":
            return LocalizedStringKey("crop_difficulty_easy")
        case "media", "medium":
            return LocalizedStringKey("crop_difficulty_medium")
        case "difícil", "dificil", "hard":
            return LocalizedStringKey("crop_difficulty_hard")
        default:
            return LocalizedStringKey(raw)
        }
    }

    private func difficultyColor(_ raw: String) -> Color {
        switch raw.lowercased() {
        case "muy fácil", "muy facil", "very easy": return .green
        case "fácil", "facil", "easy": return .mint
        case "media", "medium": return .orange
        case "difícil", "dificil", "hard": return .red
        default: return .gray
        }
    }

    /// season might be a key (season_spring) or a localized string previously stored.
    private func seasonDisplayString(for stored: String) -> String {
        // Si stored parece una key (empieza con "season_") -> localizarla,
        // si no, devolver como texto (compatibilidad con crops antiguos).
        if stored.hasPrefix("season_") {
            return NSLocalizedString(stored, comment: "")
        } else {
            return stored
        }
    }

    private func seasonEmoji(for stored: String) -> String {
        let key = stored.lowercased()
        if key.contains("spring") || key.contains("primavera") { return "🌸" }
        if key.contains("summer") || key.contains("verano") { return "☀️" }
        if key.contains("autumn") || key.contains("fall") || key.contains("otoño") { return "🍂" }
        if key.contains("winter") || key.contains("invierno") { return "❄️" }
        return "🗓"
    }

    /// Devuelve la key de la temporada actual, ej. "season_spring"
    private func currentSeasonKey() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return "season_spring"
        case 6...8: return "season_summer"
        case 9...11: return "season_autumn"
        default: return "season_winter"
        }
    }

    /// Determina si el cultivo está recomendado para la temporada actual.
    private func isRecommendedNow() -> Bool {
        guard let stored = crop.recommendedSeasons as? [String], !stored.isEmpty else { return false }
        let currentKey = currentSeasonKey()
        if stored.contains(currentKey) { return true }
        // fallback: comparar con localized name
        let currentLocalized = NSLocalizedString(currentKey, comment: "")
        return stored.contains(currentLocalized)
    }
}
