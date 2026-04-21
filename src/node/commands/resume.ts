import type { MuxRunResult } from '../contracts.js';
import { renderMuxResult } from '../status.js';

export async function renderResumeCommand(
  resumeRun: (runId: string) => Promise<MuxRunResult>,
  runId: string,
): Promise<string> {
  const result = await resumeRun(runId);
  return renderMuxResult(result);
}
