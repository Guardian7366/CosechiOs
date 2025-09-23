import SwiftUI
import CoreData
import UIKit

struct EditProgressLogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: AeroTheme

    @State private var note: String
    @State private var image: UIImage?
    @State private var showImagePicker = false
    @State private var category: String

    let categories = ["progress_general", "progress_irrigation", "progress_fertilization", "progress_pest", "progress_harvest"]
    var log: ProgressLog

    init(log: ProgressLog) {
        self.log = log
        _note = State(initialValue: log.note ?? "")
        _category = State(initialValue: log.category ?? "progress_general")
        if let data = log.imageData, let ui = UIImage(data: data) {
            _image = State(initialValue: ui)
        } else {
            _image = State(initialValue: nil)
        }
    }

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
                                    }
                                    TextEditor(text: $note)
                                        .scrollContentBackground(.hidden)
                                        .frame(minHeight: 120)
                                        .padding(8)
                                        .background(Color.black.opacity(0.25))
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
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
                                        Text(LocalizedStringKey(cat)).tag(cat)
                                    }
                                }
                                .pickerStyle(.menu)
                                .foregroundColor(.white)
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
                                        Button("remove_photo") { image = nil }
                                            .foregroundColor(.red)
                                    }
                                } else {
                                    Button("add_photo") { showImagePicker = true }
                                        .buttonStyle(AeroButtonStyle(filled: false))
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("edit_progress")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && image == nil)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $image, sourceType: .photoLibrary)
            }
        }
    }

    private func saveChanges() {
        ProgressLogHelper.editLog(
            log,
            note: note.isEmpty ? nil : note,
            image: image,
            category: category,
            context: viewContext
        )
    }
}
