import SwiftUI
import CoreData
import UserNotifications

struct EditTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let taskID: NSManagedObjectID

    // Campos editables
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
            Form {
                Section(header: Text("task_info")) {
                    TextField("task_title", text: $title)
                    TextField("task_details", text: $details)
                }

                Section(header: Text("task_date")) {
                    DatePicker("task_due_date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    Toggle("task_reminder", isOn: $reminder)
                }

                Section(header: Text("Notificación avanzada")) {
                    Picker("Repetir", selection: $recurrence) {
                        Text("Ninguna").tag("none")
                        Text("Diaria").tag("daily")
                        Text("Semanal").tag("weekly")
                        Text("Mensual").tag("monthly")
                    }
                    .pickerStyle(.segmented)

                    Toggle("Recordar días antes", isOn: $useRelative)
                    if useRelative {
                        Stepper(value: $relativeDays, in: 0...30) {
                            Text("\(relativeDays) días antes")
                        }
                    }
                }

                if let crop = liveTask?.crop {
                    Section(header: Text("Cultivo asociado")) {
                        Text(crop.name ?? "—").foregroundColor(.secondary)
                    }
                }
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
            .alert("Tarea no encontrada", isPresented: $showMissingAlert) {
                Button("OK", role: .cancel) { dismiss() }
            } message: {
                Text("La tarea que intentas editar ya no existe.")
            }
        }
    }

    private func loadLiveTask() {
        do {
            let obj = try viewContext.existingObject(with: taskID)
            guard let t = obj as? TaskEntity else {
                print("⚠️ EditTaskView: object with id is not TaskEntity")
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
            print("❌ EditTaskView load error: \(error)")
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

            // notificaciones seguras
            if reminder {
                NotificationHelper.reschedule(for: t)
            } else {
                NotificationHelper.cancelNotification(for: t)
            }

            do {
                try viewContext.save()
                print("✅ EditTaskView saved changes for task: \(t.title ?? "no title")")
            } catch {
                print("❌ Error saving edited task: \(error)")
            }
        }
    }
}
