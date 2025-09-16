import SwiftUI
import CoreData

struct LoadingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) private var viewContext

    @State private var progress: Double = 0.0
    @State private var navigateToIntro: Bool = false
    @State private var statusMessage: LocalizedStringKey = "loading_preparing"

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "leaf.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.green)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(height: 8)
                        .padding(.horizontal, 40)

                    Text("\(Int(progress * 100))%")
                        .font(.subheadline)
                        .accessibilityLabel("progress_percent \(Int(progress * 100))")
                }
                .padding(.vertical, 8)

                Text(statusMessage)
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Spacer()

                .navigationDestination(isPresented: $navigateToIntro) {
                    IntroView()
                        .environment(\.managedObjectContext, viewContext)
                        .environmentObject(appState)
                }
                .hidden()
            }
            .padding()
            .onAppear {
                Task {
                    await runStartupSequence()
                }
            }
            .navigationBarHidden(true)
        }
    }

    @MainActor
    private func runStartupSequence() async {
        withAnimation(.easeInOut(duration: 0.35)) { progress = 0.12 }
        statusMessage = "loading_preparing"

        statusMessage = "loading_inserting"
        await seedIfNeededOnMainContext()

        withAnimation(.easeInOut(duration: 0.45)) { progress = 0.55 }
        try? await Task.sleep(nanoseconds: 350_000_000)

        statusMessage = "loading_finalizing"
        withAnimation(.easeInOut(duration: 0.35)) { progress = 0.92 }
        try? await Task.sleep(nanoseconds: 300_000_000)

        withAnimation(.easeInOut(duration: 0.2)) { progress = 1.0 }
        statusMessage = "loading_ready"
        try? await Task.sleep(nanoseconds: 200_000_000)

        navigateToIntro = true
    }

    private func seedIfNeededOnMainContext() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            viewContext.perform {
                SeedData.populateIfNeeded(context: viewContext)
                continuation.resume()
            }
        }
    }
}

