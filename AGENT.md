# Session Initialization and Hand-off Rules

## Session Startup
At the start of every session, you must read the following files before performing any tasks or modifications:
1. Read `/docs/ai/00_START_HERE.md` to load the current system rules and guidelines.
2. Read `/docs/ai/PROGRESS.md` to load the active workspace context and objectives.

*Strictly follow the rules outlined inside `00_START_HERE.md` at all times.*
*Do not read other markdown files in the `/docs/ai/` directory unless they become explicitly relevant to the user request.*

## Session Teardown
Before ending any session or concluding a task checklist, you must accurately update the following logs with your progress and hand-off details:
1. Update `/docs/ai/PROGRESS.md` (what is finished, what is currently being worked on, and next immediate steps).
2. Update `/docs/ai/HANDOFF_LOG.md` (what changed, key technical decisions, or issues encountered for the next session).
