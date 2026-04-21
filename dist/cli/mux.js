#!/usr/bin/env node
import { Command } from 'commander';
import { fileURLToPath } from 'node:url';
import { runMuxRuntime } from '../node/bridge.js';
import { renderResumeCommand } from '../node/commands/resume.js';
import { renderStatusCommand } from '../node/commands/status.js';
import { renderMuxResult } from '../node/status.js';
export function createMuxCliHandlers() {
    return {
        runHybrid: (req) => runMuxRuntime({ ...req, cwd: req.cwd ?? process.cwd() }),
        runPlanner: (req) => runMuxRuntime({ ...req, cwd: req.cwd ?? process.cwd() }),
        readStatus: (runId) => runMuxRuntime({ mode: 'status', runId, cwd: process.cwd() }),
        resumeRun: (runId) => runMuxRuntime({ mode: 'resume', runId, cwd: process.cwd() }),
    };
}
export function buildMuxProgram(handlers) {
    const program = new Command();
    program.name('mux');
    program
        .command('hybrid <task...>')
        .description('Run the MUX hybrid loop')
        .action(async (task) => {
        const result = await handlers.runHybrid({ mode: 'hybrid', task: task.join(' ') });
        console.log(renderMuxResult(result));
    });
    program
        .command('team <task...>')
        .description('Alias for hybrid')
        .action(async (task) => {
        const result = await handlers.runHybrid({ mode: 'hybrid', task: task.join(' ') });
        console.log(renderMuxResult(result));
    });
    program
        .command('planner <task...>')
        .description('Show the minimal planner split for a task')
        .action(async (task) => {
        const result = await handlers.runPlanner({ mode: 'planner', task: task.join(' ') });
        console.log(renderMuxResult(result));
        if (result.plan) {
            console.log(JSON.stringify(result.plan, null, 2));
        }
    });
    program
        .command('status [runId]')
        .description('Read the status of a run')
        .action(async (runId) => {
        console.log(await renderStatusCommand(handlers.readStatus, runId));
    });
    program
        .command('resume <runId>')
        .description('Resume a paused run')
        .action(async (runId) => {
        console.log(await renderResumeCommand(handlers.resumeRun, runId));
    });
    return program;
}
export async function main(argv = process.argv) {
    await buildMuxProgram(createMuxCliHandlers()).parseAsync(argv);
}
const isDirectExecution = process.argv[1] != null
    && fileURLToPath(import.meta.url) === process.argv[1];
if (isDirectExecution) {
    main().catch((error) => {
        const message = error instanceof Error ? error.message : String(error);
        console.error(message);
        process.exitCode = 1;
    });
}
