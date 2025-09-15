import SwiftUI
import UserNotifications
import CoreData

struct EditTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var details: String
    @State private var dueDate: Date
    @State private var reminder: Bool

    // advanced
    @State private var recurrence: String
    @State private var useRelative: Bool
    @State private var relativeDays: Int

    var task: TaskEntity

    init(task: TaskEntity) {
        self.task = task
        _title = State(initialValue: task.title ?? "")
        _details = State(initialValue: task.details ?? "")
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _reminder = State(initialValue: task.reminder)

        // leer valores guardados (si existen)
        _recurrence = State(initialValue: task.recurrenceRule ?? "none")
        let rd = Int(task.relativeDays)
        _relativeDays = State(initialValue: rd)
        _useRelative = State(initialValue: rd > 0)
    }

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
        }
    }

    private func saveChanges() {
        task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.details = details.trimmingCharacters(in: .whitespacesAndNewlines)
        task.dueDate = dueDate
        task.reminder = reminder
        task.updatedAt = Date()

        // guardar opciones avanzadas
        task.recurrenceRule = recurrence
        task.relativeDays = Int16(useRelative ? relativeDays : 0)

        // reprogramar notificaciones
        if reminder {
            NotificationHelper.reschedule(for: task)
        } else {
            NotificationHelper.cancelNotification(for: task)
        }

        try? viewContext.save()
    }
}

