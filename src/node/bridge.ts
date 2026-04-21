import { spawn } from 'node:child_process';
import type { ChildProcessWithoutNullStreams, SpawnOptionsWithoutStdio } from 'node:child_process';
import type { MuxRunRequest, MuxRunResult } from './contracts.js';
import { resolveRuntimeEnvironment } from './env.js';

export async function runMuxRuntime(request: MuxRunRequest): Promise<MuxRunResult> {
  const environment = await resolveRuntimeEnvironment(request.cwd);

  return await new Promise((resolve, reject) => {
    const child = spawn(environment.pythonBin, [environment.runtimeEntrypoint], {
      stdio: 'pipe',
      cwd: environment.workingDirectory,
    });

    let stdout = '';
    let stderr = '';
    let settled = false;

    const fail = (error: Error) => {
      if (settled) {
        return;
      }

      settled = true;
      reject(error);
    };

    const succeed = (result: MuxRunResult) => {
      if (settled) {
        return;
      }

      settled = true;
      resolve(result);
    };

    child.stdout.on('data', (chunk) => {
      stdout += String(chunk);
    });

    child.stderr.on('data', (chunk) => {
      stderr += String(chunk);
    });

    child.on('error', (error) => {
      fail(new Error(`Failed to start MUX runtime: ${error.message}`));
    });

    child.on('close', (code) => {
      if (code !== 0) {
        const message = stderr.trim() || `MUX runtime exited with code ${code ?? 'unknown'}`;
        fail(new Error(message));
        return;
      }

      try {
        succeed(JSON.parse(stdout) as MuxRunResult);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        fail(new Error(`MUX runtime returned invalid JSON: ${message}`));
      }
    });

    child.stdin.write(JSON.stringify(request));
    child.stdin.end();
  });
}
