import { appEnv, hasSupabaseConfig } from "@/lib/env";
import { mapImportJobToProgress } from "@/lib/import-jobs";
import { trackEvent } from "@/lib/analytics";
import { captureError, captureMessage } from "@/lib/monitoring";
import { supabase } from "@/lib/supabase";
import { buildMockImportJob, buildMockImportedRecipe, inferPlatformFromUrl } from "@/mocks/import-job";
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

const mockJobs = new Map<string, { sourceUrl: string; createdAt: number }>();

const buildMockJobFromElapsed = (jobId: string): ImportJob => {
  const state = mockJobs.get(jobId);

  if (!state) {
    throw new Error("Import job not found");
  }

  const elapsed = Date.now() - state.createdAt;
  const base = buildMockImportJob(state.sourceUrl);
  const updatedAt = new Date().toISOString();

  if (elapsed < 500) {
    return {
      ...base,
      id: jobId,
      status: "queued",
      progress: 0.08,
      detail: {
        label: "Queued",
        description: "Preparing source ingestion"
      },
      updatedAt
    };
  }

  if (elapsed < 1400) {
    return {
      ...base,
      id: jobId,
      status: "extracting",
      progress: 0.28,
      detail: {
        label: "Extracting content",
        description: "Pulling source metadata, captions, and creator context"
      },
      updatedAt
    };
  }

  if (elapsed < 2400) {
    return {
      ...base,
      id: jobId,
      status: "identifying_ingredients",
      progress: 0.58,
      detail: {
        label: "Identifying ingredients",
        description: "Inferring ingredient list and estimated quantities"
      },
      updatedAt
    };
  }

  if (elapsed < 3400) {
    return {
      ...base,
      id: jobId,
      status: "building_steps",
      progress: 0.86,
      detail: {
        label: "Building steps",
        description: "Structuring the cooking method and timings"
      },
      updatedAt
    };
  }

  return {
    ...base,
    id: jobId,
    status: "completed",
    progress: 1,
    detail: {
      label: "Completed",
      description: "Recipe is ready"
    },
    updatedAt
  };
};

const mockGateway: ImportGateway = {
  async createJob({ sourceUrl }) {
    const job = buildMockImportJob(sourceUrl);
    mockJobs.set(job.id, {
      sourceUrl,
      createdAt: Date.now()
    });

    return {
      job
    };
  },
  async getJob(jobId) {
    await sleep(350);

    return {
      job: buildMockJobFromElapsed(jobId)
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

  while (attempts < 40) {
    const { job } = await gateway.getJob(jobId);
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
      return buildMockImportedRecipe(job.sourceUrl, job.id);
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

    attempts += 1;
    await sleep(resolveImportMode() === "remote" ? 1500 : 450);
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
    inferredFields: [],
    missingFields: ["Recipe details still generating"],
    isSaved: true,
    source: {
      creator: "Saved source",
      url: sourceUrl,
      platform: inferPlatformFromUrl(sourceUrl)
    },
    ingredients: [],
    steps: [],
    tags: ["Processing"]
  };
};

export const beginRecipeImport = async (sourceUrl: string): Promise<PendingImportResult> => {
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
