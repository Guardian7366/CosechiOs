import SwiftUI
import CoreData

struct RecommendedCropsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @State private var recommendations: [CropRecommendation] = []
    @State private var isLoading = false
    @State private var showMessage: String? = nil

    var body: some View {
        VStack {
            HeaderView()

            if isLoading {
                ProgressView()
                    .padding()
            } else if recommendations.isEmpty {
                Text("recommendations_no_results")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(recommendations) { rec in
                        RecommendationRow(rec: rec, onAdd: { addCrop(rec.crop) })
                    }
                }
                .listStyle(.insetGrouped)
            }
            Spacer()
        }
        .navigationTitle(LocalizedStringKey("recommendations_title"))
        .onAppear(perform: loadRecommendations)
        .alert(item: $showMessage) { msg in
            Alert(
                title: Text(msg),
                dismissButton: .default(Text(LocalizedStringKey("ok")))
            )
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func HeaderView() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey("recommendations_title"))
                .font(.title2).bold()
            Text(LocalizedStringKey("recommendations_subtitle"))
                .font(.caption).foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func RecommendationRow(rec: CropRecommendation, onAdd: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail if available
            if let data = rec.crop.imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipped()
                    .cornerRadius(8)
            } else {
                ZStack {
                    Color(.systemGray5)
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.white)
                }
                .frame(width: 64, height: 64)
                .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(rec.crop.name ?? NSLocalizedString("crop_default", comment: ""))
                        .font(.headline)
                    Spacer()
                    Text(String(format: "%.0f", rec.score))
                        .font(.caption2)
                        .padding(6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }

                if let cat = rec.crop.category, !cat.isEmpty {
                    Text(cat)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Reasons
                ForEach(rec.reasons.prefix(3), id: \.self) { reason in
                    Text(reason)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Add button (si ya está en colección RecommendationHelper no la añadirá)
            Button(action: onAdd) {
                Text(LocalizedStringKey("recommendations_add"))
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func loadRecommendations() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let recs = RecommendationHelper.recommendCrops(
                context: viewContext,
                forUserID: appState.currentUserID,
                maxResults: 12
            )
            DispatchQueue.main.async {
                self.recommendations = recs
                self.isLoading = false
            }
        }
    }

    private func addCrop(_ crop: Crop) {
        guard let uid = appState.currentUserID else {
            self.showMessage = NSLocalizedString("recommendations_error_not_logged", comment: "")
            return
        }

        do {
            let added = try RecommendationHelper.addCropToUserCollection(
                crop: crop,
                userID: uid,
                context: viewContext
            )
            if added {
                self.showMessage = NSLocalizedString("recommendations_added", comment: "")
            } else {
                self.showMessage = NSLocalizedString("recommendations_in_collection", comment: "")
            }
            // recargar recomendaciones (ahora que collection cambió)
            loadRecommendations()
        } catch {
            self.showMessage = error.localizedDescription
        }
    }
}

// Make String optional binding for alert
extension String: Identifiable {
    public var id: String { self }
}
