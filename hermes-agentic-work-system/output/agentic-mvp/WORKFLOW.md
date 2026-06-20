# Workflow

> **Human reference only — not auto-loaded.** Hermes loads a single context file per session
> (`.hermes.md → HERMES.md → AGENTS.md → CLAUDE.md → .cursorrules`), and `HERMES.md` wins. The
> operative copy of everything below lives in `HERMES.md`; this file is the readable long form.

## Two Layers: Hermes Status vs. Workflow Stage

Keep these separate and congruent:

- **Hermes board status** (managed by Hermes, drives the dispatcher):
  `triage → todo → ready → running → blocked → done → archived`.
- **Workflow stage** (our semantic overlay, stored in the ticket body `Stage`
  field): the lifecycle below. The stage is documentation of *where in our
  process* a card is; it never replaces the Hermes status.

## Universal Lifecycle (workflow stage)

```text
Capture → Specify → Research → Build → Review → Revise → Done → Archive
```

## Routing on the Board (dependency graph)

Chief (the orchestrator) builds a graph of linked role-tasks. The dispatcher promotes each
task `todo → ready` when **all of its parents are `done`**, then spawns the assigned worker.
Stages advance automatically — there is no human in the loop between them:

```text
chief specifies, then creates the linked graph:

  t1 research  (researcher)                 --complete--> done
       │ parent
  t2 build     (builder)   <-- auto-ready ---┘           --complete--> done
       │ parent
  t3 review    (reviewer)  <-- auto-ready ---┘           --complete (PASS)--> done
       │ parent                                          --block "needs-revision:" --> chief
  t4 finalize  (chief)     <-- auto-ready ---┘           --complete--> operator archives
```

- Each worker terminates its own card with `kanban_complete(summary, metadata)`; the metadata
  (acceptance criteria, decisions) is read downstream via `kanban_show()`.
- Workers cannot reassign or archive cards. Chief creates/links tasks (`kanban_create`,
  `kanban_link`) and is the only role that finalizes; the operator archives.
- NEEDS_REVISION → reviewer comments and blocks the review. Chief creates a revision task with
  the original build as parent, links the revision as another parent of the blocked review, and
  unblocks that review after revision completion. Reviewer reruns; no cards are reassigned.
- Skip stages that aren't needed (researcher is omitted for a simple document task).

All related role cards use one ticket-isolated workspace. Unrelated requests never share one.

## Stage Definitions

### Capture

Raw request exists.

Owner: chief

### Specify

Request is converted into a clear ticket.

Owner: chief

Required fields:

- Type
- Goal
- Desired Output
- Acceptance Criteria
- Workspace
- Done Means

### Research

Facts, options, risks, or diagnosis are gathered.

Owner: researcher

Output:

- RESEARCH.md

### Build

The requested artifact is created.

Owner: builder

Output:

- BUILD.md
- OUTPUT.md
- HANDOFF.md

### Review

Artifact is checked against acceptance criteria.

Owner: reviewer

Output:

- REVIEW.md

### Revision

Builder or Researcher corrects issues found by Reviewer.

Owner: chief assigns

### Done

Work is accepted.

Owner: chief

### Archive

Final output and durable lessons are stored.

Owner: chief

## Minimal Flow

For simple work:

```text
chief → builder → reviewer → chief
```

For pure research:

```text
chief → researcher → reviewer → chief
```

For complex work:

```text
chief → researcher → builder → reviewer → chief
```
