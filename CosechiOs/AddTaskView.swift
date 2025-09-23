// AddTaskView.swift
import SwiftUI
import CoreData

struct AddTaskView: View {
    var crop: Crop? = nil
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: AeroTheme
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var details: String = ""
    @State private var dueDate: Date = Date()
    @State private var reminder: Bool = true

    @State private var recurrence: String = "none"
    @State private var useRelative: Bool = false
    @State private var relativeDays: Int = 0

    var body: some View {
        FrutigerAeroBackground {
            ScrollView {
                VStack(spacing: 16) {
                    GlassCard {
                        VStack(spacing: 12) {
                            TextField("task_title", text: $title)
                                .aeroTextField()
                            TextField("task_details", text: $details)
                                .aeroTextField()
                        }
                    }

                    GlassCard {
                        VStack(spacing: 12) {
                            DatePicker("task_due_date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                .foregroundColor(.white)
                            Toggle("task_reminder", isOn: $reminder)
                                .foregroundColor(.white)
                        }
                    }

                    GlassCard {
                        VStack(spacing: 12) {
                            Picker("task_repeat", selection: $recurrence) {
                                Text("repeat_none").tag("none")
                                Text("repeat_daily").tag("daily")
                                Text("repeat_weekly").tag("weekly")
                                Text("repeat_monthly").tag("monthly")
                            }
                            .pickerStyle(.segmented)

                            Toggle("task_remember_days_before", isOn: $useRelative)
                                .foregroundColor(.white)

                            if useRelative {
                                Stepper(value: $relativeDays, in: 0...30) {
                                    Text("task_days_before \(relativeDays)")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }

                    if let crop = crop {
                        GlassCard {
                            Text("\(NSLocalizedString("task_associated_crop", comment: "")): \(crop.name ?? "—")")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("task_new")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") { saveTask() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveTask() {
        let task = TaskEntity(context: viewContext)
        task.taskID = UUID()
        task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.details = details.trimmingCharacters(in: .whitespacesAndNewlines)
        task.dueDate = dueDate
        task.reminder = reminder
        task.status = "pending"
        task.createdAt = Date()
        task.updatedAt = Date()
        if let c = crop { task.crop = c }

        task.recurrenceRule = recurrence
        task.relativeDays = Int16(useRelative ? relativeDays : 0)

        if let uid = appState.currentUserID {
            let ufr: NSFetchRequest<User> = User.fetchRequest()
            ufr.predicate = NSPredicate(format: "userID == %@", uid as CVarArg)
            ufr.fetchLimit = 1
            if let user = try? viewContext.fetch(ufr).first {
                task.user = user
            }
        }

        do {
            try viewContext.save()
            if reminder { NotificationHelper.scheduleNotification(for: task) }
            if let user = task.user {
                AchievementManager.award(action: .createTask, to: user.userID ?? UUID(), context: viewContext)
            }
            dismiss()
        } catch {
            viewContext.rollback()
        }
    }
}
