import SwiftUI
import CoreData

struct AddTaskView: View {
    var crop: Crop? = nil
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState      // <-- agregar
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var details: String = ""
    @State private var dueDate: Date = Date()
    @State private var reminder: Bool = true

    // Notificaciones avanzadas
    @State private var recurrence: String = "none" // "none","daily","weekly","monthly"
    @State private var useRelative: Bool = false
    @State private var relativeDays: Int = 0 // 0..30

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Detalles de la tarea")) {
                    TextField("Título", text: $title)
                    TextField("Descripción", text: $details)
                    DatePicker("Fecha", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    Toggle("Recordatorio", isOn: $reminder)
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

                if let crop = crop {
                    Section(header: Text("Cultivo asociado")) {
                        Text(crop.name ?? "—")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Nueva Tarea")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
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

        // Guardar la configuración extra en TaskEntity (requiere que hayas añadido los atributos)
        task.recurrenceRule = recurrence
        task.relativeDays = Int16(useRelative ? relativeDays : 0)

        // --- ASIGNAR USUARIO ACTUAL si existe ---
        if let uid = appState.currentUserID {
            let fr: NSFetchRequest<User> = User.fetchRequest()
            fr.predicate = NSPredicate(format: "userID == %@", uid as CVarArg)
            fr.fetchLimit = 1
            if let user = (try? viewContext.fetch(fr))?.first {
                task.user = user
            } else {
                // opcional: log si no se encuentra el user
                print("⚠️ AddTaskView: user not found for id \(uid)")
            }
        }

        do {
            try viewContext.save()
            if reminder {
                TaskHelper.scheduleNotification(for: task)
            }
            dismiss()
        } catch {
            print("❌ Error guardando tarea: \(error.localizedDescription)")
        }
    }
}

