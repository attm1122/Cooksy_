import { mapImportJobToProgress } from "@/lib/import-jobs";
import { buildMockImportJob } from "@/mocks/import-job";
import { getSupportedPlatformFromUrl } from "@/utils/source-url";

describe("mapImportJobToProgress", () => {
  it("maps queued jobs to queued progress", () => {
    const job = buildMockImportJob("https://youtube.com/watch?v=cooksy");
    const progress = mapImportJobToProgress(job);

    expect(progress.stage).toBe("queued");
    expect(progress.jobId).toBe(job.id);
  });

  it("maps failed jobs to an error stage", () => {
    const job = {
      ...buildMockImportJob("https://instagram.com/reel/cooksy"),
      status: "failed" as const,
      errorMessage: "Source could not be parsed"
    };

    const progress = mapImportJobToProgress(job);
    expect(progress.stage).toBe("error");
    expect(progress.errorMessage).toBe("Source could not be parsed");
  });

  it("detects supported social source platforms", () => {
    expect(getSupportedPlatformFromUrl("https://youtu.be/cooksy123")).toBe("youtube");
    expect(getSupportedPlatformFromUrl("https://www.tiktok.com/@cooksy/video/123456789")).toBe("tiktok");
    expect(getSupportedPlatformFromUrl("https://www.instagram.com/reel/CooksyPasta/")).toBe("instagram");
    expect(getSupportedPlatformFromUrl("https://example.com/recipe")).toBeNull();
  });
});
