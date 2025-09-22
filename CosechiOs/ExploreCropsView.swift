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

    var body: some View {
        VStack {
            // Filtros
            HStack {
                Menu {
                    Button { selectedCategoryKey = nil } label: {
                        Text(LocalizationHelper.shared.localized("filter_all"))
                    }
                    Button { selectedCategoryKey = "category_vegetable" } label: {
                        Text(LocalizationHelper.shared.localized("filter_vegetable"))
                    }
                    Button { selectedCategoryKey = "category_herb" } label: {
                        Text(LocalizationHelper.shared.localized("filter_herb"))
                    }
                    Button { selectedCategoryKey = "category_fruit" } label: {
                        Text(LocalizationHelper.shared.localized("filter_fruit"))
                    }
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
                }
                Spacer()
            }
            .padding(.horizontal)

            List {
                ForEach(filteredCrops, id: \.self) { crop in
                    NavigationLink(destination: CropDetailView(crop: crop)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizationHelper.shared.localized(crop.name ?? "crop_no_name"))
                                .font(.headline)
                            Text(LocalizationHelper.shared.localized(crop.category ?? ""))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle(Text(LocalizationHelper.shared.localized("menu_explore")))
        .searchable(text: $searchText, prompt: Text(LocalizationHelper.shared.localized("search_crops")))
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
