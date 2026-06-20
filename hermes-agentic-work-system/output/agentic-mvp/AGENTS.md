# Agentic Hermes MVP Project Context

> **Human reference only — not auto-loaded.** Hermes loads one context file per session and
> `HERMES.md` wins (`.hermes.md → HERMES.md → AGENTS.md → CLAUDE.md → .cursorrules`). The
> operative instructions are consolidated in `HERMES.md`; this file is kept for readability.

This workspace implements Jason's Agentic Hermes Work OS MVP.

The system uses four Hermes profiles:

- chief
- researcher
- builder
- reviewer

## Core Rule

The Kanban board is the source of truth.

Do not rely on chat history or memory as the only source of ticket state.

## Workspace Rules

Each ticket gets its own folder under:

```text
tickets/TICKET-xxxx/
```

Each request/ticket gets one isolated workspace, shared by its related role cards, under:

```text
workspaces/TICKET-xxxx/
```

Outputs go under:

```text
outputs/
```

Templates go under:

```text
templates/
```

## Ticket Files

A normal ticket workspace may contain:

```text
TASK.md
RESEARCH.md
BUILD.md
REVIEW.md
HANDOFF.md
OUTPUT.md
DECISIONS.md
```

## Role Boundaries

Chief owns the board.
Researcher owns understanding.
Builder owns creation.
Reviewer owns quality.

No profile should silently assume another role's responsibility unless the ticket explicitly says so.

## Ticket State

Use Hermes Kanban status for execution state.

Use the ticket body field `Stage` for workflow stage:

```text
specify
research
build
review
revision
archive
```

## Memory Rules

Ticket-specific facts stay in the ticket.
Durable facts may be recommended for memory.
Repeatable procedures should become skills or documented workflows.
Final artifacts belong in outputs or the knowledge base.

## Quality Rules

Every meaningful output must have:

- Goal
- Desired output
- Acceptance criteria
- Handoff notes
- Review verdict

Software outputs must include test evidence when tests are available.

Document outputs must include assumptions and revision notes.

Research outputs must separate facts, assumptions, risks, and recommendations.

## Escalation

Block the ticket when:

- required information is missing
- credentials/access are unavailable
- acceptance criteria are contradictory
- the assigned workspace cannot be used
- tests cannot be run for reasons outside the worker's control
