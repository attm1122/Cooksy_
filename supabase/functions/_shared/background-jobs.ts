export type BackgroundJobProcessorOptions<TJob> = {
  fetchJob: () => Promise<TJob>;
  advanceJob: (job: TJob) => Promise<TJob>;
  isTerminalJob: (job: TJob) => boolean;
  maxAdvances?: number;
};

type WaitUntilRuntime = {
  EdgeRuntime?: {
    waitUntil?: (promise: Promise<unknown>) => void;
  };
};

export const processJobToTerminal = async <TJob>({
  fetchJob,
  advanceJob,
  isTerminalJob,
  maxAdvances = 4
}: BackgroundJobProcessorOptions<TJob>): Promise<TJob> => {
  let job = await fetchJob();
  let advances = 0;

  while (!isTerminalJob(job) && advances < maxAdvances) {
    const nextJob = await advanceJob(job);
    advances += 1;

    if (isTerminalJob(nextJob)) {
      return nextJob;
    }

    job = nextJob;
  }

  if (isTerminalJob(job)) {
    return job;
  }

  return fetchJob();
};

export const scheduleBackgroundJob = (run: () => Promise<unknown>) => {
  const task = run().catch((error) => {
    console.error("Cooksy background job failed", error);
  });

  const runtime = globalThis as WaitUntilRuntime;
  runtime.EdgeRuntime?.waitUntil?.(task);

  return task;
};
