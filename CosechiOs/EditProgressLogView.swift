// EditProgressLogView.swift
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
        FrutigerAeroBackground {
            ScrollView {
                VStack(spacing: 16) {
                    GlassCard {
                        TextEditor(text: $note)
                            .frame(minHeight: 100)
                            .foregroundColor(.white)
                    }

                    GlassCard {
                        Picker("progress_category", selection: $category) {
                            ForEach(categories, id: \.self) { cat in
                                Text(LocalizedStringKey(cat)).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(.white)
                    }

                    GlassCard {
                        if let img = image {
                            VStack {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                Button("remove_photo") {
                                    image = nil
                                }
                                .foregroundColor(.red)
                            }
                        } else {
                            Button("add_photo") { showImagePicker = true }
                        }
                    }
                }
                .padding()
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
        ProgressLogHelper.editLog(log, note: note.isEmpty ? nil : note, image: image, category: category, context: viewContext)
    }
}
