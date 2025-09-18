// AchievementsSummaryView.swift
import SwiftUI

struct AchievementsSummaryView: View {
    let userID: UUID?

    @State private var xp: Int = 0
    @State private var level: Int = 1
    @State private var progress: Double = 0.0
    @State private var badges: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                progressMini
                VStack(alignment: .leading) {
                    Text(LocalizedStringKey("profile_achievements_title"))
                        .font(.headline)
                    Text(String(format: NSLocalizedString("profile_achievements_sub", comment: ""), level))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(badges.prefix(3), id: \.self) { id in
                    let symbol = AchievementManager.badgeDefinitions[id]?.symbol ?? "seal.fill"
                    Image(systemName: symbol)
                        .font(.title3)
                        .frame(width: 36, height: 36)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                if badges.count > 3 {
                    Text("+\(badges.count - 3)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if badges.isEmpty {
                    Text(LocalizedStringKey("profile_achievements_no_badges"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear(perform: load)
        .onReceive(NotificationCenter.default.publisher(for: .didUpdateAchievements)) { _ in load() }
    }

    private var progressMini: some View {
        ZStack {
            Circle().stroke(Color(.systemGray5), lineWidth: 8).frame(width: 60, height: 60)
            Circle().trim(from: 0, to: CGFloat(min(max(progress, 0), 1))).stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round)).rotationEffect(.degrees(-90)).frame(width: 60, height: 60).foregroundColor(.green)
            Text("\(level)").bold()
        }
    }

    private func load() {
        guard let uid = userID else { return }
        xp = AchievementManager.getXP(for: uid)
        level = AchievementManager.level(forXP: xp)
        progress = AchievementManager.progressToNextLevel(for: uid)
        badges = AchievementManager.getBadges(for: uid)
    }
}
