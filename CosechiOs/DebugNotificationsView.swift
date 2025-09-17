// DebugNotificationsView.swift
import SwiftUI
import UserNotifications
import CoreData

struct DebugNotificationsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState
    
    @State private var log: [String] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("debug_section_tasks")) {
                    Button("🔔 Test Task Reminder") {
                        testTaskNotification()
                    }
                }
                
                Section(header: Text("debug_section_crops")) {
                    Button("🌱 Test Crop Reminder") {
                        testCropNotification()
                    }
                }
                
                Section(header: Text("debug_section_tips")) {
                    Button("💡 Test Seasonal Tip") {
                        testTipNotification()
                    }
                }
                
                Section(header: Text("debug_section_clear")) {
                    Button("❌ Clear All Pending") {
                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                        appendLog("All pending notifications cleared.")
                    }
                }
                
                if !log.isEmpty {
                    Section(header: Text("debug_section_log")) {
                        ForEach(log, id: \.self) { entry in
                            Text(entry).font(.caption2)
                        }
                    }
                }
            }
            .navigationTitle("debug_notifications_title")
        }
    }
    
    // MARK: - Test Helpers
    
    private func testTaskNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🌱 Test Task"
        content.body = NSLocalizedString("debug_test_task_body", comment: "Task reminder test")
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "debug_task", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { err in
            if let err = err {
                appendLog("❌ Task test error: \(err.localizedDescription)")
            } else {
                appendLog("✅ Task test scheduled in 5s")
            }
        }
    }
    
    private func testCropNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🌱 Test Crop"
        content.body = NSLocalizedString("debug_test_crop_body", comment: "Crop reminder test")
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "debug_crop", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { err in
            if let err = err {
                appendLog("❌ Crop test error: \(err.localizedDescription)")
            } else {
                appendLog("✅ Crop test scheduled in 5s")
            }
        }
    }
    
    private func testTipNotification() {
        let content = UNMutableNotificationContent()
        content.title = "💡 Test Tip"
        content.body = NSLocalizedString("debug_test_tip_body", comment: "Tip reminder test")
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "debug_tip", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { err in
            if let err = err {
                appendLog("❌ Tip test error: \(err.localizedDescription)")
            } else {
                appendLog("✅ Tip test scheduled in 5s")
            }
        }
    }
    
    private func appendLog(_ msg: String) {
        DispatchQueue.main.async {
            log.insert("[\(Date().formatted(date: .omitted, time: .standard))] \(msg)", at: 0)
        }
    }
}
