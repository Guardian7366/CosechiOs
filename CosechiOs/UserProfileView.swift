import SwiftUI
import CoreData
import UserNotifications

struct UserProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @State private var user: User?
    @State private var config: Config?

    @State private var usernameText: String = ""
    @State private var showingImagePicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var pickedUIImage: UIImage?

    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Perfil
                Section(header: Text("profile_title")) {
                    HStack {
                        Spacer()
                        VStack {
                            if let imgData = user?.profilePicture,
                               let ui = UIImage(data: imgData) {
                                Image(uiImage: ui)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 110, height: 110)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .shadow(radius: 3)
                            } else {
                                Image(systemName: "person.crop.square")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 110, height: 110)
                                    .foregroundColor(.secondary)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            HStack(spacing: 20) {
                                Button("profile_gallery") {
                                    imageSource = .photoLibrary
                                    showingImagePicker = true
                                }
                                Button("profile_camera") {
                                    imageSource = .camera
                                    showingImagePicker = true
                                }
                            }
                            .font(.caption)
                            .padding(.top, 6)
                        }
                        Spacer()
                    }

                    TextField(LocalizedStringKey("profile_username"), text: $usernameText)
                        .autocapitalization(.words)

                    HStack {
                        Text("profile_email")
                        Spacer()
                        Text(user?.email ?? "-")
                            .foregroundColor(.secondary)
                    }
                }

                // MARK: - Idioma
                Section(header: Text("profile_language")) {
                    Picker("profile_language", selection: Binding(
                        get: { config?.language ?? appState.appLanguage },
                        set: { newValue in
                            if let cfg = config {
                                cfg.language = newValue
                                try? ConfigHelper.save(cfg, context: viewContext)
                            } else if let uid = appState.currentUserID {
                                if let cfg = ConfigHelper.getOrCreateConfig(for: uid, context: viewContext) {
                                    cfg.language = newValue
                                    try? ConfigHelper.save(cfg, context: viewContext)
                                    self.config = cfg
                                }
                            }
                            DispatchQueue.main.async {
                                UserDefaults.standard.set(newValue, forKey: "appLanguage")
                                appState.appLanguage = newValue
                            }
                        })) {
                        Text("English").tag("en")
                        Text("Español").tag("es")
                    }
                }

                // MARK: - Notificaciones
                Section(header: Text("profile_notifications_settings")) {
                    Toggle(isOn: Binding(
                        get: { config?.notificationsEnabled ?? true },
                        set: { handleNotificationToggle(enabled: $0) }
                    )) {
                        Text("profile_notifications")
                    }

                    if config?.notificationsEnabled ?? true {
                        Toggle(isOn: Binding(
                            get: { config?.notifyTasks ?? true },
                            set: { updateConfig(\.notifyTasks, value: $0) }
                        )) {
                            Text("profile_notify_tasks")
                        }

                        Toggle(isOn: Binding(
                            get: { config?.notifyCrops ?? true },
                            set: { updateConfig(\.notifyCrops, value: $0) }
                        )) {
                            Text("profile_notify_crops")
                        }

                        Toggle(isOn: Binding(
                            get: { config?.notifyTips ?? false },
                            set: { updateConfig(\.notifyTips, value: $0) }
                        )) {
                            Text("profile_notify_tips")
                        }
                        
                        // NUEVO: enlace al historial
                        NavigationLink(destination: NotificationHistoryView()
                            .environment(\.managedObjectContext, viewContext)) {
                            Text("profile_notifications_history")
                        }
                    }
                }

                // MARK: - Apariencia
                Section {
                    Picker("profile_theme", selection: Binding(
                        get: { config?.theme ?? "Auto" },
                        set: { newValue in
                            if let cfg = config {
                                cfg.theme = newValue
                                try? ConfigHelper.save(cfg, context: viewContext)
                            }
                        })) {
                        Text("theme_auto").tag("Auto")
                        Text("theme_light").tag("Light")
                        Text("theme_dark").tag("Dark")
                    }
                }

                // MARK: - Extras
                Section {
                    Button(role: .destructive) {
                        user?.profilePicture = nil
                        try? viewContext.save()
                    } label: {
                        Text("profile_delete_photo")
                    }

                    Button {
                        alertMessage = NSLocalizedString("profile_export", comment: "")
                        showAlert = true
                    } label: {
                        Text("profile_export")
                    }
                }
            }
            .navigationTitle("profile_title")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveProfile) {
                        if isSaving { ProgressView() } else { Text("save") }
                    }
                }
            }
            .onAppear { loadUserAndConfig() }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: imageSource) { img in
                    let resized = img.resizeTo(maxDimension: 1024)
                    if let data = resized.jpegData(compressionQuality: 0.8) {
                        user?.profilePicture = data
                        try? viewContext.save()
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("alert_title"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("ok")))
            }
        }
    }

    // MARK: - Helpers
    private func loadUserAndConfig() {
        guard let uid = appState.currentUserID else { return }
        let fr: NSFetchRequest<User> = User.fetchRequest()
        fr.predicate = NSPredicate(format: "userID == %@", uid as CVarArg)
        fr.fetchLimit = 1
        if let loadedUser = try? viewContext.fetch(fr).first {
            self.user = loadedUser
            self.usernameText = loadedUser.username ?? ""
        }
        if let cfg = ConfigHelper.getOrCreateConfig(for: uid, context: viewContext) {
            self.config = cfg
            appState.appLanguage = cfg.language ?? appState.appLanguage
            UserDefaults.standard.set(cfg.language, forKey: "appLanguage")
        }
    }

    private func saveProfile() {
        guard let user = user else { return }
        isSaving = true
        user.username = usernameText.trimmingCharacters(in: .whitespacesAndNewlines)
        user.updatedAt = Date()
        do {
            try viewContext.save()
            alertMessage = NSLocalizedString("profile_saved_success", comment: "")
            showAlert = true
        } catch {
            alertMessage = String(format: NSLocalizedString("profile_saved_error", comment: ""), error.localizedDescription)
            showAlert = true
        }
        isSaving = false
    }

    private func handleNotificationToggle(enabled: Bool) {
        guard let uid = appState.currentUserID else { return }
        if let cfg = ConfigHelper.getOrCreateConfig(for: uid, context: viewContext) {
            cfg.notificationsEnabled = enabled
            try? ConfigHelper.save(cfg, context: viewContext)
            self.config = cfg
        }

        if enabled {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }

    private func updateConfig<T>(_ keyPath: ReferenceWritableKeyPath<Config, T>, value: T) {
        if let cfg = config {
            cfg[keyPath: keyPath] = value
            try? ConfigHelper.save(cfg, context: viewContext)
            self.config = cfg
        }
    }
}
