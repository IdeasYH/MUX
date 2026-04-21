#!/usr/bin/env node
import('../dist/cli/mux.js')
  .then((mod) => mod.main(process.argv))
  .catch((error) => {
    const message = error instanceof Error ? error.message : String(error);
    console.error(message);
    process.exitCode = 1;
  });
