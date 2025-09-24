// ExploreCropsView.swift
import SwiftUI
import CoreData

struct ExploreCropsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var selectedCategoryKey: String? = nil

    @FetchRequest(
        entity: Crop.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Crop.name, ascending: true)],
        animation: .default
    ) private var crops: FetchedResults<Crop>

    private let gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        FrutigerAeroBackground {
            VStack(spacing: 16) {
                // 📌 Filtros
                GlassCard {
                    FilterMenuView(selectedCategoryKey: $selectedCategoryKey)
                }
                .padding(.horizontal)
                .frame(maxWidth: 220, maxHeight: 50) // 🔹 más pequeño y rectangular
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(LocalizationHelper.shared.localized("filter_category")))
                .accessibilityValue(
                    Text(selectedCategoryKey != nil
                         ? LocalizationHelper.shared.localized(selectedCategoryKey!)
                         : LocalizationHelper.shared.localized("filter_all"))
                )

                // 📌 Catálogo de cultivos
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 20) {
                        ForEach(filteredCrops, id: \.self) { crop in
                            NavigationLink(destination: CropDetailView(crop: crop)) {
                                CropCardView(crop: crop)
                                    .padding(.horizontal, 4)
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel(Text(LocalizationHelper.shared.localized(crop.name ?? "crop_no_name")))
                                    .accessibilityValue(Text(LocalizationHelper.shared.localized(crop.category ?? "filter_all")))
                                    .accessibilityHint(Text(LocalizationHelper.shared.localized("crop_open_detail")))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle(LocalizationHelper.shared.localized("menu_explore")) // ✅ solo texto
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(LocalizationHelper.shared.localized("menu_explore"))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.35)) // 🔹 contraste extra
                        .cornerRadius(6)
                        .shadow(color: .black.opacity(0.7), radius: 3, x: 0, y: 1)
                        .font(.headline)
                        .accessibilityHidden(true) // 👈 ya está como título accesible
                }
            }
            .searchable(
                text: $searchText,
                prompt: Text(LocalizationHelper.shared.localized("search_crops"))
            )
            .accessibilityLabel(Text(LocalizationHelper.shared.localized("search_crops")))
            .accessibilityHint(Text(LocalizationHelper.shared.localized("search_crops_hint")))
        }
    }

    private var filteredCrops: [Crop] {
        crops.filter { crop in
            let matchCategory = selectedCategoryKey == nil || (crop.category == selectedCategoryKey)
            let displayName = LocalizationHelper.shared.localized(crop.name ?? "")
            let matchSearch = searchText.isEmpty || displayName.localizedCaseInsensitiveContains(searchText)
            return matchCategory && matchSearch
        }
    }
}

// MARK: - Filtro de categorías
private struct FilterMenuView: View {
    @Binding var selectedCategoryKey: String?

    var body: some View {
        HStack {
            Menu {
                Button { selectedCategoryKey = nil } label: {
                    Text(LocalizationHelper.shared.localized("filter_all"))
                }
                .accessibilityLabel(Text(LocalizationHelper.shared.localized("filter_all")))

                Button { selectedCategoryKey = "category_vegetable" } label: {
                    Text(LocalizationHelper.shared.localized("filter_vegetable"))
                }
                .accessibilityLabel(Text(LocalizationHelper.shared.localized("filter_vegetable")))

                Button { selectedCategoryKey = "category_herb" } label: {
                    Text(LocalizationHelper.shared.localized("filter_herb"))
                }
                .accessibilityLabel(Text(LocalizationHelper.shared.localized("filter_herb")))

                Button { selectedCategoryKey = "category_fruit" } label: {
                    Text(LocalizationHelper.shared.localized("filter_fruit"))
                }
                .accessibilityLabel(Text(LocalizationHelper.shared.localized("filter_fruit")))
            } label: {
                Label {
                    if let key = selectedCategoryKey {
                        Text(LocalizationHelper.shared.localized(key))
                    } else {
                        Text(LocalizationHelper.shared.localized("filter_category"))
                    }
                } icon: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.35)) // 🔹 mejor visibilidad
                .cornerRadius(6)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            .accessibilityLabel(Text(LocalizationHelper.shared.localized("filter_category")))
            .accessibilityHint(Text(LocalizationHelper.shared.localized("filter_change_category")))
            Spacer()
        }
    }
}

// MARK: - Tarjeta de cada cultivo
private struct CropCardView: View {
    let crop: Crop

    var body: some View {
        GlassCard {
            VStack(spacing: 8) {
                // Imagen o ícono por defecto
                if let imgName = crop.imageName, !imgName.isEmpty, UIImage(named: imgName) != nil {
                    Image(imgName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 100)
                        .clipped()
                        .cornerRadius(10)
                        .accessibilityHidden(true) // 👈 evitamos leer doble
                } else {
                    ZStack {
                        Color.blue.opacity(0.25)
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                    }
                    .frame(height: 100)
                    .cornerRadius(10)
                    .accessibilityLabel(Text(LocalizationHelper.shared.localized("crop_image_placeholder")))
                }

                // Nombre
                Text(LocalizationHelper.shared.localized(crop.name ?? "crop_no_name"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.4))
                    .cornerRadius(4)
                    .lineLimit(1)
                    .accessibilityHidden(true) // 👈 lo maneja la tarjeta completa

                // Categoría
                if let category = crop.category {
                    Text(LocalizationHelper.shared.localized(category))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.95))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.green.opacity(0.35))
                        .cornerRadius(3)
                        .accessibilityHidden(true)
                }
            }
            .padding(8)
            .padding(.vertical, 4)
        }
    }
}
