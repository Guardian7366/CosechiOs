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
    @State private var seasonalTipSent = false

    @State private var progressLogs: [ProgressLog] = []
    @State private var showingAddProgress = false
    @State private var selectedLog: ProgressLog? = nil

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
                Divider()
                infoSection
            }
            .padding()
        }
        .navigationTitle(Text(localizedName()))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { onAppearActions() }
        .sheet(isPresented: $showingTaskSheet) {
            AddTaskView(crop: crop)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingAddProgress) {
            AddProgressLogView(crop: crop)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(appState)
                .onDisappear { loadProgressLogs() }
        }
        .sheet(item: $selectedLog) { log in
            EditProgressLogView(log: log)
                .environment(\.managedObjectContext, viewContext)
                .onDisappear { loadProgressLogs() }
        }
    }
}

// MARK: - UI Sections
extension CropDetailView {
    @ViewBuilder private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            if let imageName = crop.imageName, !imageName.isEmpty, UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipped()
                    .cornerRadius(10)
                    .shadow(radius: 2)
            } else {
                ZStack {
                    Color(.systemGray5)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .frame(width: 120, height: 120)
                .cornerRadius(10)
                .shadow(radius: 1)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(localizedName())
                    .font(.largeTitle)
                    .bold()

                if let descKey = crop.cropDescription, !descKey.isEmpty {
                    Text(LocalizationHelper.shared.localized(descKey))
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                if let catKey = crop.category {
                    Text(LocalizationHelper.shared.localized(catKey))
                        .font(.caption)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }

            Spacer()

            VStack {
                Text(localizedDifficultyKey(crop.difficulty ?? ""))
                    .font(.caption2)
                    .bold()
                    .padding(8)
                    .background(difficultyColor(crop.difficulty ?? ""))
                    .cornerRadius(10)
                    .foregroundColor(.white)

                if isRecommendedNow() {
                    Text(LocalizationHelper.shared.localized("crop_recommended_now"))
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
            Text(LocalizationHelper.shared.localized("crop_seasons"))
                .font(.headline)

            if let stored = crop.recommendedSeasons as? [String], !stored.isEmpty {
                HStack(spacing: 12) {
                    ForEach(stored, id: \.self) { s in
                        HStack {
                            Text(seasonEmoji(for: s))
                            Text(LocalizationHelper.shared.localized(s))
                                .font(.subheadline)
                        }
                        .padding(6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            } else {
                Text(LocalizationHelper.shared.localized("crop_seasons_none"))
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder private var collectionButtons: some View {
        Button(action: toggleCollection) {
            Label(
                isInCollection ? LocalizationHelper.shared.localized("crop_remove_my") : LocalizationHelper.shared.localized("crop_add_my"),
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
                Label(LocalizationHelper.shared.localized("crop_add_task"), systemImage: "calendar.badge.plus")
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
                Text(LocalizationHelper.shared.localized("crop_tasks_title"))
                    .font(.headline)

                ForEach(tasksForUser) { task in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title ?? LocalizationHelper.shared.localized("task_default"))
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
                            Text("✔️").foregroundColor(.green)
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
                Text(LocalizationHelper.shared.localized("crop_steps"))
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
                                if let stepKey = step.title {
                                    Text(LocalizationHelper.shared.localized(stepKey))
                                        .strikethrough(stepProgress[stepID] == true)
                                }

                                if step.estimateDuration > 0 {
                                    Text("\(step.estimateDuration) " + LocalizationHelper.shared.localized("days_abbr"))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                if let sd = step.stepDescription, !sd.isEmpty {
                                    let resolved = LocalizationHelper.shared.localized(sd)
                                    if resolved.contains("%@") {
                                        let stepTitleLocalized = LocalizationHelper.shared.localized(step.title ?? "")
                                        Text(String(format: resolved, stepTitleLocalized))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text(resolved)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
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
            Text(LocalizationHelper.shared.localized("crop_progress_title"))
                .font(.headline)

            if progressLogs.isEmpty {
                Text(LocalizationHelper.shared.localized("crop_progress_empty"))
                    .foregroundColor(.secondary)
            } else {
                ForEach(progressLogs as [ProgressLog], id: \.progressID) { log in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(log.date ?? Date(), style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if let categoryKey = log.category {
                                Text(LocalizationHelper.shared.localized(categoryKey))
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
                Label(LocalizationHelper.shared.localized("crop_add_progress"), systemImage: "plus.circle")
            }
        }
    }

    @ViewBuilder private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizationHelper.shared.localized("crop_recommendations"))
                .font(.headline)

            if let stepsSet = crop.steps as? Set<Step>, !stepsSet.isEmpty {
                let totalDays = stepsSet.reduce(0) { $0 + Int($1.estimateDuration) }
                Text("⏳ " + String(format: LocalizationHelper.shared.localized("crop_estimated_duration"), totalDays))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let info = crop.info {
                Group {
                    if let soilKey = info.soilType { Text("🌱 \(LocalizationHelper.shared.localized("crop_soil")): \(LocalizationHelper.shared.localized(soilKey))") }
                    if let wateringKey = info.watering { Text("💧 \(LocalizationHelper.shared.localized("crop_watering")): \(LocalizationHelper.shared.localized(wateringKey))") }
                    if let sunKey = info.sunlight { Text("☀️ \(LocalizationHelper.shared.localized("crop_sunlight")): \(LocalizationHelper.shared.localized(sunKey))") }
                    if let tempKey = info.temperatureRange { Text("🌡 \(LocalizationHelper.shared.localized("crop_temperature")): \(LocalizationHelper.shared.localized(tempKey))") }
                    if let fertKey = info.fertilizationTips { Text("🧪 \(LocalizationHelper.shared.localized("crop_fertilization")): \(LocalizationHelper.shared.localized(fertKey))") }
                    if let climateKey = info.climate { Text("🌍 \(LocalizationHelper.shared.localized("crop_climate")): \(LocalizationHelper.shared.localized(climateKey))") }
                    if let plKey = info.plagues { Text("🐛 \(LocalizationHelper.shared.localized("crop_plagues")): \(LocalizationHelper.shared.localized(plKey))") }
                    if let companionsKey = info.companions { Text("🤝 \(LocalizationHelper.shared.localized("crop_companions")): \(LocalizationHelper.shared.localized(companionsKey))") }
                    if info.germinationDays > 0 { Text("🌱 " + String(format: LocalizationHelper.shared.localized("crop_germination_days"), info.germinationDays)) }
                    if let freqKey = info.wateringFrequency { Text("💧 \(LocalizationHelper.shared.localized("crop_watering_frequency")): \(LocalizationHelper.shared.localized(freqKey))") }

                    if let months = info.harvestMonths as? [String], !months.isEmpty {
                        let mapped = months.map { LocalizationHelper.shared.localized($0) }.joined(separator: ", ")
                        Text("🌾 \(LocalizationHelper.shared.localized("crop_harvest_months")): \(mapped)")
                    }
                }
            } else {
                Text(LocalizationHelper.shared.localized("crop_info_unavailable"))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Helpers
extension CropDetailView {
    private func onAppearActions() {
        if let userID = appState.currentUserID {
            if let cid = crop.cropID {
                isInCollection = UserCollectionHelper.isInCollection(cropID: cid, for: userID, context: viewContext)
            }
            loadStepProgress(for: userID)
        }
        loadProgressLogs()
    }

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
        guard let userID = appState.currentUserID, let cid = crop.cropID else { return }
        do {
            if UserCollectionHelper.isInCollection(cropID: cid, for: userID, context: viewContext) {
                try UserCollectionHelper.removeCrop(cropID: cid, for: userID, context: viewContext)
                isInCollection = false
            } else {
                let added = try UserCollectionHelper.addCrop(cropID: cid, for: userID, context: viewContext)
                isInCollection = added
            }
            isInCollection = UserCollectionHelper.isInCollection(cropID: cid, for: userID, context: viewContext)
            NotificationCenter.default.post(name: .userCollectionsChanged, object: nil)
        } catch { print("❌ toggleCollection error: \(error.localizedDescription)") }
    }

    private func localizedName() -> String {
        return LocalizationHelper.shared.localized(crop.name ?? "crop_no_name")
    }

    private func localizedDifficultyKey(_ rawKey: String) -> String {
        let raw = rawKey.lowercased()
        switch raw {
        case "crop_difficulty_very_easy": return LocalizationHelper.shared.localized("crop_difficulty_very_easy")
        case "crop_difficulty_easy": return LocalizationHelper.shared.localized("crop_difficulty_easy")
        case "crop_difficulty_medium": return LocalizationHelper.shared.localized("crop_difficulty_medium")
        case "crop_difficulty_hard": return LocalizationHelper.shared.localized("crop_difficulty_hard")
        default: return LocalizationHelper.shared.localized(rawKey)
        }
    }

    private func difficultyColor(_ rawKey: String) -> Color {
        let raw = rawKey.lowercased()
        switch raw {
        case "crop_difficulty_very_easy": return .green
        case "crop_difficulty_easy": return .mint
        case "crop_difficulty_medium": return .orange
        case "crop_difficulty_hard": return .red
        default: return .gray
        }
    }

    private func seasonEmoji(for stored: String) -> String {
        let key = stored.lowercased()
        if key.contains("spring") { return "🌸" }
        if key.contains("summer") { return "☀️" }
        if key.contains("autumn") || key.contains("fall") { return "🍂" }
        if key.contains("winter") { return "❄️" }
        return "🗓"
    }

    private func isRecommendedNow() -> Bool {
        guard let stored = crop.recommendedSeasons as? [String], !stored.isEmpty else { return false }
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentSeason: String
        switch currentMonth {
        case 3...5: currentSeason = "season_spring"
        case 6...8: currentSeason = "season_summer"
        case 9...11: currentSeason = "season_autumn"
        default: currentSeason = "season_winter"
        }
        return stored.contains(currentSeason)
    }
}
