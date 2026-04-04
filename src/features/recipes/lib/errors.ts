export class InvalidRecipeUrlError extends Error {
  constructor(message = "Please paste a valid recipe link") {
    super(message);
    this.name = "InvalidRecipeUrlError";
  }
}

export class UnsupportedPlatformError extends Error {
  constructor(message = "Cooksy currently supports YouTube, TikTok, and Instagram recipe links") {
    super(message);
    this.name = "UnsupportedPlatformError";
  }
}

export class ExtractionFailedError extends Error {
  constructor(message = "Cooksy could not extract enough source context from this link") {
    super(message);
    this.name = "ExtractionFailedError";
  }
}

export class RecipeReconstructionError extends Error {
  constructor(message = "Cooksy could not reconstruct a trustworthy recipe from this source") {
    super(message);
    this.name = "RecipeReconstructionError";
  }
}

