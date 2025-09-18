// UserProfileView.swift
import SwiftUI
import CoreData
import UserNotifications
import UIKit

struct UserProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @State private var user: User?
    @State private var config: Config?

    @State private var usernameText: String = ""
    @State private var showingImagePicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var pickedUIImage: UIImage? = nil
    @State private var showingEditor = false
    @State private var editedUIImage: UIImage? = nil
    @State private var imageRefreshID = UUID()
    @State private var showImageSourceOptions = false

    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                // PERFIL
                Section(header: Text(LocalizedStringKey("profile_title"))) {
                    profileHeader
                    TextField(LocalizedStringKey("profile_username"), text: $usernameText)
                        .autocapitalization(.words)

                    HStack {
                        Text(LocalizedStringKey("profile_email"))
                        Spacer()
                        Text(user?.email ?? "-")
                            .foregroundColor(.secondary)
                    }
                }

                // LOGROS
                Section(header: Text(LocalizedStringKey("profile_achievements_section"))) {
                    if let uid = user?.userID {
                        AchievementsSummaryView(userID: uid)
                        NavigationLink(destination: AchievementsView(userID: uid)) {
                            Text(LocalizedStringKey("profile_achievements_view_all"))
                        }
                    } else {
                        Text("—")
                            .foregroundColor(.secondary)
                    }
                }

                // IDIOMA
                Section(header: Text(LocalizedStringKey("profile_language"))) {
                    languagePicker
                }

                // NOTIFICACIONES
                Section(header: Text(LocalizedStringKey("profile_notifications_settings"))) {
                    notificationsSection
                }

                // APARIENCIA
                Section {
                    themePicker
                }

                // EXTRAS
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Text(LocalizedStringKey("profile_delete_photo"))
                    }

                    Button {
                        alertMessage = NSLocalizedString("profile_export", comment: "")
                        showAlert = true
                    } label: {
                        Text(LocalizedStringKey("profile_export"))
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("profile_title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveProfile) {
                        if isSaving { ProgressView() } else { Text(LocalizedStringKey("save")) }
                    }
                }
            }
            .onAppear { loadUserAndConfig() }

            // ImagePicker
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $pickedUIImage, sourceType: imageSource)
            }
            .onChange(of: pickedUIImage) { new in
                guard new != nil else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    showingEditor = true
                }
            }
            .fullScreenCover(isPresented: $showingEditor) {
                if let picked = pickedUIImage {
                    AvatarEditorView(image: picked) { result in
                        editedUIImage = result
                        saveEditedImage()
                        pickedUIImage = nil
                        showingEditor = false
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(LocalizedStringKey("alert_title")),
                      message: Text(alertMessage),
                      dismissButton: .default(Text(LocalizedStringKey("ok"))))
            }
            .confirmationDialog(LocalizedStringKey("profile_delete_photo_confirm"),
                                isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button(LocalizedStringKey("delete"), role: .destructive) {
                    user?.profilePicture = nil
                    try? viewContext.save()
                    imageRefreshID = UUID()
                }
                Button(LocalizedStringKey("cancel"), role: .cancel) {}
            }
        }
    }

    // MARK: - Subviews

    private var profileHeader: some View {
        HStack {
            Spacer()
            VStack {
                ZStack(alignment: .bottomTrailing) {
                    if let imgData = user?.profilePicture, let ui = UIImage(data: imgData) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))
                            .shadow(radius: 4)
                            .id(imageRefreshID)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.secondary)
                            .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))
                            .id(imageRefreshID)
                    }

                    Button {
                        showImageSourceOptions = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                            .background(Color.white.clipShape(Circle()))
                    }
                    .offset(x: -8, y: -8)
                    .buttonStyle(.plain)
                    .confirmationDialog(LocalizedStringKey("profile_choose_image"),
                                        isPresented: $showImageSourceOptions,
                                        titleVisibility: .visible) {
                        Button(LocalizedStringKey("profile_take_photo")) {
                            openImagePicker(source: .camera)
                        }
                        Button(LocalizedStringKey("profile_choose_from_gallery")) {
                            openImagePicker(source: .photoLibrary)
                        }
                        Button(LocalizedStringKey("cancel"), role: .cancel) {}
                    }
                }
            }
            Spacer()
        }
    }

    private var languagePicker: some View {
        Picker(LocalizedStringKey("profile_language"), selection: Binding(
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

    private var notificationsSection: some View {
        Group {
            Toggle(isOn: Binding(
                get: { config?.notificationsEnabled ?? true },
                set: { handleNotificationToggle(enabled: $0) }
            )) {
                Text(LocalizedStringKey("profile_notifications"))
            }

            if config?.notificationsEnabled ?? true {
                Toggle(isOn: Binding(
                    get: { config?.notifyTasks ?? true },
                    set: { updateConfig(\.notifyTasks, value: $0) }
                )) {
                    Text(LocalizedStringKey("profile_notify_tasks"))
                }

                Toggle(isOn: Binding(
                    get: { config?.notifyCrops ?? true },
                    set: { updateConfig(\.notifyCrops, value: $0) }
                )) {
                    Text(LocalizedStringKey("profile_notify_crops"))
                }

                Toggle(isOn: Binding(
                    get: { config?.notifyTips ?? false },
                    set: { updateConfig(\.notifyTips, value: $0) }
                )) {
                    Text(LocalizedStringKey("profile_notify_tips"))
                }

                NavigationLink(destination: NotificationHistoryView().environment(\.managedObjectContext, viewContext)) {
                    Text(LocalizedStringKey("profile_notifications_history"))
                }
            }
        }
    }

    private var themePicker: some View {
        Picker(LocalizedStringKey("profile_theme"), selection: Binding(
            get: { config?.theme ?? "Auto" },
            set: { newValue in
                if let cfg = config {
                    cfg.theme = newValue
                    try? ConfigHelper.save(cfg, context: viewContext)
                }
            })) {
            Text(LocalizedStringKey("theme_auto")).tag("Auto")
            Text(LocalizedStringKey("theme_light")).tag("Light")
            Text(LocalizedStringKey("theme_dark")).tag("Dark")
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
            imageRefreshID = UUID()
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

    private func saveEditedImage() {
        guard let edited = editedUIImage else { return }
        let resized = edited.resizeTo(maxDimension: 1024)
        if let data = resized.jpegData(compressionQuality: 0.8) {
            user?.profilePicture = data
            do {
                try viewContext.save()
                imageRefreshID = UUID()
                alertMessage = NSLocalizedString("profile_image_saved", comment: "")
                showAlert = true
            } catch {
                alertMessage = String(format: NSLocalizedString("profile_image_save_error", comment: ""), error.localizedDescription)
                showAlert = true
            }
        }
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

    private func openImagePicker(source: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(source) {
            imageSource = source
            showingImagePicker = true
        } else {
            if source == .camera {
                alertMessage = NSLocalizedString("profile_camera_unavailable", comment: "")
            } else {
                alertMessage = NSLocalizedString("profile_source_unavailable", comment: "")
            }
            showAlert = true
        }
    }
}

// MARK: - Avatar Editor
struct AvatarEditorView: View {
    let image: UIImage
    var onSave: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Spacer()
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
                .padding()
            Spacer()
            HStack {
                Button(LocalizedStringKey("cancel")) { dismiss() }
                Spacer()
                Button(LocalizedStringKey("save")) {
                    onSave(image)
                    dismiss()
                }
            }
            .padding()
        }
    }
}
