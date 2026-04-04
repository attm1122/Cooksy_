import { mapImportJobToProgress } from "@/lib/import-jobs";
import { buildMockImportJob } from "@/mocks/import-job";

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
});
