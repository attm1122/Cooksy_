import { processJobToTerminal } from "../supabase/functions/_shared/background-jobs";

describe("background job processor", () => {
  it("advances a non-terminal job until completion", async () => {
    const fetchJob = jest
      .fn()
      .mockResolvedValueOnce({ status: "queued", progress: 0.08 })
      .mockResolvedValueOnce({ status: "completed", progress: 1 });
    const advanceJob = jest.fn(async () => ({ status: "completed", progress: 1 }));

    const result = await processJobToTerminal({
      fetchJob,
      advanceJob,
      isTerminalJob: (job) => job.status === "completed" || job.status === "failed",
      maxAdvances: 4
    });

    expect(advanceJob).toHaveBeenCalledTimes(1);
    expect(result.status).toBe("completed");
  });

  it("returns immediately for terminal jobs", async () => {
    const fetchJob = jest.fn(async () => ({ status: "failed", progress: 1 }));
    const advanceJob = jest.fn();

    const result = await processJobToTerminal({
      fetchJob,
      advanceJob,
      isTerminalJob: (job) => job.status === "completed" || job.status === "failed"
    });

    expect(advanceJob).not.toHaveBeenCalled();
    expect(result.status).toBe("failed");
  });

  it("re-fetches the latest job when the advance budget is exhausted", async () => {
    const fetchJob = jest
      .fn()
      .mockResolvedValueOnce({ status: "queued", progress: 0.08 })
      .mockResolvedValueOnce({ status: "extracting", progress: 0.28 });
    const advanceJob = jest.fn(async () => ({ status: "extracting", progress: 0.28 }));

    const result = await processJobToTerminal({
      fetchJob,
      advanceJob,
      isTerminalJob: (job) => job.status === "completed" || job.status === "failed",
      maxAdvances: 1
    });

    expect(fetchJob).toHaveBeenCalledTimes(2);
    expect(result.status).toBe("extracting");
  });
});
