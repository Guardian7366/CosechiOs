// MyCropsView.swift
import SwiftUI
import CoreData

struct MyCropsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) private var viewContext

    @State private var userCollections: [UserCollection] = []
    @State private var observer: NSObjectProtocol?
    private let notificationCenter = NotificationCenter.default

    var body: some View {
        ZStack {
            // 🌿 Fondo Frutiger Aero estilo jardín
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.6),
                    Color.blue.opacity(0.4),
                    Color.green.opacity(0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .overlay(
                // Pequeñas luces difusas
                Circle()
                    .fill(Color.green.opacity(0.25))
                    .blur(radius: 120)
                    .offset(x: -150, y: -200)
            )
            .overlay(
                Circle()
                    .fill(Color.teal.opacity(0.2))
                    .blur(radius: 100)
                    .offset(x: 180, y: 250)
            )

            VStack {
                if userCollections.isEmpty {
                    // Mensaje vacío estilizado
                    VStack(spacing: 12) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green, .white)
                            .shadow(color: .green.opacity(0.5), radius: 6, x: 0, y: 4)

                        Text(LocalizationHelper.shared.localized("mycrops_empty"))
                            .foregroundColor(.secondary)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(userCollections, id: \.self) { uc in
                                if let crop = uc.crop {
                                    NavigationLink(destination: CropDetailView(crop: crop)) {
                                        HStack(spacing: 16) {
                                            // 🌱 Icono dinámico (imagen del cultivo si existe)
                                            Image(crop.imageName ?? "leaf.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(
                                                    LocalizationHelper.shared.localized(
                                                        crop.name ?? "crop_default"
                                                    )
                                                )
                                                .font(.headline)
                                                .foregroundColor(.white)

                                                if let categoryKey = crop.category {
                                                    Text(LocalizationHelper.shared.localized(categoryKey))
                                                        .font(.subheadline)
                                                        .foregroundColor(.white.opacity(0.8))
                                                }
                                            }

                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                        .padding()
                                        .background(
                                            // Glassmorphism card
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.white.opacity(0.15))
                                                .background(
                                                    Color.white.opacity(0.05)
                                                        .blur(radius: 6)
                                                )
                                                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                                        )
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle(
            Text(LocalizationHelper.shared.localized("menu_my_crops"))
                .foregroundColor(.white)
        )
        .onAppear {
            loadUserCollections()
            // guardar el token del observer para removerlo después
            observer = notificationCenter.addObserver(forName: .userCollectionsChanged, object: nil, queue: .main) { _ in
                loadUserCollections()
            }
        }
        .onDisappear {
            if let obs = observer {
                notificationCenter.removeObserver(obs)
                observer = nil
            }
        }
    }

    private func loadUserCollections() {
        guard let userID = appState.currentUserID else {
            DispatchQueue.main.async { self.userCollections = [] }
            return
        }

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
                guard index < userCollections.count else { continue }
                let collection = userCollections[index]
                viewContext.delete(collection)
            }
            do {
                try viewContext.save()
            } catch {
                print("❌ Error saving after delete: \(error)")
                viewContext.rollback()
            }
            DispatchQueue.main.async {
                loadUserCollections()
                NotificationCenter.default.post(name: .userCollectionsChanged, object: nil)
            }
        }
    }
}
