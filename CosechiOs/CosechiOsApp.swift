import SwiftUI
import UserNotifications

// 🔹 Estado global de la app
final class AppState: ObservableObject {
    @Published var currentUserID: UUID?
    @Published var isAuthenticated: Bool = false
    // inicializa desde UserDefaults (fallback "es")
    @Published var appLanguage: String = UserDefaults.standard.string(forKey: "appLanguage") ?? "es"
}

@main
struct CosechiOsApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appState = AppState()

    init() {
        // Si no hay idioma guardado, establecer "es" por defecto
        if UserDefaults.standard.string(forKey: "appLanguage") == nil {
            UserDefaults.standard.set("es", forKey: "appLanguage")
        }
        // Pedir permisos de notificación (no bloqueante)
        requestNotificationPermissions()
    }

    var body: some Scene {
        WindowGroup {
            // Forzamos que la jerarquía se reinicialice cuando cambie appLanguage
            LoadingView()
                .id(appState.appLanguage) // <- esto fuerza recrear las vistas cuando cambia el idioma
                .environmentObject(appState)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.locale, Locale(identifier: appState.appLanguage)) // <- esto le dice a SwiftUI qué locale usar
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
