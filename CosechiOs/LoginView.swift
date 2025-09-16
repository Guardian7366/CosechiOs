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
        VStack(spacing: 20) {
            Text("login_title")
                .font(.largeTitle).bold()

            TextField("login_email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)

            SecureField("login_password", text: $password)
                .textFieldStyle(.roundedBorder)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button {
                Task { await login() }
            } label: {
                if isLoading {
                    ProgressView()
                } else {
                    Text("login_button")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)

            Spacer()
        }
        .padding()
        .navigationTitle("login_navtitle")
    }

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
