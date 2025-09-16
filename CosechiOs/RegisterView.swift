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
        VStack(spacing: 20) {
            Text("register_title")
                .font(.largeTitle).bold()

            // Nombre de usuario
            TextField("register_username", text: $username)
                .textFieldStyle(.roundedBorder)

            // Email
            TextField("register_email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .textFieldStyle(.roundedBorder)

            // Contraseña
            HStack {
                if showPassword {
                    TextField("register_password", text: $password)
                        .textContentType(.oneTimeCode) // 🚫 elimina cuadro amarillo
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textFieldStyle(.roundedBorder)
                } else {
                    SecureField("register_password", text: $password)
                        .textContentType(.oneTimeCode) // 🚫 elimina cuadro amarillo
                        .textFieldStyle(.roundedBorder)
                }

                Button { showPassword.toggle() } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
            }

            // Confirmar contraseña
            HStack {
                if showConfirmPassword {
                    TextField("register_confirm_password", text: $confirmPassword)
                        .textContentType(.oneTimeCode) // 🚫 elimina cuadro amarillo
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textFieldStyle(.roundedBorder)
                } else {
                    SecureField("register_confirm_password", text: $confirmPassword)
                        .textContentType(.oneTimeCode) // 🚫 elimina cuadro amarillo
                        .textFieldStyle(.roundedBorder)
                }

                Button { showConfirmPassword.toggle() } label: {
                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
            }

            // Errores
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            // Botón Registrar
            Button {
                Task { await register() }
            } label: {
                if isLoading {
                    ProgressView()
                } else {
                    Text("register_button")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)

            Spacer()
        }
        .padding()
        .navigationTitle("register_navtitle")
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
