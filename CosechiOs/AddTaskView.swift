import SwiftUI
import CoreData

struct AddTaskView: View {
    var crop: Crop? = nil
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var details: String = ""
    @State private var dueDate: Date = Date()
    @State private var reminder: Bool = true

    @State private var recurrence: String = "none"
    @State private var useRelative: Bool = false
    @State private var relativeDays: Int = 0

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("task_info")) {
                    TextField("task_title", text: $title)
                    TextField("task_details", text: $details)
                    DatePicker("task_due_date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    Toggle("task_reminder", isOn: $reminder)
                }

                Section(header: Text("task_advanced_notification")) {
                    Picker("task_repeat", selection: $recurrence) {
                        Text("repeat_none").tag("none")
                        Text("repeat_daily").tag("daily")
                        Text("repeat_weekly").tag("weekly")
                        Text("repeat_monthly").tag("monthly")
                    }
                    .pickerStyle(.segmented)

                    Toggle("task_remember_days_before", isOn: $useRelative)
                    if useRelative {
                        Stepper(value: $relativeDays, in: 0...30) {
                            Text("task_days_before \(relativeDays)")
                        }
                    }
                }

                if let crop = crop {
                    Section(header: Text("task_associated_crop")) {
                        Text(crop.name ?? "—")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("task_new")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        saveTask()
                    }
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
            if reminder {
                NotificationHelper.scheduleNotification(for: task)
            }
            dismiss()
        } catch {
            print("❌ Error guardando tarea: \(error.localizedDescription)")
            viewContext.rollback()
        }
    }
}
