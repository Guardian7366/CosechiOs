import SwiftUI
import CoreData

/// LoadingView.swift
/// Versión segura y actualizada de la pantalla de carga.
/// - Inserta datos de ejemplo (SeedData) si es necesario.
/// - Muestra una barra de progreso y navega a IntroView al terminar.

struct LoadingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) private var viewContext

    @State private var progress: Double = 0.0
    @State private var navigateToIntro: Bool = false
    @State private var statusMessage: String = "Cargando datos..."

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Logo / icono
                Image(systemName: "leaf.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.green)
                    .accessibilityHidden(true)

                // Barra de progreso
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(height: 8)
                        .padding(.horizontal, 40)

                    Text("\(Int(progress * 100))%")
                        .font(.subheadline)
                        .accessibilityLabel("Progreso \(Int(progress * 100)) por ciento")
                }
                .padding(.vertical, 8)

                Text(statusMessage)
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Spacer()

                // Enlace invisible que activa la navegación cuando `navigateToIntro` es true
                NavigationLink(destination:
                                IntroView()
                                .environment(\.managedObjectContext, viewContext)
                                .environmentObject(appState),
                               isActive: $navigateToIntro) {
                    EmptyView()
                }
                .hidden()
            }
            .padding()
            .onAppear {
                // Ejecutar la secuencia de inicio de forma asíncrona
                Task {
                    await runStartupSequence()
                }
            }
            // Ocultar la barra de navegación en la pantalla de carga
            .navigationBarHidden(true)
        }
    }

    // MARK: - Secuencia de inicio (async)
    @MainActor
    private func runStartupSequence() async {
        // Paso 1: progreso inicial
        withAnimation(.easeInOut(duration: 0.35)) { progress = 0.12 }
        statusMessage = "Preparando la aplicación…"

        // Paso 2: Sembrar datos si es necesario (ejecución segura en viewContext)
        statusMessage = "Insertando datos iniciales…"
        await seedIfNeededOnMainContext()

        // Animar progreso intermedio
        withAnimation(.easeInOut(duration: 0.45)) { progress = 0.55 }
        // Pequeña pausa para simular carga real (y dar tiempo a Core Data)
        try? await Task.sleep(nanoseconds: 350_000_000)

        // Paso 3: tareas finales de inicialización
        statusMessage = "Finalizando..."
        withAnimation(.easeInOut(duration: 0.35)) { progress = 0.92 }
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Paso 4: terminar y navegar
        withAnimation(.easeInOut(duration: 0.2)) { progress = 1.0 }
        statusMessage = "Listo"
        // Pequeña espera para que el usuario vea 100%
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Activar navegación a IntroView
        navigateToIntro = true
    }

    /// Ejecuta el seed de datos de forma segura en el contexto principal.
    /// Usamos `viewContext.perform` y lo adaptamos a async con una continuación.
    private func seedIfNeededOnMainContext() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            viewContext.perform {
                // Llama a tu helper. SeedData.populateIfNeeded ya maneja existence checks internamente.
                SeedData.populateIfNeeded(context: viewContext)
                continuation.resume()
            }
        }
    }
}

