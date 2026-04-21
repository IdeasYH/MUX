import { describe, expect, it, vi } from 'vitest';
import { buildMuxProgram } from '../../src/cli/mux.js';

import { renderStatusCommand } from '../../src/node/commands/status.js';
import { renderResumeCommand } from '../../src/node/commands/resume.js';

describe('mux cli', () => {
  it('maps team to hybrid', async () => {
    const runHybrid = vi.fn(async (req: { mode: string; task?: string }) => ({
      status: 'completed' as const,
      runId: 'run-1',
      summary: req.task ?? '',
    }));

    const program = buildMuxProgram({
      runHybrid,
      runPlanner: async () => ({ status: 'completed', runId: 'plan-1', summary: 'ok' }),
      readStatus: async () => ({ status: 'completed', runId: 'run-1', summary: 'done' }),
      resumeRun: async () => ({ status: 'completed', runId: 'run-1', summary: 'done' }),
    });

    await program.parseAsync(['node', 'mux', 'team', 'ship search ui']);

    expect(runHybrid).toHaveBeenCalledWith({ mode: 'hybrid', task: 'ship search ui' });
  });

  it('runs planner with planner mode', async () => {
    const runPlanner = vi.fn(async (req: { mode: string; task?: string }) => ({
      status: 'completed' as const,
      runId: 'plan-1',
      summary: req.task ?? '',
    }));

    const program = buildMuxProgram({
      runHybrid: async () => ({ status: 'completed', runId: 'run-1', summary: 'done' }),
      runPlanner,
      readStatus: async () => ({ status: 'completed', runId: 'run-1', summary: 'done' }),
      resumeRun: async () => ({ status: 'completed', runId: 'run-1', summary: 'done' }),
    });

    await program.parseAsync(['node', 'mux', 'planner', 'split', 'tasks']);

    expect(runPlanner).toHaveBeenCalledWith({ mode: 'planner', task: 'split tasks' });
  });

  it('reads status with optional run id', async () => {
    const readStatus = vi.fn(async (_runId?: string) => ({
      status: 'completed' as const,
      runId: 'run-1',
      summary: 'done',
    }));

    const program = buildMuxProgram({
      runHybrid: async () => ({ status: 'completed', runId: 'run-1', summary: 'done' }),
      runPlanner: async () => ({ status: 'completed', runId: 'plan-1', summary: 'ok' }),
      readStatus,
      resumeRun: async () => ({ status: 'completed', runId: 'run-1', summary: 'done' }),
    });

    await program.parseAsync(['node', 'mux', 'status', 'run-7']);

    expect(readStatus).toHaveBeenCalledWith('run-7');
  });

  it('reads needs_human status payloads', async () => {
    const readStatus = vi.fn(async (_runId?: string) => ({
      status: 'needs_human' as const,
      runId: 'run-2',
      summary: 'paused',
      question: 'Pick API shape',
    }));

    const program = buildMuxProgram({
      runHybrid: async () => ({ status: 'completed', runId: 'run-1', summary: 'done' }),
      runPlanner: async () => ({ status: 'completed', runId: 'plan-1', summary: 'ok' }),
      readStatus,
      resumeRun: async () => ({ status: 'completed', runId: 'run-1', summary: 'done' }),
    });

    await program.parseAsync(['node', 'mux', 'status', 'run-2']);
    expect(readStatus).toHaveBeenCalledWith('run-2');
  });

  it('resumes a run by id', async () => {
    const resumeRun = vi.fn(async (runId: string) => ({
      status: 'completed' as const,
      runId,
      summary: 'done',
    }));

    const program = buildMuxProgram({
      runHybrid: async () => ({ status: 'completed', runId: 'run-1', summary: 'done' }),
      runPlanner: async () => ({ status: 'completed', runId: 'plan-1', summary: 'ok' }),
      readStatus: async () => ({ status: 'completed', runId: 'run-1', summary: 'done' }),
      resumeRun,
    });

    await program.parseAsync(['node', 'mux', 'resume', 'run-42']);

    expect(resumeRun).toHaveBeenCalledWith('run-42');
  });


  it('renders needs_human question for status output', async () => {
    const output = await renderStatusCommand(async () => ({
      status: 'needs_human',
      runId: 'run-2',
      summary: 'paused',
      question: 'Pick API shape',
    }));

    expect(output).toContain('[needs_human] paused');
    expect(output).toContain('question: Pick API shape');
  });

  it('renders resume output through the shared formatter', async () => {
    const output = await renderResumeCommand(async (runId: string) => ({
      status: 'completed',
      runId,
      summary: 'done',
    }), 'run-2');

    expect(output).toBe('[completed] done');
  });
});
