// ExploreCropsView.swift
import SwiftUI
import CoreData
import UIKit // usado para UIScreen.main.bounds.width (cálculo de ancho disponible)

struct ExploreCropsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var theme: AeroTheme

    @State private var searchText = ""
    @State private var selectedCategoryKey: String? = nil

    @FetchRequest(
        entity: Crop.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Crop.name, ascending: true)],
        animation: .default
    ) private var crops: FetchedResults<Crop>

    // Espaciado configurable
    private let horizontalPadding: CGFloat = 16
    private let interItemSpacing: CGFloat = 16
    private let columnsCount: Int = 2

    var body: some View {
        FrutigerAeroBackground {
            VStack(spacing: 16) {
                // 📌 Filtros
                GlassCard {
                    FilterMenuView(selectedCategoryKey: $selectedCategoryKey)
                        .environmentObject(theme)
                }
                .padding(.horizontal)
                .frame(maxWidth: 220, maxHeight: 50)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(LocalizationHelper.shared.localized("filter_category")))
                .accessibilityValue(
                    Text(selectedCategoryKey != nil
                         ? LocalizationHelper.shared.localized(selectedCategoryKey!)
                         : LocalizationHelper.shared.localized("filter_all"))
                )

                // 📌 Catálogo de cultivos
                ScrollView {
                    let screenW = UIScreen.main.bounds.width
                    let totalHorizontalPadding = horizontalPadding * 2
                    let totalGaps = CGFloat(columnsCount - 1) * interItemSpacing
                    let availableWidth = max(0, screenW - totalHorizontalPadding - totalGaps)
                    let itemWidth = floor(availableWidth / CGFloat(columnsCount))

                    let gridColumns: [GridItem] = Array(repeating: GridItem(.fixed(itemWidth), spacing: interItemSpacing), count: columnsCount)

                    LazyVGrid(columns: gridColumns, spacing: interItemSpacing) {
                        ForEach(filteredCrops, id: \.objectID) { crop in
                            NavigationLink(destination: CropDetailView(crop: crop)
                                            .environment(\.managedObjectContext, viewContext)
                            ) {
                                CropCardView(crop: crop)
                                    .environmentObject(theme)
                                    .frame(width: itemWidth)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 6)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(LocalizationHelper.shared.localized("menu_explore"))
                        .aeroTextPrimary(theme)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.35))
                        .cornerRadius(6)
                        .shadow(color: .black.opacity(0.7), radius: 3, x: 0, y: 1)
                        .font(.headline)
                        .accessibilityHidden(true)
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
    @EnvironmentObject var theme: AeroTheme

    var body: some View {
        HStack {
            Menu {
                Button { selectedCategoryKey = nil } label: {
                    Text(LocalizationHelper.shared.localized("filter_all"))
                        .aeroTextPrimary(theme)
                }
                .accessibilityLabel(Text(LocalizationHelper.shared.localized("filter_all")))

                Button { selectedCategoryKey = "category_vegetable" } label: {
                    Text(LocalizationHelper.shared.localized("filter_vegetable"))
                        .aeroTextPrimary(theme)
                }
                .accessibilityLabel(Text(LocalizationHelper.shared.localized("filter_vegetable")))

                Button { selectedCategoryKey = "category_herb" } label: {
                    Text(LocalizationHelper.shared.localized("filter_herb"))
                        .aeroTextPrimary(theme)
                }
                .accessibilityLabel(Text(LocalizationHelper.shared.localized("filter_herb")))

                Button { selectedCategoryKey = "category_fruit" } label: {
                    Text(LocalizationHelper.shared.localized("filter_fruit"))
                        .aeroTextPrimary(theme)
                }
                .accessibilityLabel(Text(LocalizationHelper.shared.localized("filter_fruit")))
            } label: {
                Label {
                    if let key = selectedCategoryKey {
                        Text(LocalizationHelper.shared.localized(key))
                            .aeroTextPrimary(theme)
                    } else {
                        Text(LocalizationHelper.shared.localized("filter_category"))
                            .aeroTextPrimary(theme)
                    }
                } icon: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.35))
                .cornerRadius(6)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            .accessibilityLabel(Text(LocalizationHelper.shared.localized("filter_category")))
            .accessibilityHint(Text(LocalizationHelper.shared.localized("filter_change_category")))
            Spacer()
        }
    }
}

// MARK: - Tarjeta de cultivo
private struct CropCardView: View {
    let crop: Crop
    @EnvironmentObject var theme: AeroTheme

    var body: some View {
        GlassCard {
            VStack(spacing: 8) {
                if let imgName = crop.imageName, !imgName.isEmpty, UIImage(named: imgName) != nil {
                    Image(imgName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 60)
                        .clipped()
                        .cornerRadius(10)
                        .accessibilityHidden(true)
                } else {
                    ZStack {
                        Color.blue.opacity(0.25)
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                    }
                    .frame(height: 110)
                    .cornerRadius(10)
                    .accessibilityLabel(Text(LocalizationHelper.shared.localized("crop_image_placeholder")))
                }

                Text(LocalizationHelper.shared.localized(crop.name ?? "crop_no_name"))
                    .font(.headline)
                    .aeroTextPrimary(theme)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.4))
                    .cornerRadius(4)
                    .lineLimit(1)
                    .accessibilityHidden(true)

                if let category = crop.category {
                    Text(LocalizationHelper.shared.localized(category))
                        .font(.caption)
                        .aeroTextSecondary(theme)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.green.opacity(0.35))
                        .cornerRadius(3)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 110, alignment: .topLeading)
            .padding(8)
        }
    }
}
