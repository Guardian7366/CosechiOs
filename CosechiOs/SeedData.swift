// SeedData.swift
// Inserta seeds guardando KEYS (no textos localizados).
// Versión NO destructiva: sólo inserta si no hay crops en Core Data.

import Foundation
import CoreData

struct SeedData {
    static func populateIfNeeded(context: NSManagedObjectContext) {
        // Verificar si ya existen crops
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Crop")
        request.fetchLimit = 1
        do {
            let count = try context.count(for: request)
            if count > 0 {
                print("SeedData: ya existen crops (\(count)), no se insertan seeds.")
                return
            }
        } catch {
            print("SeedData: error comprobando crops existentes: \(error.localizedDescription)")
        }

        // Definición de semillas con KEYS (todas deben existir en Localizable.strings)
        let seeds: [(nameKey: String,
                     categoryKey: String,
                     difficultyKey: String,
                     descKey: String,
                     seasons: [String],
                     steps: [String],
                     stepDescriptions: [String],
                     stepDurations: [Int],
                     soilKey: String,
                     wateringKey: String,
                     sunlightKey: String,
                     temperatureKey: String,
                     fertilizationKey: String,
                     climateKey: String,
                     plaguesKey: String,
                     imageName: String,
                     companionsKey: String?,
                     germinationDays: Int32,
                     wateringFrequencyKey: String?,
                     harvestMonthsKeys: [String]?)] = [

            // TOMATE
            (
                nameKey: "crop_tomato_name",
                categoryKey: "category_vegetable",
                difficultyKey: "crop_difficulty_easy",
                descKey: "crop_tomato_desc",
                seasons: ["season_spring", "season_summer"],
                steps: ["step_germination", "step_transplant", "step_growth", "step_harvest"],
                stepDescriptions: ["step_germination_desc", "step_transplant_desc", "step_growth_desc", "step_harvest_desc"],
                stepDurations: [7, 14, 60, 14],
                soilKey: "soil_franco_organic",
                wateringKey: "watering_every_2_3_days",
                sunlightKey: "sun_full_sun",
                temperatureKey: "temp_18_28",
                fertilizationKey: "fert_compost_every_15_days",
                climateKey: "climate_temperate_sensitive_frost",
                plaguesKey: "plagues_tomato_common",
                imageName: "tomato",
                companionsKey: "companions_tomato",
                germinationDays: 7,
                wateringFrequencyKey: "watering_freq_every_2_3_days",
                harvestMonthsKeys: ["month_july", "month_august", "month_september"]
            ),

            // LECHUGA
            (
                nameKey: "crop_lettuce_name",
                categoryKey: "category_vegetable",
                difficultyKey: "crop_difficulty_very_easy",
                descKey: "crop_lettuce_desc",
                seasons: ["season_spring", "season_autumn"],
                steps: ["step_sowing_direct", "step_thinning", "step_growth", "step_harvest"],
                stepDescriptions: ["step_sowing_direct_desc", "step_thinning_desc", "step_growth_desc", "step_harvest_desc"],
                stepDurations: [5, 7, 30, 7],
                soilKey: "soil_light_fertile",
                wateringKey: "watering_keep_moist",
                sunlightKey: "sun_partial_or_full",
                temperatureKey: "temp_10_20",
                fertilizationKey: "fert_nitrogen_light",
                climateKey: "climate_cool_tolerates_frost",
                plaguesKey: "plagues_lettuce_common",
                imageName: "lettuce",
                companionsKey: "companions_lettuce",
                germinationDays: 5,
                wateringFrequencyKey: "watering_freq_every_1_2_days",
                harvestMonthsKeys: ["month_april", "month_may", "month_october"]
            ),

            // ALBAHACA
            (
                nameKey: "crop_basil_name",
                categoryKey: "category_herb",
                difficultyKey: "crop_difficulty_easy",
                descKey: "crop_basil_desc",
                seasons: ["season_summer"],
                steps: ["step_sowing", "step_growth", "step_harvest"],
                stepDescriptions: ["step_sowing_desc", "step_growth_desc", "step_harvest_desc"],
                stepDurations: [7, 45, 7],
                soilKey: "soil_well_drained",
                wateringKey: "watering_moderate_avoid_waterlogging",
                sunlightKey: "sun_full_sun",
                temperatureKey: "temp_18_30",
                fertilizationKey: "fert_organic_every_20_days",
                climateKey: "climate_warm_not_frost_tolerant",
                plaguesKey: "plagues_basil_common",
                imageName: "basil",
                companionsKey: "companions_basil",
                germinationDays: 7,
                wateringFrequencyKey: "watering_freq_every_2_3_days",
                harvestMonthsKeys: ["month_june", "month_july", "month_august"]
            ),

            // FRESA
            (
                nameKey: "crop_strawberry_name",
                categoryKey: "category_fruit",
                difficultyKey: "crop_difficulty_medium",
                descKey: "crop_strawberry_desc",
                seasons: ["season_spring", "season_summer"],
                steps: ["step_planting", "step_vegetative", "step_flowering", "step_harvest"],
                stepDescriptions: ["step_planting_desc", "step_vegetative_desc", "step_flowering_desc", "step_harvest_desc"],
                stepDurations: [14, 60, 30, 14],
                soilKey: "soil_sandy_fertile",
                wateringKey: "watering_regular_keep_moist",
                sunlightKey: "sun_full_or_partial",
                temperatureKey: "temp_15_25",
                fertilizationKey: "fert_high_potassium_flowering",
                climateKey: "climate_temperate_no_extreme_heat",
                plaguesKey: "plagues_strawberry_common",
                imageName: "strawberry",
                companionsKey: "companions_strawberry",
                germinationDays: 14,
                wateringFrequencyKey: "watering_freq_every_2_3_days",
                harvestMonthsKeys: ["month_may", "month_june"]
            ),

            // PEPINO
            (
                nameKey: "crop_cucumber_name",
                categoryKey: "category_vegetable",
                difficultyKey: "crop_difficulty_easy",
                descKey: "crop_cucumber_desc",
                seasons: ["season_spring", "season_summer"],
                steps: ["step_sowing", "step_transplant", "step_growth", "step_harvest"],
                stepDescriptions: ["step_sowing_desc", "step_transplant_desc", "step_growth_desc", "step_harvest_desc"],
                stepDurations: [10, 15, 50, 12],
                soilKey: "soil_loose_well_drained",
                wateringKey: "watering_consistent_avoid_drought",
                sunlightKey: "sun_full_sun",
                temperatureKey: "temp_18_30",
                fertilizationKey: "fert_high_potassium_fruiting",
                climateKey: "climate_warm_sensitive_cold",
                plaguesKey: "plagues_cucumber_common",
                imageName: "cucumber",
                companionsKey: "companions_cucumber",
                germinationDays: 10,
                wateringFrequencyKey: "watering_freq_every_2_days",
                harvestMonthsKeys: ["month_july", "month_august"]
            ),
            
            // PIMIENTO
            (
                nameKey: "crop_pepper_name",
                categoryKey: "category_vegetable",
                difficultyKey: "crop_difficulty_medium",
                descKey: "crop_pepper_desc",
                seasons: ["season_spring", "season_summer"],
                steps: ["step_sowing", "step_transplant", "step_growth", "step_harvest"],
                stepDescriptions: ["step_sowing_desc", "step_transplant_desc", "step_growth_desc", "step_harvest_desc"],
                stepDurations: [10, 20, 70, 20],
                soilKey: "soil_fertile_well_drained",
                wateringKey: "watering_regular_keep_moist",
                sunlightKey: "sun_full_sun",
                temperatureKey: "temp_20_30",
                fertilizationKey: "fert_high_potassium_fruiting",
                climateKey: "climate_warm_sensitive_cold",
                plaguesKey: "plagues_pepper_common",
                imageName: "pepper",
                companionsKey: "companions_pepper",
                germinationDays: 10,
                wateringFrequencyKey: "watering_freq_every_2_3_days",
                harvestMonthsKeys: ["month_august", "month_september"]
            ),

            // ZANAHORIA
            (
                nameKey: "crop_carrot_name",
                categoryKey: "category_vegetable",
                difficultyKey: "crop_difficulty_easy",
                descKey: "crop_carrot_desc",
                seasons: ["season_spring", "season_autumn"],
                steps: ["step_sowing_direct", "step_thinning", "step_growth", "step_harvest"],
                stepDescriptions: ["step_sowing_direct_desc", "step_thinning_desc", "step_growth_desc", "step_harvest_desc"],
                stepDurations: [7, 10, 60, 20],
                soilKey: "soil_loose_sandy",
                wateringKey: "watering_regular_keep_moist",
                sunlightKey: "sun_full_or_partial",
                temperatureKey: "temp_10_25",
                fertilizationKey: "fert_low_nitrogen",
                climateKey: "climate_cool_tolerates_frost",
                plaguesKey: "plagues_carrot_common",
                imageName: "carrot",
                companionsKey: "companions_carrot",
                germinationDays: 7,
                wateringFrequencyKey: "watering_freq_every_2_days",
                harvestMonthsKeys: ["month_june", "month_july", "month_october"]
            ),

            // CEBOLLA
            (
                nameKey: "crop_onion_name",
                categoryKey: "category_vegetable",
                difficultyKey: "crop_difficulty_easy",
                descKey: "crop_onion_desc",
                seasons: ["season_winter", "season_spring"],
                steps: ["step_sowing", "step_transplant", "step_growth", "step_harvest"],
                stepDescriptions: ["step_sowing_desc", "step_transplant_desc", "step_growth_desc", "step_harvest_desc"],
                stepDurations: [14, 20, 90, 30],
                soilKey: "soil_loose_fertile",
                wateringKey: "watering_moderate_avoid_waterlogging",
                sunlightKey: "sun_full_or_partial",
                temperatureKey: "temp_10_25",
                fertilizationKey: "fert_balanced",
                climateKey: "climate_temperate_tolerates_cold",
                plaguesKey: "plagues_onion_common",
                imageName: "onion",
                companionsKey: "companions_onion",
                germinationDays: 14,
                wateringFrequencyKey: "watering_freq_every_3_days",
                harvestMonthsKeys: ["month_july", "month_august", "month_september"]
            ),

            // SANDÍA
            (
                nameKey: "crop_watermelon_name",
                categoryKey: "category_fruit",
                difficultyKey: "crop_difficulty_hard",
                descKey: "crop_watermelon_desc",
                seasons: ["season_spring", "season_summer"],
                steps: ["step_sowing", "step_growth", "step_flowering", "step_harvest"],
                stepDescriptions: ["step_sowing_desc", "step_growth_desc", "step_flowering_desc", "step_harvest_desc"],
                stepDurations: [10, 60, 30, 20],
                soilKey: "soil_sandy_well_drained",
                wateringKey: "watering_abundant",
                sunlightKey: "sun_full_sun",
                temperatureKey: "temp_20_35",
                fertilizationKey: "fert_high_potassium_fruiting",
                climateKey: "climate_hot_sensitive_cold",
                plaguesKey: "plagues_watermelon_common",
                imageName: "watermelon",
                companionsKey: "companions_watermelon",
                germinationDays: 10,
                wateringFrequencyKey: "watering_freq_every_day",
                harvestMonthsKeys: ["month_july", "month_august"]
            ),

            // MAÍZ
            (
                nameKey: "crop_corn_name",
                categoryKey: "category_vegetable",
                difficultyKey: "crop_difficulty_medium",
                descKey: "crop_corn_desc",
                seasons: ["season_spring", "season_summer"],
                steps: ["step_sowing_direct", "step_growth", "step_harvest"],
                stepDescriptions: ["step_sowing_direct_desc", "step_growth_desc", "step_harvest_desc"],
                stepDurations: [10, 70, 20],
                soilKey: "soil_fertile_well_drained",
                wateringKey: "watering_regular_keep_moist",
                sunlightKey: "sun_full_sun",
                temperatureKey: "temp_18_30",
                fertilizationKey: "fert_nitrogen_high",
                climateKey: "climate_warm_sensitive_cold",
                plaguesKey: "plagues_corn_common",
                imageName: "corn",
                companionsKey: "companions_corn",
                germinationDays: 10,
                wateringFrequencyKey: "watering_freq_every_2_days",
                harvestMonthsKeys: ["month_august", "month_september"]
            )

            // 👉 Aquí agregas también pepper, carrot, onion, watermelon, corn siguiendo el mismo esquema
        ]

        // Insertar en Core Data
        for seed in seeds {
            guard let cropEntity = NSEntityDescription.entity(forEntityName: "Crop", in: context) else { continue }
            let crop = Crop(entity: cropEntity, insertInto: context)

            crop.cropID = UUID()
            crop.name = seed.nameKey
            crop.category = seed.categoryKey
            crop.difficulty = seed.difficultyKey
            crop.cropDescription = seed.descKey
            crop.recommendedSeasons = seed.seasons as NSArray
            crop.createdAt = Date()
            crop.updatedAt = Date()
            crop.imageName = seed.imageName

            // Steps
            for (index, stepKey) in seed.steps.enumerated() {
                if let stepEntity = NSEntityDescription.entity(forEntityName: "Step", in: context) {
                    let step = Step(entity: stepEntity, insertInto: context)
                    step.stepID = UUID()
                    step.title = stepKey
                    step.stepDescription = seed.stepDescriptions[index]
                    step.estimateDuration = Int32(seed.stepDurations[index])
                    step.order = Int16(index + 1)
                    step.crop = crop
                }
            }

            // CropInfo
            if let cropInfoEntity = NSEntityDescription.entity(forEntityName: "CropInfo", in: context) {
                let info = CropInfo(entity: cropInfoEntity, insertInto: context)
                info.infoID = UUID()
                info.soilType = seed.soilKey
                info.watering = seed.wateringKey
                info.sunlight = seed.sunlightKey
                info.temperatureRange = seed.temperatureKey
                info.fertilizationTips = seed.fertilizationKey
                info.climate = seed.climateKey
                info.plagues = seed.plaguesKey
                info.companions = seed.companionsKey
                info.germinationDays = seed.germinationDays
                info.wateringFrequency = seed.wateringFrequencyKey
                if let monthsKeys = seed.harvestMonthsKeys {
                    info.harvestMonths = monthsKeys as NSArray
                }
                info.crop = crop
            }
        }

        // Guardar
        do {
            if context.hasChanges {
                try context.save()
            }
            print("🌱 SeedData: seeds insertadas (usando KEYS).")
        } catch {
            print("❌ SeedData: error guardando seeds: \(error.localizedDescription)")
        }
    }
}
