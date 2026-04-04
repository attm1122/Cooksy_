import type { Recipe, SourcePlatform } from "@/types/recipe";

export type ImportBackendMode = "mock" | "remote" | "auto";

export type ImportJobStatus =
  | "queued"
  | "extracting"
  | "identifying_ingredients"
  | "building_steps"
  | "completed"
  | "failed";

export type ImportJobStageDetail = {
  label: string;
  description: string;
};

export type ImportJob = {
  id: string;
  sourceUrl: string;
  sourcePlatform: SourcePlatform;
  status: ImportJobStatus;
  progress: number;
  detail: ImportJobStageDetail;
  recipe?: Recipe;
  errorMessage?: string;
  createdAt: string;
  updatedAt: string;
};

export type CreateImportJobRequest = {
  sourceUrl: string;
};

export type CreateImportJobResponse = {
  job: ImportJob;
};

export type ImportJobStatusResponse = {
  job: ImportJob;
};
