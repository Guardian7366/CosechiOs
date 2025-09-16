import SwiftUI
import CoreData
import UIKit

struct CropDetailView: View {
    let crop: Crop
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var isInCollection = false
    @State private var showingTaskSheet = false
    @State private var stepProgress: [UUID: Bool] = [:]
    
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
            }
            .padding()
        }
        .navigationTitle(crop.name ?? NSLocalizedString("crop_default", comment: ""))
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

extension CropDetailView {
    @ViewBuilder private var headerSection: some View {
        Text(crop.name ?? NSLocalizedString("crop_default", comment: ""))
            .font(.largeTitle)
            .bold()
        
        if let desc = crop.cropDescription {
            Text(desc)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder private var seasonsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("crop_seasons")
                .font(.headline)
            if let seasons = crop.recommendedSeasons as? [String] {
                ForEach(seasons, id: \.self) { season in
                    Text("• \(season)")
                }
            }
        }
    }
    
    @ViewBuilder private var collectionButtons: some View {
        Button(action: toggleCollection) {
            Label(
                isInCollection ? "crop_remove_my" : "crop_add_my",
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
                Label("crop_add_task", systemImage: "calendar.badge.plus")
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
                Text("crop_tasks_title")
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
        if let steps = crop.steps as? Set<Step>, !steps.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("crop_steps")
                    .font(.headline)
                
                let sortedSteps: [Step] = steps.sorted { $0.order < $1.order }
                let total = sortedSteps.count
                let completed = sortedSteps.filter { step in
                    if let sid = step.stepID {
                        return stepProgress[sid] ?? false
                    }
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
                            
                            Text(step.title ?? NSLocalizedString("step_default", comment: ""))
                                .strikethrough(stepProgress[stepID] == true)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("crop_progress_title")
                .font(.headline)
            
            if progressLogs.isEmpty {
                Text("crop_progress_empty")
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
                Label("crop_add_progress", systemImage: "plus.circle")
            }
        }
    }
}

extension CropDetailView {
    // MARK: - Funciones auxiliares
    
    private func onAppearActions() {
        if let userID = appState.currentUserID {
            if let cid = crop.cropID {
                isInCollection = UserCollectionHelper.isInCollection(cropID: cid, for: userID, context: viewContext)
            }
            loadStepProgress(for: userID)
        }
        loadProgressLogs()
    }
    
    // ✅ Nuevo: filtrado por usuario + cultivo
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
            
            // Forzar recarga de UI
            NotificationCenter.default.post(name: .userCollectionsChanged, object: nil)
            
        } catch {
            print("❌ toggleCollection error: \(error.localizedDescription)")
        }
    }
}

extension Notification.Name {
    static let userCollectionsChanged = Notification.Name("userCollectionsChanged")
}
