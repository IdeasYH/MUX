import { constants } from 'node:fs';
import { access, stat } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
export async function resolveRuntimeEnvironment(cwd = process.cwd()) {
    const workingDirectory = resolve(cwd);
    const moduleDir = dirname(fileURLToPath(import.meta.url));
    const runtimeEntrypoint = resolve(moduleDir, '..', '..', 'runtime', 'mux_runtime', '__main__.py');
    const pythonBin = process.env.MUX_PYTHON?.trim() || 'python3';
    await ensureReadableDirectory(workingDirectory);
    await ensureReadableFile(runtimeEntrypoint);
    return {
        pythonBin,
        runtimeEntrypoint,
        workingDirectory,
    };
}
async function ensureReadableDirectory(path) {
    const details = await stat(path).catch(() => {
        throw new Error(`MUX working directory does not exist: ${path}`);
    });
    if (!details.isDirectory()) {
        throw new Error(`MUX working directory is not a directory: ${path}`);
    }
    await access(path, constants.R_OK);
}
async function ensureReadableFile(path) {
    const details = await stat(path).catch(() => {
        throw new Error(`MUX runtime entrypoint is missing: ${path}`);
    });
    if (!details.isFile()) {
        throw new Error(`MUX runtime entrypoint is not a file: ${path}`);
    }
    await access(path, constants.R_OK);
}
