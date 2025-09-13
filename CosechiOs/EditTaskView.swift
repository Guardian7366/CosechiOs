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
    
    var task: TaskEntity
    
    init(task: TaskEntity) {
        self.task = task
        _title = State(initialValue: task.title ?? "")
        _details = State(initialValue: task.details ?? "")
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _reminder = State(initialValue: task.reminder)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("task_info")) {
                    TextField("task_title", text: $title)
                    TextField("task_details", text: $details)
                }
                
                Section(header: Text("task_date")) {
                    DatePicker("task_due_date", selection: $dueDate, displayedComponents: .date)
                    Toggle("task_reminder", isOn: $reminder)
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
        task.title = title
        task.details = details
        task.dueDate = dueDate
        task.reminder = reminder
        task.updatedAt = Date()
        
        if reminder {
            TaskHelper.scheduleNotification(for: task)
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.taskID?.uuidString ?? ""])
        }
        
        try? viewContext.save()
    }
}

