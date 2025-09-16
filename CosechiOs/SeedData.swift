// SeedData.swift
import Foundation
import CoreData

struct SeedData {
    /// Inserta datos de ejemplo SOLO si no hay crops en Core Data.
    static func populateIfNeeded(context: NSManagedObjectContext) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Crop")
        request.fetchLimit = 1
        if let count = try? context.count(for: request), count > 0 {
            return // Ya hay cultivos, no hacer nada
        }

        // Definición de seeds: usar claves para texto localizable y keys para seasons
        // Mantener category en los valores que ya usabas ("Hortaliza", "Hierba", "Fruta")
        let seeds: [(nameKey: String, category: String, difficulty: String, descKey: String, seasons: [String], steps: [String], stepDurations: [Int])] = [
            (
                nameKey: "crop_tomato_name",
                category: "Hortaliza",
                difficulty: "Fácil",
                descKey: "crop_tomato_desc",
                seasons: ["season_spring", "season_summer"],
                steps: ["step_germination", "step_transplant", "step_growth", "step_harvest"],
                stepDurations: [7, 14, 60, 14]
            ),
            (
                nameKey: "crop_lettuce_name",
                category: "Hortaliza",
                difficulty: "Muy fácil",
                descKey: "crop_lettuce_desc",
                seasons: ["season_spring", "season_autumn"],
                steps: ["step_sowing_direct", "step_thinning", "step_growth", "step_harvest"],
                stepDurations: [5, 7, 30, 7]
            ),
            (
                nameKey: "crop_basil_name",
                category: "Hierba",
                difficulty: "Fácil",
                descKey: "crop_basil_desc",
                seasons: ["season_summer"],
                steps: ["step_sowing", "step_growth", "step_harvest"],
                stepDurations: [7, 45, 7]
            ),
            (
                nameKey: "crop_strawberry_name",
                category: "Fruta",
                difficulty: "Media",
                descKey: "crop_strawberry_desc",
                seasons: ["season_spring", "season_summer"],
                steps: ["step_planting", "step_vegetative", "step_flowering", "step_harvest"],
                stepDurations: [14, 60, 30, 14]
            )
        ]

        for seed in seeds {
            let cropEntity = Crop(context: context)
            cropEntity.cropID = UUID()
            cropEntity.name = NSLocalizedString(seed.nameKey, comment: "")
            cropEntity.category = seed.category // mantener compatibilidad con filtros previos
            cropEntity.difficulty = seed.difficulty
            cropEntity.cropDescription = NSLocalizedString(seed.descKey, comment: "")
            // Guardamos las keys de temporada — en la UI las traducimos con NSLocalizedString
            cropEntity.recommendedSeasons = seed.seasons as NSArray
            cropEntity.createdAt = Date()
            cropEntity.updatedAt = Date()

            // Crear steps asociados (título / descripción / duración / orden)
            for (index, stepKey) in seed.steps.enumerated() {
                let step = Step(context: context)
                step.stepID = UUID()
                // El título del paso lo guardamos ya traducido (para evitar lógica extra al mostrar)
                step.title = NSLocalizedString(stepKey, comment: "")
                // Para la descripción usamos una plantilla localizable con placeholder %@:
                let stepTitleLocalized = NSLocalizedString(stepKey, comment: "")
                step.stepDescription = String(format: NSLocalizedString("step_description_template", comment: ""), stepTitleLocalized)
                step.estimateDuration = Int32(seed.stepDurations[index])
                step.order = Int16(index + 1)
                step.crop = cropEntity
            }
        }

        do {
            try context.save()
            print("🌱 SeedData: datos de ejemplo insertados (cultivos + pasos).")
        } catch {
            print("❌ SeedData: error guardando seeds: \(error.localizedDescription)")
        }
    }
}
