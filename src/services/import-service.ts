import { appEnv, hasSupabaseConfig } from "@/lib/env";
import { mapImportJobToProgress } from "@/lib/import-jobs";
import { moderateUrl } from "@/lib/moderation";
import { trackEvent } from "@/lib/analytics";
import { captureError, captureMessage } from "@/lib/monitoring";
import { supabase } from "@/lib/supabase";
import { mapDomainRecipeToUiRecipe } from "@/features/recipes/lib/adapters";
import { detectPlatformFromUrl } from "@/features/recipes/lib/platform";
import { recipeRepository } from "@/features/recipes/services/recipeRepository";
import { startRecipeImport } from "@/features/recipes/services/recipeWorkflowService";
import { buildMockImportJob } from "@/mocks/import-job";
import { getThumbnailFromUrl } from "@/features/recipes/services/thumbnailService";
import type {
  CreateImportJobRequest,
  CreateImportJobResponse,
  ImportBackendMode,
  ImportJob,
  ImportJobStatusResponse
} from "@/types/ingestion";
import type { ImportProgress, Recipe } from "@/types/recipe";

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));
let localPendingRecipeCounter = 0;
const MAX_IMPORT_POLL_ATTEMPTS = 80;
const MAX_IMPORT_POLL_ERRORS = 3;

const resolveImportMode = (): ImportBackendMode => {
  if (appEnv.recipeImportMode === "auto") {
    return hasSupabaseConfig ? "remote" : "mock";
  }

  return appEnv.recipeImportMode;
};

type ImportGateway = {
  createJob: (payload: CreateImportJobRequest) => Promise<CreateImportJobResponse>;
  getJob: (jobId: string) => Promise<ImportJobStatusResponse>;
};

type PendingImportResult = {
  pendingRecipe: Recipe;
  job: ImportJob;
};

type MockRuntimeJob = {
  sourceUrl: string;
  status: ImportJob["status"];
  progress: number;
  detail: ImportJob["detail"];
  errorMessage?: string;
};

const mockJobs = new Map<string, MockRuntimeJob>();

const mockGateway: ImportGateway = {
  async createJob({ sourceUrl }) {
    const { processingRecipe, completion } = await startRecipeImport(sourceUrl, {
      onStageChange: (stage, recipeId) => {
        const runtime = mockJobs.get(recipeId);

        if (!runtime) {
          return;
        }

        const nextState =
          stage === "queued"
            ? {
                status: "queued" as const,
                progress: 0.08,
                detail: {
                  label: "Queued",
                  description: "Preparing source ingestion"
                }
              }
            : stage === "extracting"
              ? {
                  status: "extracting" as const,
                  progress: 0.28,
                  detail: {
                    label: "Extracting content",
                    description: "Pulling source metadata, captions, and creator context"
                  }
                }
              : stage === "identifying_ingredients"
                ? {
                    status: "identifying_ingredients" as const,
                    progress: 0.58,
                    detail: {
                      label: "Identifying ingredients",
                      description: "Extracting likely ingredients and explicit quantities"
                    }
                  }
                : stage === "building_steps"
                  ? {
                      status: "building_steps" as const,
                      progress: 0.86,
                      detail: {
                        label: "Building steps",
                        description: "Structuring the cooking method and inferred timings"
                      }
                    }
                  : stage === "completed"
                    ? {
                        status: "completed" as const,
                        progress: 1,
                        detail: {
                          label: "Completed",
                          description: "Recipe is ready"
                        }
                      }
                    : {
                        status: "failed" as const,
                        progress: 1,
                        detail: {
                          label: "Import failed",
                          description: "Cooksy could not reconstruct this recipe"
                        }
                      };

        mockJobs.set(recipeId, {
          ...runtime,
          ...nextState
        });
      }
    });

    const job = buildMockImportJob(sourceUrl);
    job.id = processingRecipe.id;
    mockJobs.set(processingRecipe.id, {
      sourceUrl,
      status: "queued",
      progress: 0.08,
      detail: {
        label: "Queued",
        description: "Preparing source ingestion"
      }
    });

    void completion.then((result) => {
      const runtime = mockJobs.get(processingRecipe.id);

      if (!runtime) {
        return;
      }

      mockJobs.set(processingRecipe.id, {
        ...runtime,
        status: result.status === "completed" ? "completed" : "failed",
        progress: 1,
        detail:
          result.status === "completed"
            ? {
                label: "Completed",
                description: "Recipe is ready"
              }
            : {
                label: "Import failed",
                description: result.validationWarnings[0] ?? result.missingFields[0] ?? "Cooksy could not reconstruct this recipe"
              },
        errorMessage:
          result.status === "failed"
            ? result.validationWarnings[0] ?? result.missingFields[0] ?? "Recipe import failed"
            : undefined
      });
    });

    return {
      job: {
        ...job,
        id: processingRecipe.id,
        sourcePlatform: detectPlatformFromUrl(sourceUrl),
        status: "queued",
        progress: 0.08,
        detail: {
          label: "Queued",
          description: "Preparing source ingestion"
        }
      }
    };
  },
  async getJob(jobId) {
    await sleep(120);
    const runtime = mockJobs.get(jobId);

    if (!runtime) {
      throw new Error("Import job not found");
    }

    const recipe = await recipeRepository.getById(jobId);

    return {
      job: {
        id: jobId,
        sourceUrl: runtime.sourceUrl,
        sourcePlatform: detectPlatformFromUrl(runtime.sourceUrl),
        status: runtime.status,
        progress: runtime.progress,
        detail: runtime.detail,
        errorMessage: runtime.errorMessage,
        recipe: recipe?.status === "completed" ? mapDomainRecipeToUiRecipe(recipe) : undefined,
        createdAt: recipe?.createdAt ?? new Date().toISOString(),
        updatedAt: recipe?.updatedAt ?? new Date().toISOString()
      }
    };
  }
};

const remoteGateway: ImportGateway = {
  async createJob(payload) {
    if (!supabase) {
      throw new Error("Supabase is not configured");
    }

    const { data, error } = await supabase.functions.invoke("import-recipe", {
      body: {
        action: "create",
        ...payload
      }
    });

    if (error) {
      throw error;
    }

    return data as CreateImportJobResponse;
  },
  async getJob(jobId) {
    if (!supabase) {
      throw new Error("Supabase is not configured");
    }

    const { data, error } = await supabase.functions.invoke("import-recipe", {
      body: {
        action: "status",
        jobId
      }
    });

    if (error) {
      throw error;
    }

    return data as ImportJobStatusResponse;
  }
};

const getGateway = (): ImportGateway => (resolveImportMode() === "remote" ? remoteGateway : mockGateway);

export const pollImportJobUntilComplete = async (
  jobId: string,
  onProgress?: (progress: ImportProgress) => void
): Promise<Recipe> => {
  const gateway = getGateway();
  let attempts = 0;
  let consecutiveErrors = 0;

  while (attempts < MAX_IMPORT_POLL_ATTEMPTS) {
    try {
      const { job } = await gateway.getJob(jobId);
      consecutiveErrors = 0;
      const mappedProgress = mapImportJobToProgress(job);
      onProgress?.(mappedProgress);
      trackEvent("recipe_import_progressed", {
        jobId,
        status: job.status,
        progress: Number(job.progress.toFixed(3))
      });

      if (job.status === "completed") {
        if (job.recipe) {
          trackEvent("recipe_import_completed", {
            jobId,
            sourcePlatform: job.sourcePlatform
          });
          return job.recipe;
        }

        trackEvent("recipe_import_completed", {
          jobId,
          sourcePlatform: job.sourcePlatform
        });
        throw new Error("Completed import job did not include a recipe payload");
      }

      if (job.status === "failed") {
        trackEvent("recipe_import_failed", {
          jobId,
          sourcePlatform: job.sourcePlatform,
          reason: job.errorMessage ?? "Recipe import failed"
        });
        captureMessage("Recipe import job failed", {
          jobId,
          sourcePlatform: job.sourcePlatform,
          reason: job.errorMessage ?? "Recipe import failed"
        });
        throw new Error(job.errorMessage ?? "Recipe import failed");
      }
    } catch (error) {
      consecutiveErrors += 1;

      if (consecutiveErrors >= MAX_IMPORT_POLL_ERRORS) {
        captureError(error, {
          action: "poll_import_job",
          jobId,
          attempts,
          consecutiveErrors
        });
        throw error;
      }
    }

    attempts += 1;
    await sleep(resolveImportMode() === "remote" ? 2000 : 450);
  }

  trackEvent("recipe_import_failed", {
    jobId,
    reason: "timeout"
  });
  throw new Error("Recipe import timed out");
};

const buildPendingRecipe = async (sourceUrl: string, recipeId: string, importJobId: string): Promise<Recipe> => {
  const thumbnail = await getThumbnailFromUrl(sourceUrl);

  return {
    id: recipeId,
    status: "processing",
    importJobId,
    processingMessage: "Generating recipe...",
    title: "Saved recipe in progress",
    description: "Your recipe is being assembled from the original video so you can come back to it when it’s ready.",
    heroNote: "Saved from a link you discovered. Cooksy is turning it into something you can actually cook.",
    imageLabel: "Imported recipe cover",
    thumbnailUrl: thumbnail.thumbnailUrl,
    thumbnailSource: thumbnail.thumbnailSource,
    thumbnailFallbackStyle: thumbnail.thumbnailFallbackStyle,
    servings: 2,
    prepTimeMinutes: 0,
    cookTimeMinutes: 0,
    totalTimeMinutes: 0,
    confidence: "medium",
    confidenceScore: 0,
    confidenceNote: "Cooksy is still reconstructing the recipe from the source content.",
    confidenceReport: {
      score: 0,
      warnings: [],
      missingFields: ["Recipe details still generating"],
      lowConfidenceAreas: ["Ingredients", "Steps"]
    },
    inferredFields: [],
    missingFields: ["Recipe details still generating"],
    warnings: [],
    editableFields: ["Ingredients", "Steps"],
    isSaved: true,
    source: {
      creator: "Saved source",
      url: sourceUrl,
      platform: detectPlatformFromUrl(sourceUrl)
    },
    ingredients: [],
    steps: [],
    tags: ["Processing"]
  };
};

export const beginRecipeImport = async (sourceUrl: string): Promise<PendingImportResult> => {
  // Check content moderation
  const moderationResult = moderateUrl(sourceUrl);
  if (!moderationResult.allowed) {
    trackEvent("recipe_import_failed", {
      sourceUrl,
      reason: moderationResult.reason,
      moderationSeverity: moderationResult.severity
    });
    captureMessage("Import blocked by moderation", {
      sourceUrl,
      reason: moderationResult.reason,
      severity: moderationResult.severity
    });
    throw new Error(moderationResult.reason || "This source cannot be imported");
  }

  const gateway = getGateway();
  const { job } = await gateway.createJob({ sourceUrl });
  const pendingRecipeId = job.id || createPendingRecipeId();
  const pendingRecipe = await buildPendingRecipe(sourceUrl, pendingRecipeId, job.id);

  trackEvent("recipe_import_started", {
    jobId: job.id,
    sourcePlatform: job.sourcePlatform
  });

  return {
    pendingRecipe,
    job
  };
};

export const importRecipeFromUrl = async (
  sourceUrl: string,
  onProgress?: (progress: ImportProgress) => void
): Promise<Recipe> => {
  const { job } = await beginRecipeImport(sourceUrl);
  onProgress?.(mapImportJobToProgress(job));

  return pollImportJobUntilComplete(job.id, onProgress);
};

export const createPendingRecipeFromUrl = async (sourceUrl: string, recipeId: string): Promise<Recipe> => {
  return buildPendingRecipe(sourceUrl, recipeId, recipeId);
};

export const createPendingRecipeId = () => {
  localPendingRecipeCounter += 1;
  return `saved-${localPendingRecipeCounter}`;
};

export const retryRecipeImport = async (
  recipe: Pick<Recipe, "id" | "source">,
  onProgress?: (progress: ImportProgress) => void
): Promise<PendingImportResult> => {
  try {
    const result = await beginRecipeImport(recipe.source.url);
    trackEvent("recipe_import_retried", {
      oldRecipeId: recipe.id,
      newJobId: result.job.id,
      sourcePlatform: result.job.sourcePlatform
    });
    onProgress?.(mapImportJobToProgress(result.job));
    return result;
  } catch (error) {
    captureError(error, {
      recipeId: recipe.id,
      sourceUrl: recipe.source.url,
      action: "retry_import"
    });
    throw error;
  }
};
