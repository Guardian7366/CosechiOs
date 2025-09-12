import Foundation
import CoreData

struct SeedData {
    static func populateIfNeeded(context: NSManagedObjectContext) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Crop")
        request.fetchLimit = 1
        if let count = try? context.count(for: request), count > 0 {
            return // Ya hay cultivos, no hacer nada
        }

        // Datos de cultivos y sus pasos
        let crops: [(name: String, category: String, difficulty: String, description: String, seasons: [String], steps: [String])] = [
            (
                name: "Tomate",
                category: "Hortaliza",
                difficulty: "Fácil",
                description: "Planta de fruto rojo muy popular en huertos urbanos.",
                seasons: ["Primavera", "Verano"],
                steps: ["Germinación", "Trasplante", "Crecimiento", "Cosecha"]
            ),
            (
                name: "Lechuga",
                category: "Hortaliza",
                difficulty: "Muy fácil",
                description: "Ideal para principiantes, crece rápido y ocupa poco espacio.",
                seasons: ["Primavera", "Otoño"],
                steps: ["Siembra directa", "Raleo", "Crecimiento", "Cosecha"]
            ),
            (
                name: "Albahaca",
                category: "Hierba",
                difficulty: "Fácil",
                description: "Hierba aromática perfecta para macetas y balcones.",
                seasons: ["Verano"],
                steps: ["Siembra", "Crecimiento", "Cosecha de hojas"]
            ),
            (
                name: "Fresa",
                category: "Fruta",
                difficulty: "Media",
                description: "Produce frutos dulces, requiere sol y cuidados regulares.",
                seasons: ["Primavera", "Verano"],
                steps: ["Siembra o plantación", "Crecimiento vegetativo", "Floración", "Cosecha"]
            )
        ]

        for crop in crops {
            // Crear Crop
            let cropEntity = Crop(context: context)
            cropEntity.cropID = UUID()
            cropEntity.name = crop.name
            cropEntity.category = crop.category
            cropEntity.difficulty = crop.difficulty
            cropEntity.cropDescription = crop.description
            cropEntity.recommendedSeasons = crop.seasons as NSArray
            cropEntity.createdAt = Date()
            cropEntity.updatedAt = Date()

            // Crear Steps asociados
            for (index, stepTitle) in crop.steps.enumerated() {
                let step = Step(context: context)
                step.stepID = UUID()
                step.title = stepTitle
                step.stepDescription = "Descripción del paso: \(stepTitle)"
                step.estimateDuration = 0
                step.order = Int16(index + 1)
                step.crop = cropEntity
            }
        }

        do {
            try context.save()
            print("🌱 Datos de ejemplo insertados en Core Data con pasos incluidos")
        } catch {
            print("❌ Error al insertar datos iniciales: \(error.localizedDescription)")
        }
    }
}
