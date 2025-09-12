import SwiftUI

struct AddTaskView: View {
    let crop: Crop
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
            }
            .navigationTitle("Nueva Tarea")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { saveTask() }
                        .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveTask() {
        let task = TaskEntity(context: viewContext)
        task.taskID = UUID()
        task.title = title
        task.details = details
        task.dueDate = dueDate
        task.reminder = reminder
        task.status = "pending"
        task.createdAt = Date()
        task.updatedAt = Date()
        task.crop = crop

        do {
            try viewContext.save()
            if reminder {
                NotificationHelper.scheduleNotification(
                    id: task.taskID?.uuidString ?? UUID().uuidString,
                    title: "🌱 \(crop.name ?? "Cultivo")",
                    body: title,
                    date: dueDate
                )
            }
            dismiss()
        } catch {
            print("❌ Error guardando tarea: \(error.localizedDescription)")
        }
    }
}

