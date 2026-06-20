# Agentic Hermes MVP Work System

This workspace defines a generic agentic workflow using Hermes profiles and Hermes Kanban.

## Profiles

- chief
- researcher
- builder
- reviewer

## Purpose

Convert user requests into reviewed outputs.

The system supports research, analysis, documents, software, troubleshooting, planning, automation, and review.

## Source of Truth

Hermes Kanban is the task source of truth.

Ticket workspace files are the artifact source of truth.

Memory is only for durable knowledge.

## First Commands

```bash
hermes kanban boards switch agentic-mvp
hermes kanban list
hermes kanban stats
hermes kanban watch
```

## Create Work (dependency graph)

Chief (the orchestrator) creates one task per role and links them with `--parent`; the
dispatcher auto-promotes each child `todo → ready` when its parents are `done`. Put the spec
and acceptance criteria in `--body`. Related cards share one ticket-isolated workspace:

```bash
TICKET_WS="$HOME/HermesWork/agentic-mvp/workspaces/TICKET-0001"
mkdir -p "$TICKET_WS"
BUILD=$(hermes kanban create "Build: Agentic Hermes MVP overview" \
  --assignee builder --body "Goal: Create outputs/hello-hermes.md; Acceptance: explain all four roles and build -> review -> finalize; no placeholders." \
  --workspace "dir:$TICKET_WS" --json | jq -r .id)
REVIEW=$(hermes kanban create "Review: Agentic Hermes MVP overview" \
  --assignee reviewer --parent "$BUILD" --body "Verify the stated acceptance criteria and record a verdict." \
  --workspace "dir:$TICKET_WS" --json | jq -r .id)
FINALIZE=$(hermes kanban create "Finalize: Agentic Hermes MVP overview" \
  --assignee chief --parent "$REVIEW" --body "Close only after an accepted review." \
  --workspace "dir:$TICKET_WS" --json | jq -r .id)
```

## Standard Flow

```text
research → build → review → finalize   (skip stages you don't need)
```

Workers complete their own cards (`kanban_complete`); only chief/operator finalizes and
archives. See `HERMES.md` (the single context file Hermes loads) for the full protocol.

On `NEEDS_REVISION`, the reviewer comments and blocks the review. Chief creates a revision
task parented by the build, links it as another parent of the same review, and unblocks the
review only after the revision completes.

## Layout of This Bundle

This directory is the staged workspace produced from the PRD. When deployed it maps to
`~/HermesWork/agentic-mvp/`.

```text
agentic-mvp/
  README.md              # this file
  AGENTS.md              # project context for agents
  HERMES.md              # Hermes Work OS instructions
  CLAUDE.md              # Claude Code context
  TEAM.md                # team charter
  WORKFLOW.md            # lifecycle + stage definitions
  MEMORY_POLICY.md       # what may/may not enter durable memory
  REVIEW_CHECKLIST.md    # reviewer checklists by ticket type
  CARD_TEMPLATE.md       # ticket template
  HANDOFF_TEMPLATE.md    # handoff template
  tickets/               # one folder per ticket (TICKET-xxxx/)
  workspaces/            # isolated work areas per ticket
  outputs/               # final deliverables
  templates/             # copies of the templates above
  scripts/
    setup-agentic-hermes-mvp.sh   # prints the Hermes commands; scaffolds files

../profiles/             # per-profile SOUL.md files to copy into ~/.hermes/profiles/<name>/
  chief/SOUL.md
  researcher/SOUL.md
  builder/SOUL.md
  reviewer/SOUL.md
```

## Setup

The setup script does **not** run any `hermes` command. It creates the local
directory structure and **prints** the Hermes commands for you to run yourself.

```bash
bash scripts/setup-agentic-hermes-mvp.sh            # scaffold + print commands
bash scripts/setup-agentic-hermes-mvp.sh --help     # usage
```

See the printed output for the profile, config, and Kanban commands to run.
