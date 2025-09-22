import SwiftUI
import CoreData

struct MyCropsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var userCollections: [UserCollection] = []
    private var notificationCenter = NotificationCenter.default

    var body: some View {
        VStack {
            if userCollections.isEmpty {
                Text("mycrops_empty")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(userCollections, id: \.self) { uc in
                        if let crop = uc.crop {
                            NavigationLink(destination: CropDetailView(crop: crop)) {
                                VStack(alignment: .leading) {
                                    Text(crop.name ?? NSLocalizedString("crop_default", comment: "Crop"))
                                        .font(.headline)
                                    Text(crop.category ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("menu_my_crops")
        .onAppear {
            loadUserCollections()
            notificationCenter.addObserver(forName: .userCollectionsChanged, object: nil, queue: .main) { _ in
                loadUserCollections()
            }
        }
        .onDisappear {
            notificationCenter.removeObserver(self, name: .userCollectionsChanged, object: nil)
        }
    }

    private func loadUserCollections() {
        guard let userID = appState.currentUserID else { return }
        viewContext.perform {
            let fr: NSFetchRequest<UserCollection> = UserCollection.fetchRequest()
            fr.predicate = NSPredicate(format: "user.userID == %@", userID as CVarArg)
            fr.sortDescriptors = [NSSortDescriptor(keyPath: \UserCollection.addedAt, ascending: false)]
            let results = (try? viewContext.fetch(fr)) ?? []
            DispatchQueue.main.async {
                self.userCollections = results
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        viewContext.perform {
            for index in offsets {
                let collection = userCollections[index]
                viewContext.delete(collection)
            }
            do {
                try viewContext.save()
            } catch {
                print("❌ Error saving after delete: \(error)")
            }
            DispatchQueue.main.async {
                loadUserCollections()
                NotificationCenter.default.post(name: .userCollectionsChanged, object: nil)
            }
        }
    }
}
