import SwiftUI
import UserNotifications

// 🔹 Estado global de la app
final class AppState: ObservableObject {
    @Published var currentUserID: UUID?
    @Published var isAuthenticated: Bool = false
    @Published var appLanguage: String = UserDefaults.standard.string(forKey: "appLanguage") ?? "es"
}

@main
struct CosechiOsApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appState = AppState()

    init() {
        NotificationManager.shared.configure()

        if UserDefaults.standard.string(forKey: "appLanguage") == nil {
            UserDefaults.standard.set("es", forKey: "appLanguage")
        }
        requestNotificationPermissions()
    }

    var body: some Scene {
        WindowGroup {
            AchievementUIContainer {   // ⬅️ integración global
                LoadingView()
                    .id(appState.appLanguage)
                    .environmentObject(appState)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environment(\.locale, Locale(identifier: appState.appLanguage))
            }
        }
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("🔔 Notificaciones permitidas")
            } else if let error = error {
                print("❌ Error en permisos de notificaciones: \(error.localizedDescription)")
            }
        }
    }
}
