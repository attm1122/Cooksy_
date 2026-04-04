import { captureError, captureMessage } from "@/lib/monitoring";
import type { SourcePlatform } from "@/features/recipes/types";
import type { ExtractionResult } from "./types";
import { extractContextFromUrl } from "./orchestrator";
import { extractionAnalytics } from "./analytics";

export type JobStatus = "queued" | "processing" | "completed" | "failed" | "cancelled";

export type ExtractionJob = {
  id: string;
  url: string;
  platform: SourcePlatform;
  status: JobStatus;
  priority: number; // Higher = process first
  createdAt: number;
  startedAt?: number;
  completedAt?: number;
  result?: ExtractionResult;
  error?: string;
  retryCount: number;
  maxRetries: number;
  progress: number; // 0-100
};

type JobCallback = (job: ExtractionJob) => void;

class BackgroundJobProcessor {
  private jobs = new Map<string, ExtractionJob>();
  private queue: string[] = [];
  private callbacks = new Map<string, Set<JobCallback>>();
  private processing = false;
  private concurrency = 2; // Process 2 jobs concurrently
  private activeJobs = 0;

  // Create a new extraction job
  createJob(url: string, platform: SourcePlatform, priority: number = 0): ExtractionJob {
    const id = `job-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    const job: ExtractionJob = {
      id,
      url,
      platform,
      status: "queued",
      priority,
      createdAt: Date.now(),
      retryCount: 0,
      maxRetries: 2,
      progress: 0
    };

    this.jobs.set(id, job);
    this.queue.push(id);
    this.sortQueue();
    
    captureMessage("Extraction job created", { jobId: id, url, platform });
    
    // Start processing if not already running
    this.startProcessing();
    
    return job;
  }

  // Get job by ID
  getJob(id: string): ExtractionJob | undefined {
    return this.jobs.get(id);
  }

  // Get all jobs for a URL
  getJobsByUrl(url: string): ExtractionJob[] {
    return Array.from(this.jobs.values()).filter(job => job.url === url);
  }

  // Cancel a job
  cancelJob(id: string): boolean {
    const job = this.jobs.get(id);
    if (!job || job.status === "completed" || job.status === "failed") {
      return false;
    }

    job.status = "cancelled";
    this.notifyCallbacks(id, job);
    
    // Remove from queue if still queued
    const queueIndex = this.queue.indexOf(id);
    if (queueIndex !== -1) {
      this.queue.splice(queueIndex, 1);
    }

    return true;
  }

  // Subscribe to job updates
  subscribe(id: string, callback: JobCallback): () => void {
    if (!this.callbacks.has(id)) {
      this.callbacks.set(id, new Set());
    }
    this.callbacks.get(id)!.add(callback);

    // Immediately notify with current state if job exists
    const job = this.jobs.get(id);
    if (job) {
      callback(job);
    }

    // Return unsubscribe function
    return () => {
      this.callbacks.get(id)?.delete(callback);
    };
  }

  // Get queue status
  getQueueStatus() {
    const allJobs = Array.from(this.jobs.values());
    return {
      total: allJobs.length,
      queued: allJobs.filter(j => j.status === "queued").length,
      processing: allJobs.filter(j => j.status === "processing").length,
      completed: allJobs.filter(j => j.status === "completed").length,
      failed: allJobs.filter(j => j.status === "failed").length,
      activeJobs: this.activeJobs,
      concurrency: this.concurrency
    };
  }

  // Clean up old completed jobs
  cleanup(maxAgeMs: number = 1000 * 60 * 60) { // 1 hour default
    const cutoff = Date.now() - maxAgeMs;
    let cleaned = 0;

    for (const [id, job] of this.jobs.entries()) {
      if ((job.status === "completed" || job.status === "failed" || job.status === "cancelled") 
          && (job.completedAt || job.createdAt) < cutoff) {
        this.jobs.delete(id);
        this.callbacks.delete(id);
        cleaned++;
      }
    }

    return cleaned;
  }

  private sortQueue() {
    this.queue.sort((a, b) => {
      const jobA = this.jobs.get(a)!;
      const jobB = this.jobs.get(b)!;
      // Higher priority first, then earlier creation time
      if (jobA.priority !== jobB.priority) {
        return jobB.priority - jobA.priority;
      }
      return jobA.createdAt - jobB.createdAt;
    });
  }

  private async startProcessing() {
    if (this.processing) return;
    this.processing = true;

    while (this.queue.length > 0 && this.activeJobs < this.concurrency) {
      const jobId = this.queue.shift();
      if (!jobId) continue;

      const job = this.jobs.get(jobId);
      if (!job || job.status !== "queued") continue;

      this.processJob(job);
    }

    this.processing = false;
  }

  private async processJob(job: ExtractionJob) {
    this.activeJobs++;
    job.status = "processing";
    job.startedAt = Date.now();
    job.progress = 10;
    this.notifyCallbacks(job.id, job);

    try {
      const result = await extractContextFromUrl(job.url, {
        timeoutMs: 60000, // 1 minute for background jobs
        retryCount: job.maxRetries
      });

      job.result = result;
      job.progress = 100;
      
      if (result.success) {
        job.status = "completed";
        captureMessage("Extraction job completed", {
          jobId: job.id,
          durationMs: Date.now() - job.startedAt
        });
      } else {
        // Check if we should retry
        if (job.retryCount < job.maxRetries && this.isRetryable(result)) {
          job.retryCount++;
          job.status = "queued";
          job.progress = 0;
          this.queue.push(job.id);
          this.sortQueue();
          captureMessage("Extraction job retrying", { jobId: job.id, retryCount: job.retryCount });
        } else {
          job.status = "failed";
          job.error = result.error?.message || "Extraction failed";
          captureError(new Error(job.error), { jobId: job.id, url: job.url });
        }
      }
    } catch (error) {
      job.status = "failed";
      job.error = error instanceof Error ? error.message : "Unknown error";
      job.progress = 100;
      captureError(error, { jobId: job.id, url: job.url });
    } finally {
      job.completedAt = Date.now();
      this.activeJobs--;
      this.notifyCallbacks(job.id, job);
      
      // Continue processing queue
      this.startProcessing();
    }
  }

  private isRetryable(result: ExtractionResult): boolean {
    if (!result.success && result.error && "retryable" in result.error) {
      return result.error.retryable;
    }
    return false;
  }

  private notifyCallbacks(jobId: string, job: ExtractionJob) {
    const callbacks = this.callbacks.get(jobId);
    if (callbacks) {
      callbacks.forEach(cb => {
        try {
          cb(job);
        } catch (error) {
          captureError(error, { action: "job_callback", jobId });
        }
      });
    }
  }
}

export const backgroundJobProcessor = new BackgroundJobProcessor();

// Convenience function for creating extraction jobs
export const queueExtraction = (
  url: string,
  platform: SourcePlatform,
  priority: number = 0
): ExtractionJob => {
  return backgroundJobProcessor.createJob(url, platform, priority);
};

// Wait for job completion with timeout
export const waitForJobCompletion = async (
  jobId: string,
  timeoutMs: number = 120000
): Promise<ExtractionJob> => {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      unsubscribe();
      reject(new Error(`Job ${jobId} timed out after ${timeoutMs}ms`));
    }, timeoutMs);

    const unsubscribe = backgroundJobProcessor.subscribe(jobId, (job) => {
      if (job.status === "completed" || job.status === "failed") {
        clearTimeout(timeout);
        unsubscribe();
        resolve(job);
      }
    });
  });
};
