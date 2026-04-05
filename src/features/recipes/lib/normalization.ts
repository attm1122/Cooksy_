/**
 * Recipe Normalization Layer
 * 
 * This module provides strong normalization for extracted recipe data
 * before it's presented to users. It validates, cleans, and enhances
 * recipe content to ensure high quality and trustworthiness.
 */

import type {
  CandidateIngredient,
  CandidateStep,
  RawRecipeContext,
  ReconstructionResult
} from "@/features/recipes/types";

// Common cooking units and their canonical forms
const UNIT_ALIASES: Record<string, string> = {
  // Volume
  "tablespoon": "tbsp",
  "tablespoons": "tbsp",
  "tbls": "tbsp",
  "tbl": "tbsp",
  "tbs": "tbsp",
  "tb": "tbsp",
  "teaspoon": "tsp",
  "teaspoons": "tsp",
  "tspn": "tsp",
  "cup": "cup",
  "cups": "cup",
  "c": "cup",
  "fluid ounce": "fl oz",
  "fluid ounces": "fl oz",
  "pint": "pt",
  "pints": "pt",
  "quart": "qt",
  "quarts": "qt",
  "gallon": "gal",
  "gallons": "gal",
  "milliliter": "ml",
  "milliliters": "ml",
  "mls": "ml",
  "liter": "L",
  "liters": "L",
  // Weight
  "ounce": "oz",
  "ounces": "oz",
  "pound": "lb",
  "pounds": "lb",
  "lbs": "lb",
  "gram": "g",
  "grams": "g",
  "gramme": "g",
  "grammes": "g",
  "kilogram": "kg",
  "kilograms": "kg",
  "kgs": "kg",
  // Count
  "piece": "piece",
  "pieces": "pieces",
  "pc": "piece",
  "pcs": "pieces",
  "clove": "clove",
  "cloves": "cloves",
  "fillet": "fillet",
  "fillets": "fillets",
  "slice": "slice",
  "slices": "slices",
  "bunch": "bunch",
  "bunches": "bunch",
  "pinch": "pinch",
  "pinches": "pinch",
  "handful": "handful",
  "handfuls": "handful",
  "sprig": "sprig",
  "sprigs": "sprig",
  "can": "can",
  "cans": "can",
  "package": "pkg",
  "packages": "pkg",
  "pkg": "pkg",
  "pkgs": "pkg",
  "stick": "stick",
  "sticks": "stick"
};

// Action verbs that indicate a cooking step
const VALID_ACTION_VERBS = [
  "add", "combine", "mix", "stir", "whisk", "fold", "blend",
  "heat", "warm", "preheat", "bring to", "simmer", "boil", "poach",
  "cook", "sauté", "saute", "fry", "sear", "brown", "caramelize",
  "roast", "bake", "broil", "grill", "char",
  "chop", "dice", "mince", "slice", "julienne", "cube", "cut",
  "grate", "shred", "zest", "peel", "trim", "remove",
  "season", "salt", "pepper", "spice", "marinate", "coat",
  "pour", "transfer", "place", "arrange", "set aside", "remove",
  "reduce", "thicken", "emulsify", "deglaze",
  "rest", "cool", "chill", "freeze", "refrigerate",
  "serve", "garnish", "top", "drizzle", "sprinkle", "finish"
];

// Words that shouldn't appear in ingredient names
const INVALID_INGREDIENT_WORDS = [
  "and", "or", "with", "without", "plus", "minus",
  "then", "next", "finally", "before", "after",
  "if", "when", "while", "until", "once"
];

// Common food words to validate ingredients
const COMMON_FOODS = new Set([
  "chicken", "beef", "pork", "lamb", "fish", "salmon", "tuna", "shrimp",
  "rice", "pasta", "noodle", "bread", "flour", "sugar", "salt", "pepper",
  "butter", "oil", "olive oil", "vinegar", "water", "milk", "cream",
  "egg", "onion", "garlic", "tomato", "potato", "carrot", "celery",
  "lettuce", "spinach", "kale", "broccoli", "cauliflower", "pepper",
  "mushroom", "lemon", "lime", "orange", "apple", "banana",
  "cheese", "parmesan", "mozzarella", "cheddar", "yogurt",
  "honey", "maple syrup", "soy sauce", "sesame oil", "ginger",
  "cumin", "coriander", "paprika", "cinnamon", "oregano", "basil"
]);

export type NormalizationResult = {
  success: true;
  confidence: number;
  warnings: string[];
} | {
  success: false;
  reason: string;
  fallbackSuggestion?: string;
};

/**
 * Normalize an ingredient name to a standard format
 */
export function normalizeIngredientName(name: string): string {
  // Remove extra whitespace
  let normalized = name.trim().toLowerCase();
  
  // Remove leading articles
  normalized = normalized.replace(/^(a|an|the)\s+/i, "");
  
  // Remove invalid words
  INVALID_INGREDIENT_WORDS.forEach((word) => {
    normalized = normalized.replace(new RegExp(`\\b${word}\\b`, "gi"), "");
  });
  
  // Remove extra whitespace after replacements
  normalized = normalized.replace(/\s+/g, " ").trim();
  
  // Capitalize first letter of each word
  normalized = normalized
    .split(" ")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
  
  return normalized;
}

/**
 * Normalize a unit to its canonical form
 */
export function normalizeUnit(unit: string | null | undefined): string | null {
  if (!unit) return null;
  
  const normalized = unit.trim().toLowerCase();
  return UNIT_ALIASES[normalized] || normalized;
}

/**
 * Validate that an ingredient looks legitimate
 */
export function validateIngredient(ingredient: CandidateIngredient): NormalizationResult {
  const warnings: string[] = [];
  let confidence = ingredient.confidence;
  
  // Check name validity
  if (!ingredient.name || ingredient.name.length < 2) {
    return {
      success: false,
      reason: "Ingredient name is too short or missing"
    };
  }
  
  if (ingredient.name.length > 50) {
    warnings.push("Ingredient name is unusually long");
    confidence *= 0.9;
  }
  
  // Check for suspicious content
  const nameLower = ingredient.name.toLowerCase();
  
  if (INVALID_INGREDIENT_WORDS.some((word) => nameLower.includes(word))) {
    warnings.push("Ingredient name contains non-food words");
    confidence *= 0.7;
  }
  
  // Check if it looks like a food
  const looksLikeFood = Array.from(COMMON_FOODS).some((food) => 
    nameLower.includes(food) || food.includes(nameLower)
  );
  
  if (!looksLikeFood && ingredient.name.length > 3) {
    warnings.push("Ingredient name doesn't match common foods");
    confidence *= 0.8;
  }
  
  // Validate quantity if present
  if (ingredient.quantity) {
    const qty = parseFloat(ingredient.quantity);
    if (isNaN(qty) || qty < 0 || qty > 1000) {
      warnings.push("Quantity looks suspicious");
      confidence *= 0.8;
    }
  }
  
  // Check confidence threshold
  if (confidence < 0.3) {
    return {
      success: false,
      reason: "Ingredient confidence too low",
      fallbackSuggestion: ingredient.uncertain 
        ? `Consider reviewing: "${ingredient.name}"`
        : undefined
    };
  }
  
  return {
    success: true,
    confidence,
    warnings
  };
}

/**
 * Validate that a cooking step looks legitimate
 */
export function validateStep(step: CandidateStep): NormalizationResult {
  const warnings: string[] = [];
  let confidence = step.confidence;
  
  // Check instruction validity
  if (!step.instruction || step.instruction.length < 10) {
    return {
      success: false,
      reason: "Step instruction is too short or missing"
    };
  }
  
  if (step.instruction.length > 300) {
    warnings.push("Step is unusually long, consider splitting");
    confidence *= 0.9;
  }
  
  // Check for action verb
  const instructionLower = step.instruction.toLowerCase();
  const hasActionVerb = VALID_ACTION_VERBS.some((verb) => 
    instructionLower.includes(verb.toLowerCase())
  );
  
  if (!hasActionVerb) {
    warnings.push("Step doesn't contain a clear action verb");
    confidence *= 0.7;
  }
  
  // Check for suspicious patterns
  if (instructionLower.includes("http") || instructionLower.includes("www")) {
    warnings.push("Step contains URL references");
    confidence *= 0.5;
  }
  
  if (step.instruction.includes("?") && !instructionLower.includes("check")) {
    warnings.push("Step contains question mark");
    confidence *= 0.8;
  }
  
  // Validate timing if present
  if (step.durationMinutes !== undefined && step.durationMinutes !== null) {
    if (step.durationMinutes < 0 || step.durationMinutes > 480) {
      warnings.push("Duration looks suspicious (outside 0-8 hours range)");
      confidence *= 0.8;
    }
  }
  
  // Check confidence threshold
  if (confidence < 0.4) {
    return {
      success: false,
      reason: "Step confidence too low",
      fallbackSuggestion: "Review this step for clarity"
    };
  }
  
  return {
    success: true,
    confidence,
    warnings
  };
}

/**
 * Calculate overall recipe quality score
 */
export function calculateRecipeQuality(
  ingredients: CandidateIngredient[],
  steps: CandidateStep[],
  context: RawRecipeContext
): {
  score: number;
  grade: "excellent" | "good" | "fair" | "poor";
  recommendations: string[];
} {
  const recommendations: string[] = [];
  let score = 0;
  
  // Ingredient quality (40%)
  if (ingredients.length === 0) {
    recommendations.push("No ingredients detected - manual review needed");
    score += 0;
  } else if (ingredients.length < 3) {
    recommendations.push("Very few ingredients detected - may be incomplete");
    score += 10;
  } else {
    const validIngredients = ingredients.filter((ing) => 
      validateIngredient(ing).success
    ).length;
    const ingredientRatio = validIngredients / ingredients.length;
    score += ingredientRatio * 40;
    
    if (ingredientRatio < 0.8) {
      recommendations.push("Some ingredients have low confidence - review suggested");
    }
  }
  
  // Step quality (40%)
  if (steps.length === 0) {
    recommendations.push("No cooking steps detected - manual review needed");
    score += 0;
  } else if (steps.length < 2) {
    recommendations.push("Very few steps detected - recipe may be incomplete");
    score += 10;
  } else {
    const validSteps = steps.filter((step) => 
      validateStep(step).success
    ).length;
    const stepRatio = validSteps / steps.length;
    score += stepRatio * 40;
    
    if (stepRatio < 0.8) {
      recommendations.push("Some steps have low confidence - review suggested");
    }
  }
  
  // Signal richness (20%)
  const signalCount = 
    (context.transcriptSegments?.length || 0) +
    (context.ocrText?.length || 0) +
    (context.signals?.length || 0);
  
  if (signalCount > 20) {
    score += 20;
  } else if (signalCount > 10) {
    score += 15;
    recommendations.push("Moderate source material - some details may be missing");
  } else if (signalCount > 5) {
    score += 10;
    recommendations.push("Limited source material - manual review strongly recommended");
  } else {
    score += 5;
    recommendations.push("Very limited source material - extensive review needed");
  }
  
  // Determine grade
  let grade: "excellent" | "good" | "fair" | "poor";
  if (score >= 85) {
    grade = "excellent";
  } else if (score >= 70) {
    grade = "good";
  } else if (score >= 50) {
    grade = "fair";
  } else {
    grade = "poor";
  }
  
  // Add general recommendations based on grade
  if (grade === "poor") {
    recommendations.unshift("Recipe quality is low - manual verification essential before sharing");
  } else if (grade === "fair") {
    recommendations.unshift("Recipe quality is moderate - please review before relying on it");
  }
  
  return {
    score: Math.round(score),
    grade,
    recommendations
  };
}

/**
 * Generate a human-readable confidence note
 */
export function generateConfidenceNote(
  quality: { score: number; grade: string; recommendations: string[] },
  inferredCount: number,
  missingCount: number
): string {
  const parts: string[] = [];
  
  switch (quality.grade) {
    case "excellent":
      parts.push("Cooksy extracted this recipe with high confidence from the source.");
      break;
    case "good":
      parts.push("Cooksy extracted this recipe well, with most details captured clearly.");
      break;
    case "fair":
      parts.push("Cooksy extracted this recipe, but some details may need your review.");
      break;
    case "poor":
      parts.push("Cooksy had difficulty extracting this recipe. Please review carefully.");
      break;
  }
  
  if (inferredCount > 0) {
    parts.push(`${inferredCount} detail${inferredCount === 1 ? " was" : "s were"} estimated.`);
  }
  
  if (missingCount > 0) {
    parts.push(`${missingCount} detail${missingCount === 1 ? " is" : "s are"} missing.`);
  }
  
  if (quality.recommendations.length > 0 && quality.grade !== "excellent") {
    parts.push(quality.recommendations[0]);
  }
  
  return parts.join(" ");
}

/**
 * Main normalization function for recipe reconstruction results
 */
export function normalizeReconstructionResult(
  result: ReconstructionResult,
  context: RawRecipeContext
): ReconstructionResult {
  // Map IngredientSignal[] to CandidateIngredient[] for quality calculation
  const candidateIngredients: CandidateIngredient[] = 
    result.rawExtraction.ingredientSignals?.map((sig) => ({
      id: sig.id,
      name: sig.name,
      quantity: sig.quantity,
      unit: sig.unit,
      note: sig.note,
      confidence: sig.weight, // Map weight to confidence
      supportingSignals: sig.sourceSignalIds
    })) || [];
  
  // Map StepSignal[] to CandidateStep[] for quality calculation  
  const candidateSteps: CandidateStep[] =
    result.rawExtraction.stepSignals?.map((sig) => ({
      id: sig.id,
      instruction: sig.instruction,
      actionVerb: sig.action,
      object: sig.object,
      durationMinutes: sig.timestamp 
        ? Math.round(sig.timestamp / 60) 
        : undefined,
      timestamp: sig.timestamp,
      confidence: sig.weight, // Map weight to confidence
      supportingSignals: sig.sourceSignalIds
    })) || [];
  
  const quality = calculateRecipeQuality(
    candidateIngredients,
    candidateSteps,
    context
  );
  
  // Update confidence based on quality assessment
  const normalizedConfidenceScore = Math.round(quality.score);
  
  // Generate confidence note
  const confidenceNote = generateConfidenceNote(
    quality,
    result.inferredFields.length,
    result.missingFields.length
  );
  
  // Update confidence report
  const confidenceReport = {
    ...result.confidenceReport,
    score: quality.score / 100,
    warnings: [...result.confidenceReport.warnings, ...quality.recommendations]
  };
  
  return {
    ...result,
    confidenceScore: normalizedConfidenceScore,
    confidenceNote,
    confidenceReport
  };
}
