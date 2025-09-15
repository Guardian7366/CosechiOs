import SwiftUI
import CoreData
import UIKit

struct AddProgressLogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let crop: Crop

    @State private var note: String = ""
    @State private var image: UIImage?
    @State private var showImagePicker = false
    @State private var category: String = "General"

    let categories = ["General", "Riego", "Fertilización", "Plaga", "Cosecha"]

    var body: some View {
        NavigationStack {
            Form {
                Section("progress_note") {
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                }

                Section("progress_category") {
                    Picker("Categoría", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }

                Section("progress_photo") {
                    if let img = image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                        Button("remove_photo") {
                            image = nil
                        }
                        .foregroundColor(.red)
                    } else {
                        Button("add_photo") {
                            showImagePicker = true
                        }
                    }
                }
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
                ImagePicker { img in image = img }
            }
        }
    }

    private func saveLog() {
        guard let userID = appState.currentUserID else { return }
        let context = viewContext
        let fr: NSFetchRequest<User> = User.fetchRequest()
        fr.predicate = NSPredicate(format: "userID == %@", userID as CVarArg)
        if let user = try? context.fetch(fr).first {
            ProgressLogHelper.addLog(for: crop, user: user, note: note.isEmpty ? nil : note, image: image, category: category, context: context)
        }
    }
}

