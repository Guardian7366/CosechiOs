import SwiftUI
import CoreData
import UIKit

struct AddProgressLogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: AeroTheme
    @Environment(\.dismiss) private var dismiss

    let crop: Crop

    @State private var note: String = ""
    @State private var image: UIImage?
    @State private var showImagePicker = false
    @State private var category: String = "General"

    let categories = ["General", "Riego", "Fertilización", "Plaga", "Cosecha"]

    var body: some View {
        NavigationStack {
            FrutigerAeroBackground {
                ScrollView {
                    VStack(spacing: 16) {
                        // 📝 Nota
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("progress_note")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.9))

                                ZStack(alignment: .topLeading) {
                                    if note.isEmpty {
                                        Text("Escribe aquí tu nota...")
                                            .foregroundColor(.white.opacity(0.4))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 14)
                                            .accessibilityHidden(true)
                                    }
                                    TextEditor(text: $note)
                                        .scrollContentBackground(.hidden)
                                        .frame(minHeight: 120)
                                        .padding(8)
                                        .background(Color.black.opacity(0.25))
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                        .accessibilityLabel("progress_note")
                                        .accessibilityHint("Ingresa una nota de progreso para tu cultivo")
                                }
                            }
                        }

                        // 📂 Categoría
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("progress_category")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.9))

                                Picker("progress_category", selection: $category) {
                                    ForEach(categories, id: \.self) { cat in
                                        Text(cat).tag(cat)
                                    }
                                }
                                .pickerStyle(.menu)
                                .foregroundColor(.white)
                                .accessibilityLabel("progress_category")
                                .accessibilityHint("Selecciona la categoría correspondiente al progreso")
                            }
                        }

                        // 📸 Foto
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("progress_photo")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.9))

                                if let img = image {
                                    VStack {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 200)
                                            .accessibilityLabel("Foto seleccionada para el progreso")

                                        Button("remove_photo") { image = nil }
                                            .foregroundColor(.red)
                                            .accessibilityLabel("remove_photo")
                                            .accessibilityHint("Elimina la foto seleccionada")
                                    }
                                } else {
                                    Button("add_photo") { showImagePicker = true }
                                        .buttonStyle(AeroButtonStyle(filled: false))
                                        .accessibilityLabel("add_photo")
                                        .accessibilityHint("Agrega una foto a tu progreso")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("new_progress")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                        .accessibilityLabel("cancel")
                        .accessibilityHint("Cancela y cierra el formulario sin guardar")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        saveLog()
                        dismiss()
                    }
                    .disabled(note.isEmpty && image == nil)
                    .accessibilityLabel("save")
                    .accessibilityHint("Guarda este progreso en tu historial")
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $image, sourceType: .photoLibrary)
                    .accessibilityLabel("image_picker")
                    .accessibilityHint("Selecciona una foto de tu biblioteca")
            }
        }
    }

    private func saveLog() {
        guard let userID = appState.currentUserID else { return }
        let fr: NSFetchRequest<User> = User.fetchRequest()
        fr.predicate = NSPredicate(format: "userID == %@", userID as CVarArg)
        if let user = try? viewContext.fetch(fr).first {
            ProgressLogHelper.addLog(
                for: crop,
                user: user,
                note: note.isEmpty ? nil : note,
                image: image,
                category: category,
                context: viewContext
            )
            AchievementManager.award(action: .addProgressLog, to: user.userID ?? UUID(), context: viewContext)
        }
    }
}
