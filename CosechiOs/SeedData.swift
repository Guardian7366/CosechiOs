// SeedData.swift
import Foundation
import CoreData

struct SeedData {
    /// Inserta datos de ejemplo SOLO si no hay crops en Core Data.
    static func populateIfNeeded(context: NSManagedObjectContext) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Crop")
        request.fetchLimit = 1
        if let count = try? context.count(for: request), count > 0 {
            let all = try? context.fetch(NSFetchRequest<NSManagedObject>(entityName: "Crop"))
                all?.forEach { context.delete($0) }        }

        // Definición de seeds: datos base + info extendida
        let seeds: [(nameKey: String,
                     category: String,
                     difficulty: String,
                     descKey: String,
                     seasons: [String],
                     steps: [String],
                     stepDurations: [Int],
                     soil: String,
                     watering: String,
                     sunlight: String,
                     temperature: String,
                     fertilization: String,
                     climate: String,
                     plagues: String,
                     imageName: String,
                     companions: String?,
                     germinationDays: Int32,
                     wateringFrequency: String?,
                     harvestMonths: [String]?)] = [

            // TOMATE 🍅
            (
                nameKey: "crop_tomato_name",
                category: "Hortaliza",
                difficulty: "Fácil",
                descKey: "crop_tomato_desc",
                seasons: ["season_spring", "season_summer"],
                steps: ["step_germination", "step_transplant", "step_growth", "step_harvest"],
                stepDurations: [7, 14, 60, 14],
                soil: "Suelo franco, rico en materia orgánica",
                watering: "Riego frecuente, cada 2-3 días",
                sunlight: "Pleno sol (6-8 horas)",
                temperature: "18-28°C",
                fertilization: "Aportar compost cada 15 días",
                climate: "Clima templado, sensible a heladas",
                plagues: "Pulgones, mosca blanca, mildiu, araña roja, gusano del tomate",
                imageName: "tomato",
                companions: "✅ Albahaca, zanahoria, cebolla | ❌ Patatas, hinojo",
                germinationDays: 7,
                wateringFrequency: "Cada 2-3 días",
                harvestMonths: ["Julio", "Agosto", "Septiembre"]
            ),

            // LECHUGA 🥬
            (
                nameKey: "crop_lettuce_name",
                category: "Hortaliza",
                difficulty: "Muy fácil",
                descKey: "crop_lettuce_desc",
                seasons: ["season_spring", "season_autumn"],
                steps: ["step_sowing_direct", "step_thinning", "step_growth", "step_harvest"],
                stepDurations: [5, 7, 30, 7],
                soil: "Suelo ligero y fértil",
                watering: "Mantener humedad constante",
                sunlight: "Sol parcial o pleno sol",
                temperature: "10-20°C",
                fertilization: "Abonar ligeramente con nitrógeno",
                climate: "Prefiere clima fresco, tolera ligeras heladas",
                plagues: "Pulgones, babosas/limacos, trips",
                imageName: "lettuce",
                companions: "✅ Zanahorias, rábanos | ❌ Apio",
                germinationDays: 5,
                wateringFrequency: "Cada 1-2 días",
                harvestMonths: ["Abril", "Mayo", "Octubre"]
            ),

            // ALBAHACA 🌿
            (
                nameKey: "crop_basil_name",
                category: "Hierba",
                difficulty: "Fácil",
                descKey: "crop_basil_desc",
                seasons: ["season_summer"],
                steps: ["step_sowing", "step_growth", "step_harvest"],
                stepDurations: [7, 45, 7],
                soil: "Suelo bien drenado",
                watering: "Riego moderado, evitar encharcamiento",
                sunlight: "Pleno sol",
                temperature: "18-30°C",
                fertilization: "Aplicar fertilizante orgánico cada 20 días",
                climate: "Clima cálido, no tolera heladas",
                plagues: "Pulgones, mosca blanca, oídio (moho polvoriento)",
                imageName: "basil",
                companions: "✅ Tomate, pimientos | ❌ Pepino, ruda",
                germinationDays: 7,
                wateringFrequency: "Cada 2-3 días",
                harvestMonths: ["Junio", "Julio", "Agosto"]
            ),

            // FRESA 🍓
            (
                nameKey: "crop_strawberry_name",
                category: "Fruta",
                difficulty: "Media",
                descKey: "crop_strawberry_desc",
                seasons: ["season_spring", "season_summer"],
                steps: ["step_planting", "step_vegetative", "step_flowering", "step_harvest"],
                stepDurations: [14, 60, 30, 14],
                soil: "Suelo arenoso y fértil",
                watering: "Riego regular, mantener suelo húmedo",
                sunlight: "Pleno sol o semisombra ligera",
                temperature: "15-25°C",
                fertilization: "Aplicar potasio durante la floración",
                climate: "Clima templado, no soporta calor extremo",
                plagues: "Araña roja, babosas, botrytis (moho gris)",
                imageName: "strawberry",
                companions: "✅ Espinaca, lechuga | ❌ Coles",
                germinationDays: 14,
                wateringFrequency: "Cada 2-3 días",
                harvestMonths: ["Mayo", "Junio"]
            ),

            // PEPINO 🥒
            (
                nameKey: "crop_cucumber_name",
                category: "Hortaliza",
                difficulty: "Fácil",
                descKey: "crop_cucumber_desc",
                seasons: ["season_spring", "season_summer"],
                steps: ["step_sowing", "step_transplant", "step_growth", "step_harvest"],
                stepDurations: [10, 15, 50, 12],
                soil: "Suelo suelto y bien drenado",
                watering: "Riego constante, evitar sequías",
                sunlight: "Pleno sol",
                temperature: "18-30°C",
                fertilization: "Fertilización rica en potasio durante fructificación",
                climate: "Clima cálido, sensible al frío",
                plagues: "Pulgones, mosca blanca, ácaros, oídio, gusanos de cucurbitáceas",
                imageName: "cucumber",
                companions: "✅ Maíz, girasol | ❌ Patatas, hierbas aromáticas",
                germinationDays: 10,
                wateringFrequency: "Cada 2 días",
                harvestMonths: ["Julio", "Agosto"]
            ),

            // PIMIENTO 🌶
            (
                nameKey: "crop_pepper_name",
                category: "Hortaliza",
                difficulty: "Media",
                descKey: "crop_pepper_desc",
                seasons: ["season_spring", "season_summer"],
                steps: ["step_germination", "step_transplant", "step_growth", "step_harvest"],
                stepDurations: [14, 20, 80, 20],
                soil: "Suelo fértil con buen drenaje",
                watering: "Riego moderado, evitar encharcamientos",
                sunlight: "Pleno sol",
                temperature: "20-30°C",
                fertilization: "Aporte de nitrógeno y fósforo en crecimiento",
                climate: "Clima cálido, no tolera heladas",
                plagues: "Pulgones, ácaros, mosca blanca, nematodos",
                imageName: "pepper",
                companions: "✅ Albahaca, zanahoria | ❌ Judías",
                germinationDays: 14,
                wateringFrequency: "Cada 2-3 días",
                harvestMonths: ["Agosto", "Septiembre"]
            ),

            // ZANAHORIA 🥕
            (
                nameKey: "crop_carrot_name",
                category: "Hortaliza",
                difficulty: "Muy fácil",
                descKey: "crop_carrot_desc",
                seasons: ["season_spring", "season_autumn"],
                steps: ["step_sowing_direct", "step_thinning", "step_growth", "step_harvest"],
                stepDurations: [7, 14, 70, 15],
                soil: "Suelo profundo, suelto y arenoso",
                watering: "Mantener humedad ligera y constante",
                sunlight: "Pleno sol",
                temperature: "10-24°C",
                fertilization: "Evitar exceso de nitrógeno para no deformar raíces",
                climate: "Prefiere clima fresco, tolera heladas suaves",
                plagues: "Mosca de la zanahoria, pulgones, gusanos de raíz",
                imageName: "carrot",
                companions: "✅ Guisantes, lechugas | ❌ Eneldo",
                germinationDays: 7,
                wateringFrequency: "Cada 3 días",
                harvestMonths: ["Junio", "Julio", "Octubre"]
            ),

            // CEBOLLA 🧅
            (
                nameKey: "crop_onion_name",
                category: "Hortaliza",
                difficulty: "Media",
                descKey: "crop_onion_desc",
                seasons: ["season_winter", "season_spring"],
                steps: ["step_sowing", "step_transplant", "step_growth", "step_harvest"],
                stepDurations: [14, 20, 100, 20],
                soil: "Suelo ligero y bien aireado",
                watering: "Riego moderado, suspender antes de cosecha",
                sunlight: "Pleno sol",
                temperature: "12-25°C",
                fertilization: "Fósforo y potasio al inicio del crecimiento",
                climate: "Clima templado-frío, resistente a heladas leves",
                plagues: "Trips, mosca de la cebolla, mildiu",
                imageName: "onion",
                companions: "✅ Zanahorias, remolachas | ❌ Guisantes",
                germinationDays: 14,
                wateringFrequency: "Cada 3-4 días",
                harvestMonths: ["Julio", "Agosto"]
            ),

            // SANDÍA 🍉
            (
                nameKey: "crop_watermelon_name",
                category: "Fruta",
                difficulty: "Difícil",
                descKey: "crop_watermelon_desc",
                seasons: ["season_summer"],
                steps: ["step_sowing", "step_growth", "step_flowering", "step_fruit_set", "step_harvest"],
                stepDurations: [10, 40, 20, 30, 20],
                soil: "Suelo profundo, arenoso y rico en materia orgánica",
                watering: "Riego abundante en crecimiento, reducir antes de cosecha",
                sunlight: "Pleno sol (8h mínimo)",
                temperature: "22-32°C",
                fertilization: "Alto potasio en fructificación",
                climate: "Clima cálido-seco, no soporta heladas",
                plagues: "Pulgones, ácaros, gusanos del fruto, oídio",
                imageName: "watermelon",
                companions: "✅ Maíz, girasol | ❌ Patatas",
                germinationDays: 10,
                wateringFrequency: "Cada 2-3 días",
                harvestMonths: ["Agosto", "Septiembre"]
            ),

            // MAÍZ 🌽
            (
                nameKey: "crop_corn_name",
                category: "Hortaliza",
                difficulty: "Fácil",
                descKey: "crop_corn_desc",
                seasons: ["season_spring", "season_summer"],
                steps: ["step_sowing_direct", "step_growth", "step_pollination", "step_harvest"],
                stepDurations: [10, 45, 20, 30],
                soil: "Suelo fértil y profundo",
                watering: "Riego regular, especialmente en floración",
                sunlight: "Pleno sol",
                temperature: "18-30°C",
                fertilization: "Requiere nitrógeno abundante",
                climate: "Clima cálido-templado, sensible a heladas",
                plagues: "Taladro del maíz, gusano cogollero, pulgones",
                imageName: "corn",
                companions: "✅ Calabaza, pepino | ❌ Tomate",
                germinationDays: 10,
                wateringFrequency: "Cada 2-3 días",
                harvestMonths: ["Agosto", "Septiembre"]
            )
        ]

        for seed in seeds {
            let cropEntity = Crop(context: context)
            cropEntity.cropID = UUID()
            cropEntity.name = NSLocalizedString(seed.nameKey, comment: "")
            cropEntity.category = seed.category
            cropEntity.difficulty = seed.difficulty
            cropEntity.cropDescription = NSLocalizedString(seed.descKey, comment: "")
            cropEntity.recommendedSeasons = seed.seasons as NSArray
            cropEntity.createdAt = Date()
            cropEntity.updatedAt = Date()
            cropEntity.imageName = seed.imageName

            // Crear steps asociados
            for (index, stepKey) in seed.steps.enumerated() {
                let step = Step(context: context)
                step.stepID = UUID()
                step.title = NSLocalizedString(stepKey, comment: "")
                let stepTitleLocalized = NSLocalizedString(stepKey, comment: "")
                step.stepDescription = String(format: NSLocalizedString("step_description_template", comment: ""), stepTitleLocalized)
                step.estimateDuration = Int32(seed.stepDurations[index])
                step.order = Int16(index + 1)
                step.crop = cropEntity
            }

            // Crear info asociada
            if let cropInfoEntity = NSEntityDescription.entity(forEntityName: "CropInfo", in: context) {
                let info = NSManagedObject(entity: cropInfoEntity, insertInto: context)
                info.setValue(UUID(), forKey: "infoID")
                info.setValue(seed.soil, forKey: "soilType")
                info.setValue(seed.watering, forKey: "watering")
                info.setValue(seed.sunlight, forKey: "sunlight")
                info.setValue(seed.temperature, forKey: "temperatureRange")
                info.setValue(seed.fertilization, forKey: "fertilizationTips")
                info.setValue(seed.climate, forKey: "climate")
                info.setValue(seed.plagues, forKey: "plagues")
                info.setValue(seed.companions, forKey: "companions")
                info.setValue(seed.germinationDays, forKey: "germinationDays")
                info.setValue(seed.wateringFrequency, forKey: "wateringFrequency")
                info.setValue(seed.harvestMonths, forKey: "harvestMonths")
                // set relationships (KVC-safe)
                info.setValue(cropEntity, forKey: "crop")
                cropEntity.setValue(info, forKey: "info")
            }
        }

        do {
            try context.save()
            print("🌱 SeedData: datos de ejemplo insertados (cultivos + pasos + info).")
        } catch {
            print("❌ SeedData: error guardando seeds: \(error.localizedDescription)")
        }
    }
}
