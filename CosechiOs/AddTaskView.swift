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
        NavigationStack {
            FrutigerAeroBackground {
                ScrollView {
                    VStack(spacing: 16) {
                        // 📌 Sección Título y Detalles
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(LocalizationHelper.shared.localized("task_info_section"))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                TextField(LocalizationHelper.shared.localized("task_title"), text: $title)
                                    .aeroTextField()
                                    .accessibilityLabel(Text(LocalizationHelper.shared.localized("task_title")))
                                TextField(LocalizationHelper.shared.localized("task_details"), text: $details)
                                    .aeroTextField()
                                    .accessibilityLabel(Text(LocalizationHelper.shared.localized("task_details")))
                            }
                        }

                        // 📌 Sección Fecha y Recordatorio
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(LocalizationHelper.shared.localized("task_schedule_section"))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                DatePicker(LocalizationHelper.shared.localized("task_due_date"),
                                           selection: $dueDate,
                                           displayedComponents: [.date, .hourAndMinute])
                                    .foregroundColor(.white)
                                    .accessibilityLabel(Text(LocalizationHelper.shared.localized("task_due_date")))
                                Toggle(LocalizationHelper.shared.localized("task_reminder"), isOn: $reminder)
                                    .foregroundColor(.white)
                                    .accessibilityLabel(Text(LocalizationHelper.shared.localized("task_reminder")))
                            }
                        }

                        // 📌 Sección Repetición
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(LocalizationHelper.shared.localized("task_repeat_section"))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Picker(LocalizationHelper.shared.localized("task_repeat"), selection: $recurrence) {
                                    Text(LocalizationHelper.shared.localized("repeat_none")).tag("none")
                                    Text(LocalizationHelper.shared.localized("repeat_daily")).tag("daily")
                                    Text(LocalizationHelper.shared.localized("repeat_weekly")).tag("weekly")
                                    Text(LocalizationHelper.shared.localized("repeat_monthly")).tag("monthly")
                                }
                                .pickerStyle(.segmented)
                                .accessibilityLabel(Text(LocalizationHelper.shared.localized("task_repeat")))

                                Toggle(LocalizationHelper.shared.localized("task_remember_days_before"), isOn: $useRelative)
                                    .foregroundColor(.white)
                                    .accessibilityLabel(Text(LocalizationHelper.shared.localized("task_remember_days_before")))

                                if useRelative {
                                    Stepper(value: $relativeDays, in: 0...30) {
                                        Text("\(LocalizationHelper.shared.localized("task_days_before")) \(relativeDays)")
                                            .foregroundColor(.white)
                                    }
                                    .accessibilityLabel(Text(LocalizationHelper.shared.localized("task_days_before")))
                                }
                            }
                        }

                        // 📌 Sección Cultivo Asociado
                        if let crop = crop {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(LocalizationHelper.shared.localized("task_associated_crop"))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text(LocalizationHelper.shared.localized(crop.name ?? "crop_default"))
                                        .foregroundColor(.secondary)
                                        .accessibilityLabel(Text(LocalizationHelper.shared.localized("task_associated_crop")))
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(LocalizationHelper.shared.localized("task_new"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationHelper.shared.localized("cancel")) { dismiss() }
                        .accessibilityLabel(Text(LocalizationHelper.shared.localized("cancel")))
                        .accessibilityAddTraits(.isButton)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationHelper.shared.localized("save")) { saveTask() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityLabel(Text(LocalizationHelper.shared.localized("save")))
                        .accessibilityAddTraits(.isButton)
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
