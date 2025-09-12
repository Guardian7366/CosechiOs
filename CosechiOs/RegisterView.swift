import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var authVM = AuthViewModel()

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Crear cuenta")
                .font(.largeTitle).bold()

            TextField("Nombre de usuario", text: $username)
                .textFieldStyle(.roundedBorder)

            TextField("Correo electrónico", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)

            SecureField("Contraseña", text: $password)
                .textFieldStyle(.roundedBorder)

            SecureField("Confirmar contraseña", text: $confirmPassword)
                .textFieldStyle(.roundedBorder)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button {
                Task {
                    await register()
                }
            } label: {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Registrarse")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)

            Spacer()
        }
        .padding()
        .navigationTitle("Registro")
    }

    private func register() async {
        guard password == confirmPassword else {
            errorMessage = "Las contraseñas no coinciden."
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

