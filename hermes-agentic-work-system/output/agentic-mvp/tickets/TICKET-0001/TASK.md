# Ticket (human mirror)

> **This file is a human-readable mirror, not the channel workers read.** `kanban_show()`
> returns the **card body** (`--body`) and parent handoffs — not this file. Put the spec and
> acceptance criteria in the card `--body` at creation, and pass handoffs forward via
> `kanban_complete(summary, metadata)`. Keep this file in sync for humans only.

## Title

Test the Agentic Hermes MVP workflow with a simple document task

## Type

document

## Goal

Prove that a request flows through the dependency-graph pipeline and produces a reviewed
artifact, exercising ticket-isolated workspaces, `kanban_complete` handoffs, and the review gate
end to end.

## Background

This is the first validation request for the MVP. It confirms profiles, board, orchestrator
config, and the auto-promotion pipeline work together before any real work is loaded.

## Desired Output

A short Markdown document (`outputs/hello-hermes.md`, ~1 page) summarizing what the Agentic
Hermes MVP is and how a request flows through it.

## Acceptance Criteria (these go in each card's `--body`)

- [ ] Document explains the four profiles and their responsibilities.
- [ ] Document shows the dependency-graph pipeline (research → build → review → finalize).
- [ ] Document is clear, structured, and free of placeholder text.
- [ ] Reviewer records a PASS / PASS_WITH_NOTES verdict (in `REVIEW.md` and `kanban_complete`).

## Task graph (researcher skipped for a simple doc)

```text
build    (assignee: builder)                 -> kanban_complete(summary, metadata)
review   (assignee: reviewer, parent: build) -> PASS: kanban_complete | NEEDS_REVISION: kanban_block
finalize (assignee: chief,    parent: review)-> chief closes; operator archives
```

Chief creates these with `kanban_create ... --parent <id>`; the dispatcher auto-promotes each
child when its parent is `done`.

## Non-Goals

- No code changes.
- No new profiles or boards.

## Inputs / Sources

- README.md
- HERMES.md (the loaded context file)

## Constraints

- Keep it to roughly one page.
- No secrets.

## Workspace (isolated per ticket)

`dir:~/HermesWork/agentic-mvp/workspaces/TICKET-0001` — all related cards share this isolated
ticket workspace; unrelated tickets never use it or the project root.

## Done Means

Reviewer issues PASS / PASS_WITH_NOTES, the `finalize` task auto-promotes, Chief closes it, and
the operator archives the cards.

For NEEDS_REVISION, Reviewer blocks the existing review after commenting. Chief creates a
revision card parented by build, links revision as another parent of review, and unblocks review
after revision completes.

## Memory Recommendation

None by default.
