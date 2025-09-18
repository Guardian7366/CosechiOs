// AchievementsSummaryView.swift
import SwiftUI
import CoreData

struct AchievementsSummaryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let userID: UUID?

    @State private var xp: Int = 0
    @State private var level: Int = 1
    @State private var progress: Double = 0
    @State private var badgesCount: Int = 0

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(lineWidth: 8)
                    .opacity(0.15)
                    .frame(width: 72, height: 72)
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 72, height: 72)
                Text("\(level)")
                    .font(.headline)
            }

            VStack(alignment: .leading) {
                Text("\(xp) XP")
                    .font(.subheadline)
                Text(String(format: NSLocalizedString("achievements_badges_count", comment: ""), badgesCount))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
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
