// RecommendedCropsView.swift
import SwiftUI
import CoreData

struct RecommendedCropsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @State private var recommendations: [CropRecommendation] = []
    @State private var isLoading = false
    @State private var showMessage: String? = nil

    var body: some View {
        FrutigerAeroBackground {
            ScrollView {
                VStack(spacing: 16) {
                    // ✅ Encabezado bonito
                    AeroHeader(
                        LocalizationHelper.shared.localized("recommendations_title"),
                        subtitle: LocalizationHelper.shared.localized("recommendations_subtitle")
                    )

                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if recommendations.isEmpty {
                        Text(LocalizationHelper.shared.localized("recommendations_no_results"))
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        // ✅ Cards en stack vertical
                        LazyVStack(spacing: 14) {
                            ForEach(recommendations) { rec in
                                RecommendationCard(rec: rec) {
                                    addCrop(rec.crop)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 8)
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
            loadRecommendations() // recargar después de agregar
        } catch {
            self.showMessage = error.localizedDescription
        }
    }
}

// MARK: - Recommendation Card (Frutiger Aero estilo)
private struct RecommendationCard: View {
    let rec: CropRecommendation
    let onAdd: () -> Void

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                // Imagen
                if let data = rec.crop.imageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipped()
                        .cornerRadius(10)
                } else if let imgName = rec.crop.imageName, !imgName.isEmpty, UIImage(named: imgName) != nil {
                    Image(imgName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipped()
                        .cornerRadius(10)
                } else {
                    ZStack {
                        Color.green.opacity(0.25)
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    .frame(width: 72, height: 72)
                    .cornerRadius(10)
                }

                // Texto descriptivo
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(LocalizationHelper.shared.localized(rec.crop.name ?? "crop_default"))
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                        Spacer()
                        Text(String(format: "%.0f", rec.score))
                            .font(.caption2)
                            .padding(6)
                            .background(Color.white.opacity(0.18))
                            .cornerRadius(8)
                    }

                    if let cat = rec.crop.category, !cat.isEmpty {
                        Text(LocalizationHelper.shared.localized(cat))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    ForEach(rec.reasons.prefix(3), id: \.self) { reason in
                        Text(LocalizationHelper.shared.localized(reason))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Botón agregar
                Button(action: onAdd) {
                    Text(LocalizedStringKey("recommendations_add"))
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - Alert string helper
extension String: Identifiable {
    public var id: String { self }
}
