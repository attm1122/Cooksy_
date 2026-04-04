import type { ImportJob, ImportJobStatus } from "@/types/ingestion";
import type { ImportProgress } from "@/types/recipe";

const statusToProgressMap: Record<
  ImportJobStatus,
  Pick<ImportProgress, "stage" | "progress" | "detail">
> = {
  queued: {
    stage: "queued",
    progress: 0.08,
    detail: "Queued for ingestion"
  },
  extracting: {
    stage: "extracting",
    progress: 0.28,
    detail: "Extracting source metadata and captions"
  },
  identifying_ingredients: {
    stage: "ingredients",
    progress: 0.58,
    detail: "Identifying ingredients and quantities"
  },
  building_steps: {
    stage: "steps",
    progress: 0.86,
    detail: "Building the cooking method"
  },
  completed: {
    stage: "complete",
    progress: 1,
    detail: "Recipe import complete"
  },
  failed: {
    stage: "error",
    progress: 1,
    detail: "Recipe import failed"
  }
};

export const mapImportJobToProgress = (job: ImportJob): ImportProgress => ({
  url: job.sourceUrl,
  ...statusToProgressMap[job.status],
  jobId: job.id,
  errorMessage: job.errorMessage
});
