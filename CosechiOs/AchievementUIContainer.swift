// AchievementUIContainer.swift
import SwiftUI

struct AchievementUIContainer<Content: View>: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState

    @State private var showConfetti = false
    @State private var bannerMessage: String?
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        ZStack {
            content()

            if showConfetti {
                ConfettiView()
                    .transition(.opacity)
            }

            if let message = bannerMessage {
                VStack {
                    Spacer()
                    Text(message)
                        .padding()
                        .background(Color.blue.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didUpdateAchievements)) { note in
            guard let leveledUp = note.userInfo?["leveledUp"] as? Bool,
                  let newBadges = note.userInfo?["newBadges"] as? [String] else { return }

            if leveledUp {
                triggerConfetti()
                bannerMessage = NSLocalizedString("level_up_message", comment: "")
                dismissBannerAfterDelay()
            }

            if let badge = newBadges.first {
                let def = AchievementManager.badgeDefinitions[badge]
                let title = def?.titleKey ?? "badge_unlocked"
                bannerMessage = NSLocalizedString(title, comment: "")
                dismissBannerAfterDelay()
            }
        }
    }

    private func triggerConfetti() {
        withAnimation {
            showConfetti = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showConfetti = false
            }
        }
    }

    private func dismissBannerAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                bannerMessage = nil
            }
        }
    }
}
