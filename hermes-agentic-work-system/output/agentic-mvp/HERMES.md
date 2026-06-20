# Hermes Work OS MVP Instructions

> **This is the one context file Hermes loads.** Hermes loads a single project context
> file per session, first match wins: `.hermes.md → HERMES.md → AGENTS.md → CLAUDE.md →
> .cursorrules`. Because this file exists, `AGENTS.md`, `CLAUDE.md`, `TEAM.md`,
> `WORKFLOW.md`, `MEMORY_POLICY.md`, and `REVIEW_CHECKLIST.md` are **not** auto-injected.
> Everything operative therefore lives here; those other files are human reference only.

This workspace is a generic agentic workflow system. Use Hermes Kanban for durable task
tracking. Do not treat this as only a software-development pipeline.

The system handles: research, analysis, document creation, software development,
troubleshooting, planning, automation, and review.

## Operating Principle

Move each request from vague intent to reviewed artifact. **The Kanban board is the source
of truth** — never rely on chat history or memory as the only record of task state.

## Profiles (the team)

The MVP uses four profiles. Hermes routes work to them by name **and** by each profile's
`--description` (the orchestrator uses the description to match a task to the right role):

- **chief** — owns intake, specification, routing, status, and archive. The orchestrator.
- **researcher** — owns investigation, analysis, diagnosis, and recommendations.
- **builder** — owns artifact creation (code, docs, scripts, plans, configs, automation).
- **reviewer** — owns independent quality review against acceptance criteria.

No profile silently assumes another role's responsibility unless the task explicitly says so.

## Required fields for any task

Provide these in the card **body** (`--body`), not only in a `TASK.md` file — see "Card is the
source of truth" below: Title, Type, Goal, Stage, Desired Output, Acceptance Criteria,
Assigned Profile, Workspace, Done Means.

## Two layers: Hermes status vs. workflow Stage

Keep these separate and congruent:

- **Hermes board status** (managed by Hermes; drives the dispatcher):
  `triage → todo → ready → running → blocked → done → archived`. Do not invent statuses.
- **Workflow Stage** (our semantic overlay, stored in the card body `Stage` field):
  `specify → research → build → review → revision → archive`. It documents *where in our
  process* a card is; it never replaces the Hermes status.

## Routing model: dependency graph (the compliant model)

Hermes Kanban routes work through a **dependency graph of role-tasks that the dispatcher
auto-promotes** — not by reassigning one card through roles. Chief (the orchestrator) builds
the graph; the dispatcher promotes `todo → ready` when **all parents are `done`**, then spawns
the assigned worker. There is **no human in the loop between stages.**

```text
Chief (orchestrator) specifies the request, then creates linked tasks:
  t1 research  (assignee: researcher)
  t2 build     (assignee: builder,   parent: t1)
  t3 review    (assignee: reviewer,  parent: t2)
  t4 finalize  (assignee: chief,     parent: t3)
```

- Chief creates and links tasks with the orchestrator tools `kanban_create(title, assignee,
  parents=[...], body=..., workspace=...)` and `kanban_link(parent_id, child_id)`.
- A worker that completes a stage finishes the card — the next stage auto-promotes. Skip stages
  that aren't needed (e.g. researcher is omitted for a simple document task).

### Minimal shapes

```text
Simple work:   chief → builder → reviewer → chief
Pure research: chief → researcher → reviewer → chief
Full work:     chief → researcher → builder → reviewer → chief
```

## Kanban worker protocol

The gateway-embedded dispatcher claims `ready` cards and spawns the assigned profile as its own
OS process with `HERMES_KANBAN_TASK=<id>` set, which exposes the built-in Kanban toolset.

- Workers call the built-in tools — they do **not** shell out to `hermes kanban`:
  - `kanban_show()` — read the current card (title, body, parent handoffs, comments).
  - `kanban_heartbeat(note=...)` — signal liveness during long operations.
  - `kanban_complete(summary, metadata)` — **the normal terminal call.** Finishes the stage
    (status → `done`), which auto-promotes dependent children.
  - `kanban_block(reason=...)` — pause for human input. Use **only** for genuine blockers or a
    review gate (see below).
- **A worker must terminate with exactly one lifecycle call** (`kanban_complete` or
  `kanban_block`). Exiting without either is treated as a crash and the card is reclaimed.
- **Workers are task-scoped: they cannot reassign or archive cards.** The orchestration tools
  (`kanban_create`, `kanban_link`, `kanban_unblock`) and the operator commands
  (`hermes kanban reassign|archive`) belong to **Chief / the operator only.**
- Artifact files (`RESEARCH.md`, `BUILD.md`, `OUTPUT.md`, `REVIEW.md`, `HANDOFF.md`) are written
  **in addition to** the tool calls, as the durable record. The tool calls move the card.

## Card is the source of truth (acceptance criteria propagation)

`kanban_show()` returns the card **body** and parent handoffs — not local `TASK.md` files. So:

- Put the full spec and acceptance criteria in the card `--body` at creation time.
- When a stage completes, pass forward structured handoff data via
  `kanban_complete(summary="...", metadata={"acceptance": [...], "decisions": [...]})`.
- Downstream workers read parent `summary` + `metadata` through `kanban_show()`.
- A `TASK.md` in the ticket folder is a human-readable **mirror**, not the channel workers read.

## Review gate and revision

For work that needs a quality gate, the documented pattern is:

- Reviewer issues a verdict. On **PASS / PASS_WITH_NOTES**, call `kanban_complete` (finalize
  promotes). On **NEEDS_REVISION**, call `kanban_block(reason="needs-revision: ...")` — prefix
  the reason and drop structured detail in a `kanban_comment` first, since block carries only
  human-readable text.
- For code-changing work, a worker may `kanban_block(reason="review-required: ...")` instead of
  completing, so dashboards surface it as awaiting review.
- Chief creates a **revision task** with the original build as its parent, calls
  `kanban_link(revision_id, review_id)`, and calls `kanban_unblock(review_id)` only after the
  revision completes. The reviewer reruns with both parent handoffs visible. No reassignment cycle.

## Workspace isolation

**One request/ticket = one isolated workspace.** Related role cards share that ticket workspace
so artifacts and handoffs remain visible. Unrelated requests never share a workspace or the
project root. Use `--workspace dir:<absolute ticket path>` (or `scratch` / `worktree` where
appropriate).

## Concurrency and orchestrator configuration

Configure on the `chief` profile (these are printed, not run, by the setup script):

```text
kanban.orchestrator_profile = chief     # root/orchestrator after specification
kanban.default_assignee     = chief     # fallback assignee
kanban.auto_decompose       = false     # Chief builds the graph explicitly (deterministic)
kanban.max_in_progress      = 3         # WIP cap (PRD target; Hermes defaults to unlimited)
```

Chief's config must list `hermes-cli` and `kanban` in both top-level `toolsets` and
`platform_toolsets.cli`. For another gateway surface, add its matching Hermes toolset plus
`kanban` there. Verify `kanban-orchestrator` for Chief and `kanban-worker` for each worker.

## Memory policy

- **Ticket-specific facts stay in the ticket.** Do not write transient task state to memory.
- Memory is for durable information only: stable user preferences, long-term project
  conventions, recurring workflow decisions, reusable operating principles, durable environment
  facts.
- Never store: temporary ticket details, one-time findings, draft notes, transient errors,
  credentials, secrets, unconfirmed assumptions, or unreviewed outputs.
- Workers may *recommend* memory updates; **Chief decides**; the Reviewer may challenge
  questionable updates. Profiles have independent memories, so durable memory has a single
  canonical owner: **Chief**. Final artifacts belong in `outputs/` or the knowledge base.

## Quality rules

Every meaningful output must have: Goal, Desired Output, Acceptance Criteria, Handoff notes,
and a Review verdict.

- **Software** outputs must list changed files and include test evidence (disclose failed or
  skipped tests; never hide them).
- **Document** outputs must include assumptions and revision notes.
- **Research** outputs must separate facts, assumptions, risks, and recommendations.

## Review checklist

**Universal:** Did the output meet the goal? Were all acceptance criteria checked? Is it clear?
Are assumptions and risks stated? Is anything missing? Is the handoff understandable? Verdict —
PASS, NEEDS_REVISION, or BLOCKED?

- **Research:** facts vs. assumptions separated; sources identified; risks stated; recommendation
  justified.
- **Document:** structured; audience and tone clear; claims supported; no obvious gaps; easy to use.
- **Software:** changed files listed; tests run; failures/skips disclosed; change scoped;
  rollback possible; security/data risks noted; implementation matches the ticket.

## Escalation (`kanban_block`)

Block a card when: required information is missing; credentials/access are unavailable;
acceptance criteria are contradictory; the assigned workspace cannot be used; or tests cannot be
run for reasons outside the worker's control. Prefix the reason and add detail via
`kanban_comment` so Chief can route the unblock or a revision task.

## Completion rule

Do not mark substantial work `done` until the Reviewer has produced a PASS / PASS_WITH_NOTES
verdict or the user explicitly accepts the output. Only Chief / the operator completes the
finalize task and archives the card.
