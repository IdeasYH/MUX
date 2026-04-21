export function renderMuxResult(result) {
    if (result.status === 'needs_human' && result.question) {
        return `[${result.status}] ${result.summary}\nquestion: ${result.question}`;
    }
    return `[${result.status}] ${result.summary}`;
}
