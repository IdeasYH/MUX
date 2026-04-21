import { renderMuxResult } from '../status.js';
export async function renderStatusCommand(readStatus, runId) {
    const result = await readStatus(runId);
    return renderMuxResult(result);
}
