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
                    Button("Todas") { selectedCategory = nil }
                    Button("Hortaliza") { selectedCategory = "Hortaliza" }
                    Button("Hierba") { selectedCategory = "Hierba" }
                    Button("Fruta") { selectedCategory = "Fruta" }
                } label: {
                    Label(selectedCategory ?? "Categoría", systemImage: "line.3.horizontal.decrease.circle")
                }
                Spacer()
            }
            .padding(.horizontal)

            List {
                ForEach(filteredCrops, id: \.self) { crop in
                    NavigationLink(destination: CropDetailView(crop: crop)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(crop.name ?? "Sin nombre")
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
        .navigationTitle("Explorar Cultivos")
        .searchable(text: $searchText, prompt: "Buscar cultivos")
    }

    // Filtro combinado (búsqueda + categoría)
    private var filteredCrops: [Crop] {
        crops.filter { crop in
            let matchCategory = selectedCategory == nil || crop.category == selectedCategory
            let matchSearch = searchText.isEmpty || (crop.name?.localizedCaseInsensitiveContains(searchText) ?? false)
            return matchCategory && matchSearch
        }
    }
}
