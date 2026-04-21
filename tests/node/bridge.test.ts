import { beforeEach, describe, expect, it, vi } from 'vitest';

const spawnMock = vi.fn();
const resolveRuntimeEnvironmentMock = vi.fn();

vi.mock('node:child_process', () => ({
  spawn: (...args: unknown[]) => spawnMock(...args),
}));

vi.mock('../../src/node/env.js', () => ({
  resolveRuntimeEnvironment: (...args: unknown[]) => resolveRuntimeEnvironmentMock(...args),
}));

describe('runMuxRuntime', () => {
  beforeEach(() => {
    vi.resetModules();
    spawnMock.mockReset();
    resolveRuntimeEnvironmentMock.mockReset();
  });

  it('returns parsed runtime JSON', async () => {
    const stdoutHandlers: Array<(chunk: string) => void> = [];
    const stderrHandlers: Array<(chunk: string) => void> = [];
    const closeHandlers: Array<(code: number) => void> = [];
    const stdinWrite = vi.fn();
    const stdinEnd = vi.fn();

    resolveRuntimeEnvironmentMock.mockResolvedValue({
      pythonBin: 'python3',
      runtimeEntrypoint: '/tmp/runtime/__main__.py',
    });

    spawnMock.mockImplementation(() => ({
      stdin: { write: stdinWrite, end: stdinEnd },
      stdout: { on: (event: string, cb: (chunk: string) => void) => { if (event === 'data') stdoutHandlers.push(cb); } },
      stderr: { on: (event: string, cb: (chunk: string) => void) => { if (event === 'data') stderrHandlers.push(cb); } },
      on: (event: string, cb: (code: number) => void) => { if (event === 'close') closeHandlers.push(cb); },
    }));

    const { runMuxRuntime } = await import('../../src/node/bridge.js');
    const pending = runMuxRuntime({ mode: 'hybrid', task: 'ship feature' });

    await Promise.resolve();
    stdoutHandlers.forEach(handler => handler(JSON.stringify({
      status: 'completed',
      runId: 'run-1',
      summary: 'ship feature',
    })));
    closeHandlers.forEach(handler => handler(0));

    await expect(pending).resolves.toMatchObject({
      status: 'completed',
      runId: 'run-1',
      summary: 'ship feature',
    });

    expect(spawnMock).toHaveBeenCalledWith('python3', ['/tmp/runtime/__main__.py'], { stdio: 'pipe' });
    expect(stdinWrite).toHaveBeenCalledWith(JSON.stringify({ mode: 'hybrid', task: 'ship feature' }));
    expect(stdinEnd).toHaveBeenCalled();
    expect(stderrHandlers).toHaveLength(1);
  });

  it('wraps non-zero exits with stderr output', async () => {
    const closeHandlers: Array<(code: number) => void> = [];
    const stderrHandlers: Array<(chunk: string) => void> = [];

    resolveRuntimeEnvironmentMock.mockResolvedValue({
      pythonBin: 'python3',
      runtimeEntrypoint: '/tmp/runtime/__main__.py',
    });

    spawnMock.mockImplementation(() => ({
      stdin: { write: vi.fn(), end: vi.fn() },
      stdout: { on: vi.fn() },
      stderr: { on: (event: string, cb: (chunk: string) => void) => { if (event === 'data') stderrHandlers.push(cb); } },
      on: (event: string, cb: (code: number) => void) => { if (event === 'close') closeHandlers.push(cb); },
    }));

    const { runMuxRuntime } = await import('../../src/node/bridge.js');
    const pending = runMuxRuntime({ mode: 'planner', task: 'split tasks' });

    await Promise.resolve();
    stderrHandlers.forEach(handler => handler('runtime failed'));
    closeHandlers.forEach(handler => handler(1));

    await expect(pending).rejects.toThrow('runtime failed');
  });
});
