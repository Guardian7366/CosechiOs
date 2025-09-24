import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var authVM = AuthViewModel()

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var showPassword = false
    @State private var showConfirmPassword = false

    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            // 🌈 Fondo Frutiger Aero degradante
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "89F7FE"),
                    Color(hex: "66A6FF"),
                    Color(hex: "D16BA5")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // ✨ Círculos difusos estilo "aero bubbles"
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 280, height: 280)
                    .blur(radius: 60)
                    .offset(x: -140, y: -200)

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 240, height: 240)
                    .blur(radius: 50)
                    .offset(x: 160, y: -100)

                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 300, height: 300)
                    .blur(radius: 70)
                    .offset(x: 100, y: 300)
            }
            .ignoresSafeArea()

            // 📋 Contenido principal
            VStack(spacing: 20) {
                Spacer().frame(height: 95)

                Text("register_title")
                    .font(.largeTitle).bold()
                    .foregroundColor(.white)
                    .shadow(radius: 3)

                // Nombre de usuario
                TextField("register_username", text: $username)
                    .aeroTextField()
                    .accessibilityLabel("register_username")
                    .accessibilityHint("Introduce tu nombre de usuario")

                // Email
                TextField("register_email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .aeroTextField()
                    .accessibilityLabel("register_email")
                    .accessibilityHint("Introduce tu correo electrónico")

                // Contraseña
                HStack {
                    if showPassword {
                        TextField("register_password", text: $password)
                            .textContentType(.oneTimeCode)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .aeroTextField()
                            .accessibilityLabel("register_password")
                            .accessibilityHint("Introduce tu contraseña")
                    } else {
                        SecureField("register_password", text: $password)
                            .textContentType(.oneTimeCode)
                            .aeroTextField()
                            .accessibilityLabel("register_password")
                            .accessibilityHint("Introduce tu contraseña")
                    }

                    Button { showPassword.toggle() } label: {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .accessibilityLabel("toggle_password_visibility")
                    .accessibilityHint("Muestra u oculta la contraseña")
                }

                // Confirmar contraseña
                HStack {
                    if showConfirmPassword {
                        TextField("register_confirm_password", text: $confirmPassword)
                            .textContentType(.oneTimeCode)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .aeroTextField()
                            .accessibilityLabel("register_confirm_password")
                            .accessibilityHint("Vuelve a escribir tu contraseña")
                    } else {
                        SecureField("register_confirm_password", text: $confirmPassword)
                            .textContentType(.oneTimeCode)
                            .aeroTextField()
                            .accessibilityLabel("register_confirm_password")
                            .accessibilityHint("Vuelve a escribir tu contraseña")
                    }

                    Button { showConfirmPassword.toggle() } label: {
                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .accessibilityLabel("toggle_confirm_password_visibility")
                    .accessibilityHint("Muestra u oculta la confirmación de la contraseña")
                }

                // Errores
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .accessibilityLabel("error_message")
                        .accessibilityHint(error)
                }

                // Botón Registrar
                Button {
                    Task { await register() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .accessibilityLabel("loading")
                            .accessibilityHint("Procesando tu registro")
                    } else {
                        Text("register_button")
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
                }
                .disabled(isLoading)
                .accessibilityLabel("register_button")
                .accessibilityHint("Crea una nueva cuenta con los datos ingresados")

                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("register_navtitle")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Lógica de registro
    private func register() async {
        guard password == confirmPassword else {
            errorMessage = NSLocalizedString("error_password_mismatch", comment: "")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authVM.register(username: username, email: email, password: password)
            appState.currentUserID = authVM.currentUserID
            appState.isAuthenticated = true
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
