import { appEnv, hasSupabaseConfig } from "@/lib/env";
import { mapImportJobToProgress } from "@/lib/import-jobs";
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
    onProgress?.(mapImportJobToProgress(job));

    if (job.status === "completed") {
      if (job.recipe) {
        return job.recipe;
      }

      return buildMockImportedRecipe(job.sourceUrl);
    }

    if (job.status === "failed") {
      throw new Error(job.errorMessage ?? "Recipe import failed");
    }

    attempts += 1;
    await sleep(resolveImportMode() === "remote" ? 1500 : 450);
  }

  throw new Error("Recipe import timed out");
};

export const importRecipeFromUrl = async (
  sourceUrl: string,
  onProgress?: (progress: ImportProgress) => void
): Promise<Recipe> => {
  const gateway = getGateway();
  const { job } = await gateway.createJob({ sourceUrl });
  onProgress?.(mapImportJobToProgress(job));

  return pollImportJobUntilComplete(job.id, onProgress);
};

export const createPendingRecipeFromUrl = async (sourceUrl: string, recipeId: string): Promise<Recipe> => {
  const thumbnail = await getThumbnailFromUrl(sourceUrl);

  return {
    id: recipeId,
    status: "processing",
    importJobId: undefined,
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

export const createPendingRecipeId = () => {
  localPendingRecipeCounter += 1;
  return `saved-${localPendingRecipeCounter}`;
};
