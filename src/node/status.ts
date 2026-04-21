import type { MuxRunResult } from './contracts.js';

export function renderMuxResult(result: MuxRunResult): string {
  if (result.status === 'needs_human' && result.question) {
    return `[${result.status}] ${result.summary}\nquestion: ${result.question}`;
  }

  return `[${result.status}] ${result.summary}`;
}
