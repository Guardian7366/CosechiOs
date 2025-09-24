// UserProfileView.swift
// Vista de perfil con estética Frutiger Aero - con VoiceOver accesibilidad

import SwiftUI
import CoreData
import UserNotifications
import UIKit

struct UserProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: AeroTheme

    // Datos
    @State private var user: User?
    @State private var config: Config?

    // Edición
    @State private var usernameText: String = ""
    @State private var isSaving = false

    // Imagen
    @State private var showingImagePicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var pickedUIImage: UIImage? = nil
    @State private var showingEditor = false
    @State private var editedUIImage: UIImage? = nil
    @State private var imageRefreshID = UUID()
    @State private var showImageSourceOptions = false

    // UI / alerts
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showDeleteConfirm = false

    // Progress
    @State private var isUploadingImage = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo Frutiger Aero
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "D9F6E2"),
                        Color(hex: "BEEAF0"),
                        Color(hex: "FFFFFF").opacity(0.9)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                BubbleOverlay()
                    .opacity(0.06)

                // Contenido principal
                ScrollView {
                    VStack(spacing: 18) {
                        // Encabezado
                        GlassCard {
                            HStack(spacing: 14) {
                                profileAvatar
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(user?.username ?? NSLocalizedString("profile_anonymous", comment: "Anonymous"))
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.primary)

                                    Text(user?.email ?? "-")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    HStack(spacing: 8) {
                                        Text(LocalizedStringKey("CosechiOs"))
                                            .font(.caption2)
                                            .padding(6)
                                            .background(theme.mint.opacity(0.12))
                                            .cornerRadius(8)
                                            .foregroundColor(.primary)

                                        if let updated = user?.updatedAt {
                                            Text("\(updated, style: .date)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }

                        // Username edit
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedStringKey("profile_username"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                TextField(LocalizedStringKey("profile_username"), text: $usernameText)
                                    .autocapitalization(.words)
                                    .disableAutocorrection(true)
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.06)))
                                    .accessibilityLabel(Text(LocalizedStringKey("profile_username")))
                                    .accessibilityHint(Text("Introduce tu nombre de usuario"))
                            }
                        }

                        // Logros
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(LocalizedStringKey("profile_achievements_section"))
                                    .font(.headline)
                                if let uid = user?.userID {
                                    AchievementsSummaryView(userID: uid)
                                        .environment(\.managedObjectContext, viewContext)

                                    HStack {
                                        Spacer()
                                        NavigationLink(destination: AchievementsView(userID: uid).environment(\.managedObjectContext, viewContext)) {
                                            Text(LocalizedStringKey("profile_achievements_view_all"))
                                        }
                                        .accessibilityHint(Text("Ver todos los logros"))
                                    }
                                } else {
                                    Text("—").foregroundColor(.secondary)
                                }
                            }
                        }

                        // Idioma
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedStringKey("profile_language"))
                                    .font(.headline)

                                Picker(selection: Binding(
                                    get: { config?.language ?? appState.appLanguage },
                                    set: { newValue in changeLanguage(to: newValue) }
                                ), label: Text(LocalizedStringKey("profile_language"))) {
                                    Text("English").tag("en")
                                    Text("Español").tag("es")
                                }
                                .pickerStyle(.segmented)
                                .accessibilityLabel(Text(LocalizedStringKey("profile_language")))
                                .accessibilityHint(Text("Selecciona el idioma de la aplicación"))
                            }
                        }

                        // Notificaciones
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedStringKey("profile_notifications_settings"))
                                    .font(.headline)

                                Toggle(isOn: Binding(
                                    get: { config?.notificationsEnabled ?? true },
                                    set: { handleNotificationToggle(enabled: $0) }
                                )) {
                                    Text(LocalizedStringKey("profile_notifications"))
                                }
                                .accessibilityHint(Text("Activa o desactiva todas las notificaciones"))

                                if config?.notificationsEnabled ?? true {
                                    Toggle(isOn: Binding(
                                        get: { config?.notifyTasks ?? true },
                                        set: { updateConfig(\.notifyTasks, value: $0) }
                                    )) {
                                        Text(LocalizedStringKey("profile_notify_tasks"))
                                    }
                                    .accessibilityHint(Text("Notificar recordatorios de tareas"))

                                    Toggle(isOn: Binding(
                                        get: { config?.notifyCrops ?? true },
                                        set: { updateConfig(\.notifyCrops, value: $0) }
                                    )) {
                                        Text(LocalizedStringKey("profile_notify_crops"))
                                    }
                                    .accessibilityHint(Text("Notificar sobre cultivos"))

                                    Toggle(isOn: Binding(
                                        get: { config?.notifyTips ?? false },
                                        set: { updateConfig(\.notifyTips, value: $0) }
                                    )) {
                                        Text(LocalizedStringKey("profile_notify_tips"))
                                    }
                                    .accessibilityHint(Text("Recibir consejos y tips"))

                                    NavigationLink(destination: NotificationHistoryView().environment(\.managedObjectContext, viewContext)) {
                                        Text(LocalizedStringKey("profile_notifications_history"))
                                    }
                                    .accessibilityHint(Text("Ver historial de notificaciones"))
                                }
                            }
                        }

                        // Apariencia
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedStringKey("profile_theme"))
                                    .font(.headline)

                                Picker(selection: Binding(
                                    get: { config?.theme ?? "Auto" },
                                    set: { newVal in
                                        if let cfg = config {
                                            cfg.theme = newVal
                                            try? ConfigHelper.save(cfg, context: viewContext)
                                            self.config = cfg
                                        }
                                    }
                                ), label: Text(LocalizedStringKey("profile_theme"))) {
                                    Text(LocalizedStringKey("theme_auto")).tag("Auto")
                                    Text(LocalizedStringKey("theme_light")).tag("Light")
                                    Text(LocalizedStringKey("theme_dark")).tag("Dark")
                                }
                                .pickerStyle(.segmented)
                                .accessibilityHint(Text("Selecciona el tema de apariencia"))
                            }
                        }

                        // Extras
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Button(role: .destructive) {
                                    showDeleteConfirm = true
                                } label: {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text(LocalizedStringKey("profile_delete_photo"))
                                        Spacer()
                                    }
                                }
                                .accessibilityLabel(Text(LocalizedStringKey("profile_delete_photo")))
                                .accessibilityHint(Text("Elimina tu foto de perfil"))

                                Button {
                                    alertMessage = NSLocalizedString("profile_export", comment: "")
                                    showAlert = true
                                } label: {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text(LocalizedStringKey("profile_export"))
                                        Spacer()
                                    }
                                }
                                .accessibilityLabel(Text(LocalizedStringKey("profile_export")))
                                .accessibilityHint(Text("Exporta tus datos"))
                            }
                        }

                        Spacer(minLength: 32)
                    }
                    .padding()
                }
            }
            .navigationTitle(LocalizedStringKey("profile_title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveProfile) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(LocalizedStringKey("save"))
                        }
                    }
                    .accessibilityHint(Text("Guarda los cambios del perfil"))
                }
            }
            // Image picker + editor + alerts + confirmación
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
                        pickedUIImage = nil
                        saveEditedImage()
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
            .onAppear(perform: loadUserAndConfig)
        }
    }

    // MARK: - Avatar
    private var profileAvatar: some View {
        VStack {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let imgData = user?.profilePicture, let ui = UIImage(data: imgData) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .accessibilityLabel(Text("Foto de perfil"))
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white.opacity(0.85))
                            .background(Circle().fill(theme.primaryStart).opacity(0.12))
                            .accessibilityLabel(Text("Avatar de perfil predeterminado"))
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 2))
                .shadow(color: Color.black.opacity(0.16), radius: 6, x: 0, y: 3)
                .id(imageRefreshID)

                Button {
                    showImageSourceOptions = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .background(Circle().fill(theme.accent))
                        .frame(width: 36, height: 36)
                        .shadow(radius: 3)
                }
                .offset(x: -6, y: -6)
                .accessibilityLabel(Text("Editar foto de perfil"))
                .accessibilityHint(Text("Toca para cambiar tu foto de perfil"))
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
    }
    // MARK: - Lógica / Helpers (idéntica a la tuya; solo envuelta)
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
        isUploadingImage = true
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
        isUploadingImage = false
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

    private func changeLanguage(to newValue: String) {
        if let cfg = config {
            cfg.language = newValue
            try? ConfigHelper.save(cfg, context: viewContext)
            self.config = cfg
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
                .accessibilityLabel(Text("Vista previa de la imagen seleccionada"))
            Spacer()
            HStack {
                Button(LocalizedStringKey("cancel")) { dismiss() }
                    .accessibilityHint(Text("Cancelar edición de imagen"))
                Spacer()
                Button(LocalizedStringKey("save")) {
                    onSave(image)
                    dismiss()
                }
                .accessibilityHint(Text("Guardar imagen como foto de perfil"))
            }
            .padding()
        }
    }
}
