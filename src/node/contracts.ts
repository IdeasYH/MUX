export type MuxMode = 'hybrid' | 'planner' | 'status' | 'resume';

export type MuxTerminalStatus = 'completed' | 'failed' | 'blocked' | 'needs_human';

export interface MuxPlannerTask {
  id: string;
  title: string;
  kind: 'impl' | 'fix' | 'verify';
}

export interface MuxPlannerPlan {
  task: string;
  tasks: MuxPlannerTask[];
  checkpoints: string[];
  blockers: string[];
  needs_human: string[];
}

export interface MuxRunRequest {
  mode: MuxMode;
  task?: string;
  runId?: string;
  cwd?: string;
  workerCount?: number;
}

export interface MuxRunResult {
  status: MuxTerminalStatus;
  runId: string;
  summary: string;
  question?: string;
  plan?: MuxPlannerPlan;
}
