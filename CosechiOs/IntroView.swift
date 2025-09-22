import SwiftUI

struct IntroView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            if appState.isAuthenticated {
                MainMenuView()
            } else {
                ZStack {
                    // 🌿 Fondo degradante verde
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "A8E063"), // verde claro
                            Color(hex: "56AB2F")  // verde oscuro
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        Spacer()
                        
                        // Título y subtítulo localizados
                        Text(LocalizedStringKey("intro_title"))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .shadow(radius: 3)
                        
                        Text(LocalizedStringKey("intro_subtitle"))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Spacer()
                        
                        // Botón de registro
                        NavigationLink(destination: RegisterView()) {
                            Text(LocalizedStringKey("register"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "00C9FF"),
                                            Color(hex: "92FE9D")
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                        }
                        .padding(.horizontal)
                        
                        // Botón de login
                        NavigationLink(destination: LoginView()) {
                            Text(LocalizedStringKey("login"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .foregroundColor(.black)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding()
                }
                .navigationTitle("")
                .navigationBarHidden(true)
            }
        }
    }
}

#Preview {
    IntroView().environmentObject(AppState())
}

