import SwiftUI
import CoreData

struct AddTaskView: View {
    // Ahora crop es opcional para permitir usar AddTaskView() desde varios sitios
    var crop: Crop? = nil

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var details: String = ""
    @State private var dueDate: Date = Date()
    @State private var reminder: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Detalles de la tarea")) {
                    TextField("Título", text: $title)
                    TextField("Descripción", text: $details)
                    DatePicker("Fecha", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    Toggle("Recordatorio", isOn: $reminder)
                }

                // Mostrar info del cultivo si fue pasado
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

        // Solo asignar crop si hay uno
        if let c = crop {
            task.crop = c
        }

        do {
            try viewContext.save()

            // Usar la API centralizada para programar notificaciones
            if reminder {
                TaskHelper.scheduleNotification(for: task)
            }

            dismiss()
        } catch {
            // Mejor manejar errores de guardado (podrías mostrar una alerta)
            print("❌ Error guardando tarea: \(error.localizedDescription)")
        }
    }
}

