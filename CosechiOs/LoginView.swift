import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var authVM = AuthViewModel()

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            // 🌈 Fondo Frutiger Aero degradante
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "FF9A9E"),
                    Color(hex: "FAD0C4"),
                    Color(hex: "FBC2EB")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // ✨ Círculos difusos
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 260, height: 260)
                    .blur(radius: 60)
                    .offset(x: -120, y: -200)

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 220, height: 220)
                    .blur(radius: 50)
                    .offset(x: 140, y: -120)

                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 300, height: 300)
                    .blur(radius: 70)
                    .offset(x: 100, y: 260)
            }
            .ignoresSafeArea()

            // 📋 Contenido
            VStack(spacing: 22) {
                Spacer().frame(height: 80)

                Text("login_title")
                    .font(.largeTitle).bold()
                    .foregroundColor(.white)
                    .shadow(radius: 3)

                // Email
                TextField("login_email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .aeroTextField()
                    .accessibilityLabel("login_email")
                    .accessibilityHint("Introduce tu correo electrónico")

                // Password
                SecureField("login_password", text: $password)
                    .aeroTextField()
                    .accessibilityLabel("login_password")
                    .accessibilityHint("Introduce tu contraseña")

                // Errores
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .accessibilityLabel("error_message")
                        .accessibilityHint(error)
                }

                // Botón Login
                Button {
                    Task { await login() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .accessibilityLabel("loading")
                            .accessibilityHint("Procesando inicio de sesión")
                    } else {
                        Text("login_button")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "F7971E"),
                                        Color(hex: "FFD200")
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
                    }
                }
                .disabled(isLoading)
                .accessibilityLabel("login_button")
                .accessibilityHint("Inicia sesión con los datos ingresados")

                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("login_navtitle")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Lógica de login
    private func login() async {
        isLoading = true
        errorMessage = nil

        do {
            try await authVM.login(email: email, password: password)
            appState.currentUserID = authVM.currentUserID
            appState.isAuthenticated = true
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
