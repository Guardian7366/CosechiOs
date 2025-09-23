// EditTaskView.swift
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

                    if let crop = liveTask?.crop {
                        GlassCard {
                            Text("\(NSLocalizedString("task_associated_crop", comment: "")): \(crop.name ?? "—")")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("edit_task")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .onAppear(perform: loadLiveTask)
            .alert("task_not_found", isPresented: $showMissingAlert) {
                Button("ok", role: .cancel) { dismiss() }
            } message: {
                Text("task_not_found_message")
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
            t.relativeDays = Int16(useRelative ? relativeDays : 0)

            if reminder {
                NotificationHelper.reschedule(for: t)
            } else {
                NotificationHelper.cancelNotification(for: t)
            }

            do { try viewContext.save() } catch { viewContext.rollback() }
        }
    }
}
