import SwiftUI
import CoreData

struct CropDetailView: View {
    let crop: Crop
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) private var viewContext

    @State private var isInCollection = false
    @State private var showingTaskSheet = false
    @State private var tasks: [TaskEntity] = []
    @State private var stepProgress: [UUID: Bool] = [:]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // --- INFO DEL CULTIVO (igual que antes) ---
                Text(crop.name ?? "Cultivo")
                    .font(.largeTitle)
                    .bold()

                if let desc = crop.cropDescription {
                    Text(desc)
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                Divider()

                // --- ESTACIONES ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("🌦️ Estaciones recomendadas:")
                        .font(.headline)
                    if let seasons = crop.recommendedSeasons as? [String] {
                        ForEach(seasons, id: \.self) { season in
                            Text("• \(season)")
                        }
                    }
                }

                Divider()

                // --- BOTONES DE COLECCIÓN Y TAREA (igual que antes) ---
                Button(action: toggleCollection) {
                    Label(
                        isInCollection ? "Quitar de Mis Cultivos" : "Añadir a Mis Cultivos",
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
                        Label("➕ Añadir Tarea", systemImage: "calendar.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }

                Divider()

                // --- LISTA DE TAREAS (igual que antes) ---
                if !tasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📅 Tareas de este cultivo")
                            .font(.headline)

                        ForEach(tasks) { task in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title ?? "Tarea")
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
                                        loadTasks()
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

                Divider()

                // --- CHECKLIST DE PASOS ---
                if let steps = crop.steps as? Set<Step>, !steps.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📋 Pasos de cultivo")
                            .font(.headline)

                        let sortedSteps = steps.sorted { $0.order < $1.order }
                        let total = sortedSteps.count
                        let completed = sortedSteps.filter { stepProgress[$0.stepID ?? UUID()] ?? false }.count

                        // Barra de progreso
                        ProgressView(value: Double(completed), total: Double(total))
                            .padding(.vertical, 4)

                        ForEach(sortedSteps, id: \.self) { step in
                            let stepID = step.stepID ?? UUID()
                            HStack {
                                Button {
                                    toggleStep(step)
                                } label: {
                                    Image(systemName: stepProgress[stepID] == true ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(stepProgress[stepID] == true ? .green : .gray)
                                }
                                .buttonStyle(.plain)

                                Text(step.title ?? "Paso")
                                    .strikethrough(stepProgress[stepID] == true)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(crop.name ?? "Cultivo")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let userID = appState.currentUserID {
                isInCollection = UserCollectionHelper.isInCollection(crop, for: userID, context: viewContext)
                loadStepProgress(for: userID)
            }
            loadTasks()
        }
        .sheet(isPresented: $showingTaskSheet) {
            AddTaskView(crop: crop)
                .environment(\.managedObjectContext, viewContext)
                .onDisappear {
                    loadTasks()
                }
        }
    }

    // MARK: - Funciones auxiliares

    private func toggleCollection() {
        guard let userID = appState.currentUserID else { return }
        do {
            if isInCollection {
                try UserCollectionHelper.removeCrop(crop, for: userID, context: viewContext)
                isInCollection = false
            } else {
                try UserCollectionHelper.addCrop(crop, for: userID, context: viewContext)
                isInCollection = true
            }
        } catch {
            print("❌ Error al actualizar colección: \(error.localizedDescription)")
        }
    }

    private func loadTasks() {
        tasks = TaskHelper.fetchTasks(for: crop, context: viewContext)
    }

    private func loadStepProgress(for userID: UUID) {
        if let steps = crop.steps as? Set<Step> {
            var map: [UUID: Bool] = [:]
            for step in steps {
                let completed = StepProgressHelper.isCompleted(step, userID: userID, context: viewContext)
                map[step.stepID ?? UUID()] = completed
            }
            stepProgress = map
        }
    }

    private func toggleStep(_ step: Step) {
        guard let userID = appState.currentUserID else { return }
        StepProgressHelper.toggleStep(step, userID: userID, context: viewContext)
        loadStepProgress(for: userID)
    }
}
