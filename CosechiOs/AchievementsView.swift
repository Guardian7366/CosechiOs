// AchievementsView.swift
import SwiftUI
import CoreData

struct AchievementsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var theme: AeroTheme

    let userID: UUID?

    @State private var xp: Int = 0
    @State private var level: Int = 1
    @State private var progress: Double = 0.0
    @State private var badges: [String] = []

    var body: some View {
        FrutigerAeroBackground {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    progressSection
                    badgesGrid
                }
                .padding()
            }
        }
        .navigationTitle(LocalizationHelper.shared.localized("achievements_title"))
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(LocalizationHelper.shared.localized("achievements_title"))
                    .aeroTextPrimary(theme)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.35))
                    .cornerRadius(6)
                    .shadow(color: .black.opacity(0.7), radius: 3, x: 0, y: 1)
                    .font(.headline)
                    .accessibilityHidden(true) // evitamos duplicación en VoiceOver
            }
        }
        .onAppear(perform: load)
        .onReceive(NotificationCenter.default.publisher(for: .didUpdateAchievements)) { note in
            if let info = note.userInfo, let uid = info["userID"] as? UUID, uid == userID {
                load()
            } else {
                load()
            }
        }
    }

    private var header: some View {
        GlassCard {
            VStack(spacing: 6) {
                Text(LocalizedStringKey("achievements_your_level"))
                    .font(.caption)
                    .aeroTextSecondary(theme)

                Text("\(level)")
                    .font(.system(size: 46, weight: .bold))
                    .aeroTextPrimary(theme)
                    .shadow(color: .green.opacity(0.5), radius: 3, x: 0, y: 1)
                    .accessibilityLabel(Text("Level \(level)"))

                Text("\(xp) XP")
                    .font(.subheadline)
                    .foregroundColor(theme.accent)
                    .accessibilityLabel(Text("\(xp) experience points"))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var progressSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(LocalizedStringKey("achievements_progress"))
                    .font(.headline)
                    .aeroTextPrimary(theme)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.35))
                    .cornerRadius(4)
                    .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)

                ProgressView(value: progress)
                    .frame(height: 14)
                    .tint(theme.mint)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityValue(Text("\(Int(progress * 100)) percent complete"))

                HStack {
                    Text(String(format: NSLocalizedString("achievements_progress_pct", comment: ""), Int(progress * 100)))
                        .font(.caption)
                        .aeroTextSecondary(theme)
                    Spacer()
                    Text(String(format: NSLocalizedString("achievements_level_next", comment: ""), level + 1))
                        .font(.caption)
                        .aeroTextSecondary(theme)
                }
            }
        }
    }

    private var badgesGrid: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringKey("achievements_badges"))
                    .font(.headline)
                    .aeroTextPrimary(theme)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.35))
                    .cornerRadius(4)
                    .shadow(color: .black.opacity(0.7), radius: 3, x: 0, y: 1)

                if badges.isEmpty {
                    Text(LocalizedStringKey("achievements_no_badges"))
                        .aeroTextSecondary(theme)
                        .accessibilityLabel(Text("No badges earned yet"))
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 14) {
                        ForEach(badges, id: \.self) { id in
                            badgeCell(id: id)
                        }
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
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(theme.primaryStart.opacity(0.15))
                    )
                    .foregroundColor(theme.accent)
                    .accessibilityHidden(true)
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 60, height: 60)
                    .accessibilityHidden(true)
            }

            Text(LocalizedStringKey(meta?.titleKey ?? id))
                .font(.caption2)
                .aeroTextPrimary(theme)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.45))
                .cornerRadius(4)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                .accessibilityLabel(Text(meta?.titleKey ?? id))
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
