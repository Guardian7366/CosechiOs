import SwiftUI
import CoreData

struct AchievementsSummaryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var theme: AeroTheme
    let userID: UUID?

    @State private var xp: Int = 0
    @State private var level: Int = 1
    @State private var progress: Double = 0
    @State private var badgesCount: Int = 0

    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(theme.primaryStart.opacity(0.2), lineWidth: 8)
                        .frame(width: 72, height: 72)

                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            LinearGradient(colors: [theme.primaryStart, theme.primaryEnd],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 72, height: 72)

                    Text("\(level)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .accessibilityLabel(Text("Level \(level)"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(xp) XP")
                        .font(.subheadline)
                        .foregroundColor(theme.accent)
                        .accessibilityLabel(Text("\(xp) experience points"))

                    Text(String(format: NSLocalizedString("achievements_badges_count", comment: ""), badgesCount))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityLabel(Text("\(badgesCount) badges earned"))
                }
                Spacer()
            }
        }
        .onAppear(perform: load)
        .onReceive(NotificationCenter.default.publisher(for: .didUpdateAchievements)) { _ in load() }
    }

    private func load() {
        guard let uid = userID else { xp = 0; level = 1; progress = 0; badgesCount = 0; return }
        xp = AchievementManager.getXP(for: uid, context: viewContext)
        level = AchievementManager.getLevel(for: uid, context: viewContext)
        progress = AchievementManager.progressToNextLevel(for: uid, context: viewContext)
        badgesCount = AchievementManager.getBadges(for: uid, context: viewContext).count
    }
}
