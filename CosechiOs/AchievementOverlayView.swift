// AchievementOverlayView.swift
import SwiftUI

struct AchievementOverlayView: View {
    @State private var showOverlay = false
    @State private var overlayType: String? = nil
    @State private var level: Int = 0
    @State private var badges: [String] = []

    var body: some View {
        ZStack {
            // Confeti + contenido solo si hay algo
            if showOverlay {
                ConfettiView()
                    .transition(.opacity)

                VStack(spacing: 16) {
                    if overlayType == "level" {
                        Text(String(format: NSLocalizedString("notif_level_up_body", comment: ""), level))
                            .font(.title2).bold()
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.green.opacity(0.7))
                                    .blur(radius: 4)
                            )
                    }

                    if overlayType == "badge" {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(badges, id: \.self) { badge in
                                    AchievementBadgeCard(badgeID: badge)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didUnlockAchievementUI)) { note in
            guard let info = note.userInfo else { return }
            if let type = info["type"] as? String {
                withAnimation {
                    overlayType = type
                    if type == "level" {
                        level = info["level"] as? Int ?? 0
                    } else if type == "badge" {
                        badges = info["badges"] as? [String] ?? []
                    }
                    showOverlay = true
                }

                // Auto ocultar después de 4s
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation {
                        showOverlay = false
                    }
                }
            }
        }
    }
}

