import SwiftUI
import CoreData

struct ExploreCropsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil

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
                    Button("filter_all") { selectedCategory = nil }
                    Button("filter_vegetable") { selectedCategory = "Hortaliza" }
                    Button("filter_herb") { selectedCategory = "Hierba" }
                    Button("filter_fruit") { selectedCategory = "Fruta" }
                } label: {
                    Label(selectedCategory ?? NSLocalizedString("filter_category", comment: ""), systemImage: "line.3.horizontal.decrease.circle")
                }
                Spacer()
            }
            .padding(.horizontal)

            List {
                ForEach(filteredCrops, id: \.self) { crop in
                    NavigationLink(destination: CropDetailView(crop: crop)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(crop.name ?? NSLocalizedString("crop_no_name", comment: ""))
                                .font(.headline)
                            Text(crop.category ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("menu_explore")
        .searchable(text: $searchText, prompt: Text("search_crops"))
    }

    private var filteredCrops: [Crop] {
        crops.filter { crop in
            let matchCategory = selectedCategory == nil || crop.category == selectedCategory
            let matchSearch = searchText.isEmpty || (crop.name?.localizedCaseInsensitiveContains(searchText) ?? false)
            return matchCategory && matchSearch
        }
    }
}
