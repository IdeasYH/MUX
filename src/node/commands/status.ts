import type { MuxRunResult } from '../contracts.js';
import { renderMuxResult } from '../status.js';

export async function renderStatusCommand(
  readStatus: (runId?: string) => Promise<MuxRunResult>,
  runId?: string,
): Promise<string> {
  const result = await readStatus(runId);
  return renderMuxResult(result);
}
