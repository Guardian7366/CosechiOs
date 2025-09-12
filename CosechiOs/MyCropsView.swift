import SwiftUI
import CoreData

struct MyCropsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) private var viewContext

    @State private var userCollections: [UserCollection] = []

    var body: some View {
        VStack {
            if userCollections.isEmpty {
                Text("No tienes cultivos en tu colección.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(userCollections, id: \.self) { uc in
                        if let crop = uc.crop {
                            NavigationLink(destination: CropDetailView(crop: crop)) {
                                VStack(alignment: .leading) {
                                    Text(crop.name ?? "Cultivo")
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
        .navigationTitle("Mis Cultivos")
        .onAppear {
            loadUserCollections()
        }
    }

    private func loadUserCollections() {
        guard let userID = appState.currentUserID else { return }
        let fr: NSFetchRequest<UserCollection> = UserCollection.fetchRequest()
        fr.predicate = NSPredicate(format: "user.userID == %@", userID as CVarArg)
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \UserCollection.addedAt, ascending: false)]
        userCollections = (try? viewContext.fetch(fr)) ?? []
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = userCollections[index]
            viewContext.delete(item)
        }
        try? viewContext.save()
        loadUserCollections()
    }
}

