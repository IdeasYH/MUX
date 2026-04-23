# OMX Lightweight Routing Plan

Status: planned
Date: 2026-04-23

## Goal

Keep natural-language OMX activation only for `team`, `ralph`, and `ask`.
Require explicit invocation for all other OMX workflows/skills.
Reduce token overhead and reduce conflicts with other prompt-routing plugins.

## Plan Artifact

- Primary execution plan: `.omx/plans/omx-lightweight-routing-2026-04-23.md`

## Phases

1. Inspect current OMX routing, triage, hook, and MCP configuration.
2. Disable non-essential automatic routing while preserving `team` / `ralph` / `ask`.
3. Reduce always-on OMX context sources that are not needed for the retained workflows.
4. Verify that explicit workflows still work and ordinary chat no longer gets broad OMX intervention.

## Constraints

- Preserve `team` functionality, including planner-driven team execution handoff.
- Preserve `ralph` functionality.
- Preserve `ask` functionality.
- Prefer minimal, reversible changes before any hard module removal.

## Success Criteria

- Natural-language routing remains available for `team`, `ralph`, and `ask`.
- Other OMX workflows do not auto-activate from ordinary chat.
- Triage/advisory routing is disabled or narrowed enough to stop broad prompt injection.
- Non-essential always-on MCP surfaces are disabled where safe.
- The resulting configuration is still usable for explicit OMX workflows.
