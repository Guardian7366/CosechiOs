import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                // 🚀 Nuevo acceso al Dashboard
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
                
                // ✅ NUEVO: acceso a todas las tareas
                NavigationLink(destination: TaskListView()) {
                    MenuCardView(icon: "checklist", title: "Todas mis tareas")
                }
                
                NavigationLink(destination: UserProfileView()) {
                    MenuCardView(icon: "person.circle", title: "menu_profile")
                }

                // Cerrar sesión
                Button(role: .destructive) {
                    appState.isAuthenticated = false
                    appState.currentUserID = nil
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("logout")
                    }
                }
            }
            .navigationTitle("CosechiOs")
        }
    }
}
struct MenuCardView: View {
    let icon: String
    let title: LocalizedStringKey

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 36, height: 36)
                .background(Color(.systemGray6))
                .clipShape(Circle())

            Text(title)
                .font(.body)
                .padding(.leading, 4)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    MainMenuView().environmentObject(AppState())
}
