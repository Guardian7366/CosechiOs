import SwiftUI
import CoreData
import UserNotifications

/// EditTaskView recibe un taskID para recuperar la entidad en el contexto activo.
/// Evita faults o context-mismatch y maneja edición segura.
struct EditTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let taskID: NSManagedObjectID

    // Campos editables
    @State private var title: String = ""
    @State private var details: String = ""
    @State private var dueDate: Date = Date()
    @State private var reminder: Bool = true

    // Avanzado
    @State private var recurrence: String = "none"
    @State private var useRelative: Bool = false
    @State private var relativeDays: Int = 0

    // Referencia en vivo a la entidad
    @State private var liveTask: TaskEntity?

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
        }
    }

    // MARK: - Cargar datos desde Core Data

    private func loadLiveTask() {
        viewContext.perform {
            do {
                if let obj = try? viewContext.existingObject(with: taskID) as? TaskEntity {
                    self.liveTask = obj
                    self.title = obj.title ?? ""
                    self.details = obj.details ?? ""
                    self.dueDate = obj.dueDate ?? Date()
                    self.reminder = obj.reminder
                    self.recurrence = obj.recurrenceRule ?? "none"
                    let rd = Int(obj.relativeDays)
                    self.relativeDays = rd
                    self.useRelative = rd > 0
                } else {
                    print("⚠️ EditTaskView: task not found or not TaskEntity")
                }
            }
        }
    }

    // MARK: - Guardar cambios

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

            do {
                try viewContext.save()
                print("✅ Tarea actualizada correctamente")
            } catch {
                print("❌ Error saving edited task: \(error.localizedDescription)")
            }
        }
    }
}
