// AddProgressLogView.swift
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
                                Text(cat).tag(cat)
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
                                Button("remove_photo") { image = nil }
                                    .foregroundColor(.red)
                            }
                        } else {
                            Button("add_photo") { showImagePicker = true }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("new_progress")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        saveLog()
                        dismiss()
                    }
                    .disabled(note.isEmpty && image == nil)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $image, sourceType: .photoLibrary)
            }
        }
    }

    private func saveLog() {
        guard let userID = appState.currentUserID else { return }
        let fr: NSFetchRequest<User> = User.fetchRequest()
        fr.predicate = NSPredicate(format: "userID == %@", userID as CVarArg)
        if let user = try? viewContext.fetch(fr).first {
            ProgressLogHelper.addLog(for: crop, user: user, note: note.isEmpty ? nil : note, image: image, category: category, context: viewContext)
            AchievementManager.award(action: .addProgressLog, to: user.userID ?? UUID(), context: viewContext)
        }
    }
}
