// AchievementsView.swift
import SwiftUI

struct AchievementsView: View {
    let userID: UUID?

    @State private var xp: Int = 0
    @State private var level: Int = 1
    @State private var progress: Double = 0.0
    @State private var badges: [String] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                progressCircle
                Divider()
                badgesSection
                Spacer()
            }
            .padding()
        }
        .navigationTitle(LocalizedStringKey("achievements_title"))
        .onAppear(perform: load)
        .onReceive(NotificationCenter.default.publisher(for: .didUpdateAchievements)) { _ in load() }
    }

    private var header: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(LocalizedStringKey("achievements_subtitle"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var progressCircle: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 14)
                    .frame(width: 140, height: 140)
                Circle()
                    .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                    .stroke(style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 140, height: 140)
                    .foregroundColor(.green)
                VStack {
                    Text("\(level)")
                        .font(.title)
                        .bold()
                    Text(LocalizedStringKey("achievements_level"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("\(xp) XP")
                .font(.headline)
            Text(String(format: NSLocalizedString("achievements_to_next", comment: ""), Int((1.0 - progress) * Double(nextLevelXP()))))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func nextLevelXP() -> Int {
        guard let uid = userID else { return AchievementManager.xpForLevel(level+1) }
        let cur = AchievementManager.level(forXP: xp)
        return AchievementManager.xpForLevel(cur+1)
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(LocalizedStringKey("achievements_badges"))
                    .font(.headline)
                Spacer()
            }

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

    private func badgeCell(id: String) -> some View {
        let def = AchievementManager.badgeDefinitions[id]
        return VStack(spacing: 6) {
            Image(systemName: def?.symbol ?? "seal.fill")
                .font(.system(size: 28))
                .frame(width: 56, height: 56)
                .background(Color(.systemGray6))
                .clipShape(Circle())
            Text(LocalizedStringKey(def?.titleKey ?? "badge_unknown"))
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }

    private func load() {
        guard let uid = userID else {
            xp = 0; level = 1; badges = []
            progress = 0; return
        }
        xp = AchievementManager.getXP(for: uid)
        level = AchievementManager.level(forXP: xp)
        progress = AchievementManager.progressToNextLevel(for: uid)
        badges = AchievementManager.getBadges(for: uid)
    }
}

#if DEBUG
struct AchievementsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AchievementsView(userID: UUID())
        }
    }
}
#endif
