import SwiftUI

struct IntroView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            if appState.isAuthenticated {
                MainMenuView()
            } else {
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Título y subtítulo localizados
                    Text("intro_title")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("intro_subtitle")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    // Botón de registro
                    NavigationLink(destination: RegisterView()) {
                        Text("register")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Botón de login
                    NavigationLink(destination: LoginView()) {
                        Text("login")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
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
