import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var appState: AppState

    init() {
        // 🔧 Personalizar la barra de navegación para quitar el fondo blanco
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.backgroundEffect = nil
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 🌈 Fondo frutiger degradante
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "43CEA2"), // verde aqua
                        Color(hex: "185A9D")  // azul profundo
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // ✨ Overlay burbujas suaves
                BubbleOverlay()
                    .opacity(0.08)

                // 📋 Lista con tarjetas
                ScrollView {
                    VStack(spacing: 16) {
                        NavigationLink(destination: DashboardView()) {
                            MenuCardView(icon: "speedometer", title: "dashboard_title")
                        }

                        NavigationLink(destination: MyCropsView()) {
                            MenuCardView(icon: "leaf.fill", title: "menu_my_crops")
                        }

                        NavigationLink(destination: ExploreCropsView()) {
                            MenuCardView(icon: "book.fill", title: "menu_explore")
                        }

                        NavigationLink(destination: TaskCalendarView()) {
                            MenuCardView(icon: "calendar", title: "menu_tasks")
                        }

                        NavigationLink(destination: TaskListView()) {
                            MenuCardView(icon: "checklist", title: "menu_all_tasks")
                        }

                        NavigationLink(destination: UserProfileView()) {
                            MenuCardView(icon: "person.circle", title: "menu_profile")
                        }

                        Button(role: .destructive) {
                            appState.isAuthenticated = false
                            appState.currentUserID = nil
                        } label: {
                            GlassCard {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .foregroundColor(.red)
                                        .font(.title3)
                                    Text("logout")
                                        .font(.body).bold()
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("app_name")
            .navigationBarBackButtonHidden(true) // 👈 elimina el botón "<"
        }
    }
}

struct MenuCardView: View {
    let icon: String
    let title: LocalizedStringKey

    var body: some View {
        GlassCard {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "00D4FF"),
                                    Color(hex: "00C37A")
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.title3)
                }

                Text(title)
                    .font(.body).bold()
                    .foregroundColor(.primary)
                    .padding(.leading, 8)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 6)
        }
    }
}
