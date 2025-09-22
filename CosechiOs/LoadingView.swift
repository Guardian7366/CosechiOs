// LoadingView+FrutigerAero.swift
import SwiftUI
import CoreData

struct LoadingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: AeroTheme
    @Environment(\.managedObjectContext) private var viewContext

    @State private var progress: Double = 0.0
    @State private var navigateToIntro: Bool = false
    @State private var statusMessage: LocalizedStringKey = "loading_preparing"

    var body: some View {
        NavigationStack {
            ZStack {
                // 🚀 Fondo manual aquí
                theme.bgGradient.ignoresSafeArea()
                BubbleOverlay().opacity(theme.variant == .neon ? 0.12 : 0.06).ignoresSafeArea()
                VStack(spacing: 20) {
                    Spacer()

                    // Logo
                    GlassCard {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                theme.primaryStart.opacity(0.25),
                                                theme.primaryEnd.opacity(0.15)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 160, height: 160)
                                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)

                                Image(systemName: "leaf.fill")
                                    .renderingMode(.template)
                                    .aeroIconStyle(size: 104)
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [theme.primaryStart, theme.primaryEnd]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: theme.primaryStart.opacity(0.25), radius: 8, x: 0, y: 4)
                            }

                            Text(LocalizedStringKey("app_name"))
                                .font(.headline)
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(maxWidth: 320)

                    // Barra de progreso
                    GlassCard {
                        VStack(spacing: 12) {
                            AeroProgressBar(progress: progress)
                                .frame(height: 14)
                                .padding(.horizontal, 4)

                            HStack {
                                Text("\(Int(progress * 100))%")
                                    .font(.subheadline).bold()
                                    .accessibilityLabel(Text(String(format: NSLocalizedString("progress_percent", comment: ""), Int(progress * 100))))

                                Spacer()

                                Text(statusMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                    .frame(maxWidth: 380)

                    Spacer()

                    Text(LocalizedStringKey("loading_hint"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 16)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationDestination(isPresented: $navigateToIntro) {
                IntroView()
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(appState)
                    .environmentObject(theme)
            }
        }
        .navigationBarHidden(true)
        .onAppear { Task { await runStartupSequence() } }
    }

    // MARK: - ProgressBar
    private struct AeroProgressBar: View {
        var progress: Double
        @EnvironmentObject var theme: AeroTheme
        var body: some View {
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12)).frame(height: 10)
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [theme.primaryStart, theme.primaryEnd]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(6, w * CGFloat(min(1.0, max(0.0, progress)))), height: 10)
                        .shadow(color: theme.primaryStart.opacity(0.25), radius: 8, x: 0, y: 4)
                }
                .cornerRadius(20)
            }
            .frame(height: 10)
        }
    }

    // MARK: - Startup
    @MainActor
    private func runStartupSequence() async {
        let start = Date()

        withAnimation(.easeInOut(duration: 1.0)) { progress = 0.12 }
        statusMessage = "loading_preparing"

        statusMessage = "loading_inserting"
        await seedIfNeededOnMainContext()

        withAnimation(.easeInOut(duration: 1.5)) { progress = 0.55 }
        try? await Task.sleep(nanoseconds: 1_200_000_000)

        statusMessage = "loading_finalizing"
        withAnimation(.easeInOut(duration: 1.2)) { progress = 0.92 }
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        withAnimation(.easeInOut(duration: 0.8)) { progress = 1.0 }
        statusMessage = "loading_ready"

        let elapsed = Date().timeIntervalSince(start)
        let minimum: Double = 5.0
        if elapsed < minimum {
            let remaining = minimum - elapsed
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
        }

        navigateToIntro = true
    }

    private func seedIfNeededOnMainContext() async {
        await withCheckedContinuation { continuation in
            viewContext.perform {
                SeedData.populateIfNeeded(context: viewContext)
                continuation.resume()
            }
        }
    }
}
