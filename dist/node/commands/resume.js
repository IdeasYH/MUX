import { renderMuxResult } from '../status.js';
export async function renderResumeCommand(resumeRun, runId) {
    const result = await resumeRun(runId);
    return renderMuxResult(result);
}
