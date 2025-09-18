// AchievementsView.swift
import SwiftUI
import CoreData

struct AchievementsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    let userID: UUID?

    @State private var xp: Int = 0
    @State private var level: Int = 1
    @State private var progress: Double = 0.0
    @State private var badges: [String] = []

    var body: some View {
        VStack(spacing: 16) {
            header
            progressSection
            badgesGrid
            Spacer()
        }
        .padding()
        .navigationTitle(LocalizedStringKey("achievements_title"))
        .onAppear(perform: load)
        .onReceive(NotificationCenter.default.publisher(for: .didUpdateAchievements)) { note in
            // If user updated matches, reload
            if let info = note.userInfo, let uid = info["userID"] as? UUID, uid == userID {
                load()
            } else {
                // fallback reload
                load()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(LocalizedStringKey("achievements_your_level"))
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(level)")
                .font(.system(size: 46, weight: .bold))
            Text("\(xp) XP")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey("achievements_progress"))
                .font(.headline)
            ProgressView(value: progress)
                .frame(height: 12)
                .accentColor(.green)
            HStack {
                Text(String(format: NSLocalizedString("achievements_progress_pct", comment: ""), Int(progress * 100)))
                    .font(.caption)
                Spacer()
                Text(String(format: NSLocalizedString("achievements_level_next", comment: ""), level + 1))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var badgesGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey("achievements_badges"))
                .font(.headline)

            if badges.isEmpty {
                Text(LocalizedStringKey("achievements_no_badges"))
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                    ForEach(badges, id: \.self) { id in
                        badgeCell(id: id)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func badgeCell(id: String) -> some View {
        let meta = AchievementManager.badgeDefinitions[id]
        VStack(spacing: 6) {
            if let symbol = meta?.symbol {
                Image(systemName: symbol)
                    .font(.system(size: 28))
                    .frame(width: 56, height: 56)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(width: 56, height: 56)
            }
            Text(LocalizedStringKey(meta?.titleKey ?? id))
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
    }

    private func load() {
        guard let uid = userID else {
            xp = 0; level = 1; progress = 0.0; badges = []
            return
        }
        xp = AchievementManager.getXP(for: uid, context: viewContext)
        level = AchievementManager.getLevel(for: uid, context: viewContext)
        progress = AchievementManager.progressToNextLevel(for: uid, context: viewContext)
        badges = AchievementManager.getBadges(for: uid, context: viewContext)
    }
}
