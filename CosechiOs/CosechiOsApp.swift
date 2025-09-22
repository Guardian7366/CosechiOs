// CosechiOsApp.swift
import SwiftUI
import UserNotifications
import CoreData

final class AppState: ObservableObject {
    @Published var currentUserID: UUID?
    @Published var isAuthenticated: Bool = false
    @Published var appLanguage: String = UserDefaults.standard.string(forKey: "appLanguage") ?? "es" {
        didSet { UserDefaults.standard.set(appLanguage, forKey: "appLanguage") }
    }
}

@main
struct CosechiOsApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appState = AppState()
    @StateObject private var theme = AeroTheme(variant: .soft) // theme raíz

    init() {
        NotificationManager.shared.configure()

        if UserDefaults.standard.string(forKey: "appLanguage") == nil {
            UserDefaults.standard.set("es", forKey: "appLanguage")
        }

        // Seeds no destructivo (background)
        let ctx = persistenceController.container.viewContext
        ctx.perform {
            SeedData.populateIfNeeded(context: ctx)
        }

        requestNotificationPermissions()
    }

    var body: some Scene {
        WindowGroup {
            // AppRootView será el contenedor que aplica el frutiger background desde su body,
            // y recibirá el theme y appState desde aquí (antes de construir la vista).
            AppRootView()
                .environmentObject(theme)      // inyecta theme ANTES de que AppRootView se evalúe
                .environmentObject(appState)   // inyecta appState
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.locale, Locale(identifier: appState.appLanguage))
        }
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted { print("🔔 Notificaciones permitidas") }
            else if let error = error { print("❌ Error en permisos de notificaciones: \(error.localizedDescription)") }
        }
    }
}

// Root wrapper view: aplica el background (FRUTIGER) asegurándose que theme ya esté disponible.
struct AppRootView: View {
    @EnvironmentObject var theme: AeroTheme
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) var viewContext

    var body: some View {
        // AchievementUIContainer es tu contenedor global (notificaciones/confetti)
        AchievementUIContainer {
            LoadingView()
                .environmentObject(appState)
                .environmentObject(theme)
                .environment(\.managedObjectContext, viewContext)
        }
        // Aplico el background AQUÍ dentro del body: theme ya está disponible en este punto.
        .frutigerAeroBackground()
    }
}
