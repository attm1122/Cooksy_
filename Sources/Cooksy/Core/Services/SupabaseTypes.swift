import Foundation
import SwiftData

// MARK: - User
/// Represents an authenticated user in the Cooksy system.
///
/// This is a domain-level user model, decoupled from the underlying Supabase `Auth.User`.
/// It provides a stable interface for Views and ViewModels regardless of the auth backend.
public struct User: Identifiable, Codable, Sendable, Hashable {
    /// The unique user identifier (matches the Supabase auth UUID).
    public let id: String
    /// The user's email address.
    public let email: String
    /// When the user account was created.
    public let createdAt: Date

    public init(id: String, email: String, createdAt: Date) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
    }
}

// MARK: - IngredientDTO
/// Data-transfer object for an ingredient returned by the Supabase API.
struct IngredientDTO: Codable, Sendable {
    let id: String
    let name: String
    let quantity: String?
    let unit: String?
    let isChecked: Bool
    let displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, name, quantity, unit
        case isChecked = "is_checked"
        case displayOrder = "display_order"
    }
}

// MARK: - RecipeStepDTO
/// Data-transfer object for a recipe step returned by the Supabase API.
struct RecipeStepDTO: Codable, Sendable {
    let id: String
    let title: String
    let instruction: String
    let durationMinutes: Int?
    let displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, title, instruction
        case durationMinutes = "duration_minutes"
        case displayOrder = "display_order"
    }
}

// MARK: - RecipeDTO
/// Data-transfer object for a recipe returned by the Supabase API (PostgREST).
///
/// Maps directly to the `recipes` table schema with snake_case coding keys.
/// Use `toModel(context:)` to convert into a SwiftData `Recipe` for local persistence.
struct RecipeDTO: Codable, Sendable, Identifiable {
    let id: String
    let title: String
    let heroNote: String
    let servings: Int
    let prepTimeMinutes: Int
    let cookTimeMinutes: Int
    let totalTimeMinutes: Int
    let status: String
    let confidence: String
    let confidenceScore: Int
    let confidenceNote: String
    let isSaved: Bool
    let createdAt: String
    let updatedAt: String
    let importJobId: String?
    let processingMessage: String?
    let sourceUrl: String
    let sourcePlatform: String
    let sourceCreator: String
    let sourceTitle: String
    let ingredients: [IngredientDTO]?
    let steps: [RecipeStepDTO]?

    enum CodingKeys: String, CodingKey {
        case id, title
        case heroNote = "hero_note"
        case servings
        case prepTimeMinutes = "prep_time_minutes"
        case cookTimeMinutes = "cook_time_minutes"
        case totalTimeMinutes = "total_time_minutes"
        case status, confidence
        case confidenceScore = "confidence_score"
        case confidenceNote = "confidence_note"
        case isSaved = "is_saved"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case importJobId = "import_job_id"
        case processingMessage = "processing_message"
        case sourceUrl = "source_url"
        case sourcePlatform = "source_platform"
        case sourceCreator = "source_creator"
        case sourceTitle = "source_title"
        case ingredients, steps
    }
}

// MARK: - RecipeDTO → Recipe conversion

extension RecipeDTO {

    /// Converts this DTO into a full SwiftData `Recipe` with nested ingredients and steps.
    ///
    /// - Parameter context: The `ModelContext` used to insert related models if needed.
    /// - Returns: A fully populated `Recipe` ready for insertion into SwiftData.
    func toModel(context: ModelContext) -> Recipe {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let recipe = Recipe(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            heroNote: heroNote,
            servings: servings,
            prepTimeMinutes: prepTimeMinutes,
            cookTimeMinutes: cookTimeMinutes,
            totalTimeMinutes: totalTimeMinutes,
            status: RecipeStatus(rawValue: status) ?? .processing,
            confidence: ConfidenceLevel(rawValue: confidence) ?? .medium,
            confidenceScore: confidenceScore,
            confidenceNote: confidenceNote,
            isSaved: isSaved,
            createdAt: isoFormatter.date(from: createdAt) ?? Date(),
            updatedAt: isoFormatter.date(from: updatedAt) ?? Date(),
            importJobId: importJobId,
            processingMessage: processingMessage,
            sourceUrl: sourceUrl,
            sourcePlatform: SourcePlatform(rawValue: sourcePlatform) ?? .youtube,
            sourceCreator: sourceCreator,
            sourceTitle: sourceTitle
        )

        // Attach ingredients
        if let ingredientDTOs = ingredients {
            let ingredientModels = ingredientDTOs.map { dto in
                Ingredient(
                    id: UUID(uuidString: dto.id) ?? UUID(),
                    name: dto.name,
                    quantity: dto.quantity,
                    unit: dto.unit,
                    isChecked: dto.isChecked,
                    displayOrder: dto.displayOrder
                )
            }
            recipe.ingredients = ingredientModels
        }

        // Attach steps
        if let stepDTOs = steps {
            let stepModels = stepDTOs.map { dto in
                RecipeStep(
                    id: UUID(uuidString: dto.id) ?? UUID(),
                    title: dto.title,
                    instruction: dto.instruction,
                    durationMinutes: dto.durationMinutes,
                    displayOrder: dto.displayOrder
                )
            }
            recipe.steps = stepModels
        }

        return recipe
    }
}

// MARK: - ImportJobStatus
/// The lifecycle status of a server-side recipe import job.
enum ImportJobStatus: String, Codable, Sendable {
    case pending
    case processing
    case ready
    case failed
}

// MARK: - ImportJobResponse
/// Response from the `beginImport` edge function.
struct ImportJobResponse: Codable, Sendable {
    let jobId: String
    let status: ImportJobStatus
    let recipe: RecipeDTO?

    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case status, recipe
    }
}

// MARK: - ImportStatusResponse
/// Response from the `checkImportStatus` edge function.
struct ImportStatusResponse: Codable, Sendable {
    let jobId: String
    let status: ImportJobStatus
    let recipe: RecipeDTO?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case status, recipe, message
    }
}
