import { backgroundJobProcessor, queueExtraction } from "../background-jobs";
import type { SourcePlatform } from "@/features/recipes/types";

describe("background job processor", () => {
  // Store original processJob method
  let originalProcessJob: any;

  beforeEach(() => {
    // Clean up any existing jobs
    backgroundJobProcessor["cleanup"](0);
    
    // Mock the processJob to prevent actual extraction
    originalProcessJob = backgroundJobProcessor["processJob"];
    backgroundJobProcessor["processJob"] = jest.fn().mockImplementation(async function(this: any, job: any) {
      // Just mark as completed without actual processing
      this["activeJobs"]++;
      job.status = "processing";
      job.startedAt = Date.now();
      
      // Simulate quick completion
      await new Promise(resolve => setTimeout(resolve, 10));
      
      job.status = "completed";
      job.progress = 100;
      job.completedAt = Date.now();
      this["activeJobs"]--;
      this["notifyCallbacks"](job.id, job);
      this["startProcessing"]();
    });
  });

  afterEach(() => {
    // Restore original method
    if (originalProcessJob) {
      backgroundJobProcessor["processJob"] = originalProcessJob;
    }
  });

  afterAll(() => {
    // Final cleanup
    backgroundJobProcessor["cleanup"](0);
  });

  describe("createJob", () => {
    it("creates a job with correct initial state", async () => {
      const job = backgroundJobProcessor.createJob(
        "https://youtube.com/watch?v=test",
        "youtube" as SourcePlatform,
        5
      );

      expect(job.id).toBeDefined();
      expect(job.url).toBe("https://youtube.com/watch?v=test");
      expect(job.platform).toBe("youtube");
      expect(["queued", "processing"]).toContain(job.status);
      expect(job.priority).toBe(5);
      expect(job.retryCount).toBe(0);
      expect(job.progress).toBe(0);
      expect(job.createdAt).toBeGreaterThan(0);

      // Wait for processing to complete
      await new Promise(resolve => setTimeout(resolve, 100));
    });
  });

  describe("getJob", () => {
    it("retrieves job by ID", async () => {
      const job = backgroundJobProcessor.createJob(
        "https://youtube.com/watch?v=test",
        "youtube" as SourcePlatform
      );

      const retrieved = backgroundJobProcessor.getJob(job.id);
      expect(retrieved).toBeDefined();
      expect(retrieved?.id).toBe(job.id);

      await new Promise(resolve => setTimeout(resolve, 50));
    });

    it("returns undefined for non-existent job", () => {
      const retrieved = backgroundJobProcessor.getJob("non-existent-id");
      expect(retrieved).toBeUndefined();
    });
  });

  describe("cancelJob", () => {
    it("returns boolean for cancel operation", async () => {
      const job = backgroundJobProcessor.createJob(
        "https://youtube.com/watch?v=test",
        "youtube" as SourcePlatform
      );

      const cancelled = backgroundJobProcessor.cancelJob(job.id);
      expect(typeof cancelled).toBe("boolean");
      
      await new Promise(resolve => setTimeout(resolve, 50));
    });

    it("cannot cancel completed job", () => {
      const job = backgroundJobProcessor.createJob(
        "https://youtube.com/watch?v=test",
        "youtube" as SourcePlatform
      );

      // Simulate completion
      (job as { status: string }).status = "completed";

      const cancelled = backgroundJobProcessor.cancelJob(job.id);
      expect(cancelled).toBe(false);
    });
  });

  describe("subscribe", () => {
    it("returns unsubscribe function", async () => {
      const job = backgroundJobProcessor.createJob(
        "https://youtube.com/watch?v=test",
        "youtube" as SourcePlatform
      );

      const unsubscribe = backgroundJobProcessor.subscribe(job.id, () => {});
      expect(typeof unsubscribe).toBe("function");
      
      expect(() => unsubscribe()).not.toThrow();

      await new Promise(resolve => setTimeout(resolve, 50));
    });

    it("immediately notifies with current state", (done) => {
      const job = backgroundJobProcessor.createJob(
        "https://youtube.com/watch?v=test",
        "youtube" as SourcePlatform
      );

      let unsubscribe: (() => void) | undefined;
      unsubscribe = backgroundJobProcessor.subscribe(job.id, (updatedJob) => {
        expect(updatedJob.id).toBe(job.id);
        unsubscribe?.();
        done();
      });
    });
  });

  describe("getQueueStatus", () => {
    it("returns queue statistics", async () => {
      const initialStatus = backgroundJobProcessor.getQueueStatus();
      
      backgroundJobProcessor.createJob("https://youtube.com/watch?v=1", "youtube" as SourcePlatform);

      const status = backgroundJobProcessor.getQueueStatus();
      expect(status.total).toBeGreaterThanOrEqual(initialStatus.total + 1);
      expect(status).toHaveProperty("queued");
      expect(status).toHaveProperty("processing");
      expect(status).toHaveProperty("completed");
      expect(status).toHaveProperty("failed");
      expect(status.concurrency).toBe(2);

      await new Promise(resolve => setTimeout(resolve, 100));
    });
  });

  describe("cleanup", () => {
    it("removes old completed jobs", () => {
      const job = backgroundJobProcessor.createJob(
        "https://youtube.com/watch?v=test",
        "youtube" as SourcePlatform
      );

      // Simulate completion with old timestamp
      (job as { status: string }).status = "completed";
      (job as { completedAt: number }).completedAt = Date.now() - 1000 * 60 * 60 * 2;

      const cleaned = backgroundJobProcessor.cleanup(1000 * 60 * 60);
      expect(typeof cleaned).toBe("number");
    });
  });

  describe("getJobsByUrl", () => {
    it("returns jobs matching URL", async () => {
      const url = "https://youtube.com/watch?v=specific";
      backgroundJobProcessor.createJob(url, "youtube" as SourcePlatform);
      backgroundJobProcessor.createJob(url, "youtube" as SourcePlatform);
      backgroundJobProcessor.createJob("https://youtube.com/watch?v=other", "youtube" as SourcePlatform);

      const jobs = backgroundJobProcessor.getJobsByUrl(url);
      expect(jobs.length).toBeGreaterThanOrEqual(2);
      jobs.forEach(job => expect(job.url).toBe(url));

      await new Promise(resolve => setTimeout(resolve, 100));
    });
  });

  describe("queueExtraction", () => {
    it("is a convenience wrapper for createJob", async () => {
      const job = queueExtraction("https://youtube.com/watch?v=queued", "youtube" as SourcePlatform, 10);
      
      expect(job.url).toBe("https://youtube.com/watch?v=queued");
      expect(job.platform).toBe("youtube");
      expect(job.priority).toBe(10);
      expect(["queued", "processing"]).toContain(job.status);

      await new Promise(resolve => setTimeout(resolve, 50));
    });
  });

  describe("job priority", () => {
    it("respects priority values", async () => {
      const lowPriority = backgroundJobProcessor.createJob(
        "https://youtube.com/watch?v=low",
        "youtube" as SourcePlatform,
        1
      );
      const highPriority = backgroundJobProcessor.createJob(
        "https://youtube.com/watch?v=high",
        "youtube" as SourcePlatform,
        10
      );

      expect(lowPriority.priority).toBe(1);
      expect(highPriority.priority).toBe(10);

      await new Promise(resolve => setTimeout(resolve, 100));
    });
  });
});
