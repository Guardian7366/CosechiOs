import SwiftUI
import CoreData
import UserNotifications

struct EditTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: AeroTheme

    let taskID: NSManagedObjectID

    @State private var title: String = ""
    @State private var details: String = ""
    @State private var dueDate: Date = Date()
    @State private var reminder: Bool = true

    @State private var recurrence: String = "none"
    @State private var useRelative: Bool = false
    @State private var relativeDays: Int = 0

    @State private var liveTask: TaskEntity?
    @State private var showMissingAlert = false

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
                        if let crop = liveTask?.crop {
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
            .navigationTitle(LocalizationHelper.shared.localized("edit_task"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationHelper.shared.localized("cancel")) { dismiss() }
                        .accessibilityLabel(Text(LocalizationHelper.shared.localized("cancel")))
                        .accessibilityAddTraits(.isButton)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationHelper.shared.localized("save")) {
                        saveChanges()
                        dismiss()
                    }
                    .accessibilityLabel(Text(LocalizationHelper.shared.localized("save")))
                    .accessibilityAddTraits(.isButton)
                }
            }
            .onAppear(perform: loadLiveTask)
            .alert(LocalizationHelper.shared.localized("task_not_found"), isPresented: $showMissingAlert) {
                Button(LocalizationHelper.shared.localized("ok"), role: .cancel) { dismiss() }
            } message: {
                Text(LocalizationHelper.shared.localized("task_not_found_message"))
            }
        }
    }

    private func loadLiveTask() {
        do {
            let obj = try viewContext.existingObject(with: taskID)
            guard let t = obj as? TaskEntity else {
                showMissingAlert = true
                return
            }
            self.liveTask = t
            self.title = t.title ?? ""
            self.details = t.details ?? ""
            self.dueDate = t.dueDate ?? Date()
            self.reminder = t.reminder
            self.recurrence = t.recurrenceRule ?? "none"
            let rd = Int(t.relativeDays)
            self.relativeDays = rd
            self.useRelative = rd > 0
        } catch {
            showMissingAlert = true
        }
    }

    private func saveChanges() {
        guard let t = liveTask else { return }
        viewContext.performAndWait {
            t.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            t.details = details.trimmingCharacters(in: .whitespacesAndNewlines)
            t.dueDate = dueDate
            t.reminder = reminder
            t.updatedAt = Date()

            t.recurrenceRule = recurrence
            t.relativeDays = Int16(useRelative ? Int16(relativeDays) : 0)

            if reminder {
                NotificationHelper.reschedule(for: t)
            } else {
                NotificationHelper.cancelNotification(for: t)
            }

            do { try viewContext.save() } catch { viewContext.rollback() }
        }
    }
}
