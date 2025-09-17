// DebugNotificationsView.swift
import SwiftUI
import CoreData
import UserNotifications

struct DebugNotificationsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @State private var showingAlert = false
    @State private var alertMessage: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizedStringKey("debug_notifications_title"))) {
                    Button {
                        insertDemoData()
                    } label: {
                        Label(LocalizedStringKey("debug_insert_demo"), systemImage: "tray.and.arrow.down")
                    }

                    Button {
                        sendTaskNotificationIn5s()
                    } label: {
                        Label(LocalizedStringKey("debug_send_task_5s"), systemImage: "bell")
                    }

                    Button {
                        sendCropTipIn5s()
                    } label: {
                        Label(LocalizedStringKey("debug_send_crop_tip_5s"), systemImage: "leaf")
                    }

                    Button {
                        sendSeasonalTipIn15s()
                    } label: {
                        Label(LocalizedStringKey("debug_send_seasonal_tip_15s"), systemImage: "sun.max")
                    }

                    Button(role: .destructive) {
                        clearPendingNotifications()
                    } label: {
                        Label(LocalizedStringKey("debug_clear_pending"), systemImage: "xmark.circle")
                    }
                }

                Section(header: Text("debug_logs")) {
                    Text(LocalizedStringKey("debug_instructions"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(LocalizedStringKey("debug_notifications_title"))
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("debug_alert_title"), message: Text(alertMessage), dismissButton: .default(Text("ok")))
            }
        }
    }

    // MARK: - Actions

    private func insertDemoData() {
        let insertedID = DebugPreviewData.populateIfNeeded(context: viewContext)
        if let id = insertedID {
            appState.currentUserID = id
            appState.isAuthenticated = true
            alertMessage = NSLocalizedString("debug_insert_demo_success", comment: "")
        } else {
            // Buscar usuario demo si ya existía
            let fr: NSFetchRequest<User> = User.fetchRequest()
            fr.predicate = NSPredicate(format: "email == %@", "demo@local")
            if let demoUser = try? viewContext.fetch(fr).first {
                appState.currentUserID = demoUser.userID
                appState.isAuthenticated = true
            }
            alertMessage = NSLocalizedString("debug_insert_demo_exists", comment: "")
        }
        showingAlert = true
    }

    private func sendTaskNotificationIn5s() {
        let id = "debug_task_" + UUID().uuidString
        let content = UNMutableNotificationContent()
        content.title = "🌱 " + NSLocalizedString("debug_task_title", comment: "Debug task title")
        content.body = NSLocalizedString("debug_task_body", comment: "Debug task body")
        content.sound = .default
        content.categoryIdentifier = "task_reminder"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = String(format: NSLocalizedString("debug_send_error", comment: ""), error.localizedDescription)
                } else {
                    alertMessage = NSLocalizedString("debug_task_scheduled", comment: "")
                    // Log (asociado al usuario actual si existe)
                    NotificationLogHelper.logNotification(title: content.title, body: content.body, type: "action:DEBUG_SEND_TASK", userID: appState.currentUserID, context: viewContext)
                }
                showingAlert = true
            }
        }
    }

    private func sendCropTipIn5s() {
        // Try to find a crop in the store
        let fr: NSFetchRequest<Crop> = Crop.fetchRequest()
        fr.fetchLimit = 1
        var cropName = NSLocalizedString("crop_default", comment: "Crop")
        if let crop = try? viewContext.fetch(fr).first {
            // Use NotificationHelper.scheduleSeasonalTip(for:) (which schedules the system notification)
            NotificationHelper.scheduleSeasonalTip(for: crop)
            // Log (associate to current user if any)
            NotificationLogHelper.logNotification(title: "Seasonal tip: \(crop.name ?? cropName)", body: NSLocalizedString("debug_crop_tip_body", comment: ""), type: "tip:seasonal", userID: appState.currentUserID, context: viewContext)
            alertMessage = String(format: NSLocalizedString("debug_crop_scheduled_for_crop", comment: ""), crop.name ?? cropName)
            showingAlert = true
            return
        }

        // Fallback: schedule a generic crop tip in 5s
        let id = "debug_crop_" + UUID().uuidString
        let content = UNMutableNotificationContent()
        content.title = "💧 \(cropName)"
        content.body = NSLocalizedString("debug_crop_tip_body", comment: "Debug crop tip")
        content.sound = .default
        content.categoryIdentifier = "crop_tip"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = String(format: NSLocalizedString("debug_send_error", comment: ""), error.localizedDescription)
                } else {
                    alertMessage = NSLocalizedString("debug_crop_scheduled", comment: "")
                    NotificationLogHelper.logNotification(title: content.title, body: content.body, type: "tip:crop_debug", userID: appState.currentUserID, context: viewContext)
                }
                showingAlert = true
            }
        }
    }

    private func sendSeasonalTipIn15s() {
        // Try to find a crop and use NotificationHelper which uses 15s by default
        let fr: NSFetchRequest<Crop> = Crop.fetchRequest()
        fr.fetchLimit = 1
        if let crop = try? viewContext.fetch(fr).first {
            NotificationHelper.scheduleSeasonalTip(for: crop)
            NotificationLogHelper.logNotification(title: "Seasonal tip: \(crop.name ?? "")", body: NSLocalizedString("debug_crop_tip_body", comment: ""), type: "tip:seasonal", userID: appState.currentUserID, context: viewContext)
            alertMessage = NSLocalizedString("debug_seasonal_scheduled", comment: "")
            showingAlert = true
            return
        }

        // No crops: fallback to generic
        let id = "debug_seasonal_" + UUID().uuidString
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("debug_seasonal_title", comment: "")
        content.body = NSLocalizedString("debug_crop_tip_body", comment: "Debug crop tip")
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = String(format: NSLocalizedString("debug_send_error", comment: ""), error.localizedDescription)
                } else {
                    alertMessage = NSLocalizedString("debug_seasonal_scheduled", comment: "")
                    NotificationLogHelper.logNotification(title: content.title, body: content.body, type: "tip:seasonal", userID: appState.currentUserID, context: viewContext)
                }
                showingAlert = true
            }
        }
    }

    private func clearPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        alertMessage = NSLocalizedString("debug_cleared_pending_success", comment: "")
        showingAlert = true
    }
}
