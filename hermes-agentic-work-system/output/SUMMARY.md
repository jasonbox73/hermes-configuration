# Agentic Hermes MVP — Build Summary

Scaffolding for Jason's Agentic Hermes MVP Work System, generated from
`hermes-agentic-work-system.md` (the PRD). Command syntax was validated against the
live docs at https://hermes-agent.nousresearch.com/docs/.

Per request: **no `hermes` command is executed anywhere.** The setup script only
creates local files and **prints** the Hermes commands for you to run.

## Files created

```text
output/
  SUMMARY.md                       # this file
  profiles/
    chief/SOUL.md                  # profile identities (copy to ~/.hermes/profiles/<name>/)
    researcher/SOUL.md
    builder/SOUL.md
    reviewer/SOUL.md
  agentic-mvp/                     # the workspace (maps to ~/HermesWork/agentic-mvp/)
    README.md
    AGENTS.md
    HERMES.md
    CLAUDE.md
    TEAM.md
    WORKFLOW.md
    MEMORY_POLICY.md
    REVIEW_CHECKLIST.md
    CARD_TEMPLATE.md
    HANDOFF_TEMPLATE.md
    tickets/
      TICKET-0001/TASK.md          # filled-in sample/validation ticket
    workspaces/
    outputs/
    templates/
      CARD_TEMPLATE.md
      HANDOFF_TEMPLATE.md
    scripts/
      setup-agentic-hermes-mvp.sh  # prints hermes commands; scaffolds files (idempotent)
```

## Commands already run (by this build)

- Created the directory tree under `output/`.
- Wrote all Markdown context files, templates, SOUL.md files, and the sample ticket.
- `chmod +x` and `bash -n` (syntax check) on the setup script.
- A `--dry-run`-equivalent real run against a **temporary** workspace to verify
  output and idempotency. Nothing was written to `~/.hermes` or `~/HermesWork`.

## Commands the user must run

Run the setup script to scaffold your real workspace and see the Hermes commands:

```bash
bash output/agentic-mvp/scripts/setup-agentic-hermes-mvp.sh
# or choose a workspace path:
bash output/agentic-mvp/scripts/setup-agentic-hermes-mvp.sh --workspace ~/HermesWork/agentic-mvp
```

Then run the printed Hermes commands yourself, in order:

1. `hermes profile create {chief,researcher,builder,reviewer} --clone-from default --description "..."`
   (`--clone-from default` is the deterministic clone; `--description` is how the orchestrator routes to roles).
2. `hermes profile show <name>` to confirm each profile path.
3. Copy each `SOUL.md` into `~/.hermes/profiles/<name>/SOUL.md`
   (the script stages these automatically once the profile dir exists; use
   `--overwrite-soul` to replace an existing one).
4. `<profile> config set terminal.cwd <workspace>` for each profile.
5. Configure Chief as orchestrator + WIP: `chief config set kanban.orchestrator_profile chief`,
   `... default_assignee chief`, `... auto_decompose false`, `... max_in_progress 3`.
   List `hermes-cli` and `kanban` in both Chief toolset lists.
6. Verify `kanban-orchestrator` for Chief and `kanban-worker` for each worker.
7. `hermes kanban init` then `hermes kanban boards create agentic-mvp --name "..." --description "..." --switch`.
8. `chief gateway start` (Chief hosts the gateway/dispatcher).
9. Build the executable sample graph printed by the script: Builder root, Reviewer parented by
   Builder, and Chief finalize parented by Reviewer. All three share one isolated ticket workspace.

### Routing model (dependency graph)

Routing follows Hermes' documented model: **Chief (the orchestrator) creates a graph of
linked role-tasks** with `kanban_create` + `--parent`, and the dispatcher promotes a child
`todo → ready` when **all its parents are `done`** — so the pipeline advances automatically
with no human in the loop between stages.

- Workers use the built-in Kanban toolset when dispatched (`kanban_show`, `kanban_heartbeat`,
  `kanban_complete`, `kanban_block`) — they do **not** shell out to `hermes kanban`. Each worker
  terminates its **own** card with `kanban_complete(summary, metadata)` (or `kanban_block` for a
  genuine blocker / review gate). Workers are task-scoped and **cannot reassign or archive** cards.
- Acceptance criteria travel in the card `--body` and in `kanban_complete` metadata (read
  downstream via `kanban_show()`); `TASK.md` files are a human mirror only.
- The operator only intervenes for **blocked** cards (`hermes kanban unblock <id>`) and to
  **archive** finished cards. `NEEDS_REVISION` → reviewer comments and blocks; Chief creates a
  revision parented by build, links it as another review parent, then unblocks review after it ends.

The Hermes board status (`triage → todo → ready → running → blocked → done →
archived`) is managed by Hermes; our workflow `Stage` field is a semantic
overlay in the ticket body and never replaces it.

## Validation steps

```bash
hermes profile list
hermes profile show chief        # repeat for researcher/builder/reviewer
ls -la ~/HermesWork/agentic-mvp
ls -la ~/HermesWork/agentic-mvp/templates
hermes kanban boards list
hermes kanban boards show
hermes kanban stats
```

Expected lifecycle for the sample ticket (simple document → researcher skipped):
chief specifies → creates `build` (assignee builder) and `review` (assignee reviewer,
parent build) and `finalize` (assignee chief, parent review) → builder produces
`outputs/hello-hermes.md` and `kanban_complete`s → review auto-promotes to `ready`;
reviewer writes `REVIEW.md`, completes on PASS → finalize auto-promotes; chief closes
and the operator archives.

## Known limitations / things to verify

- **Orchestrator toolset** — Chief lists `hermes-cli` and `kanban` in both top-level `toolsets`
  and `platform_toolsets.cli` with `chief config edit`. The `kanban.*` scalars (`orchestrator_profile`, `default_assignee`,
  `auto_decompose`, `max_in_progress`) are set with `chief config set`. Workers do **not** need
  `kanban` in their toolset — the dispatcher injects the worker tools at spawn. Chief hosts the
  gateway (`chief gateway start`), so Chief's `kanban.*` block governs the dispatcher.
- **SOUL.md location** is `HERMES_HOME/profiles/<name>/SOUL.md` (default
  `~/.hermes/...`). Hermes does not read `SOUL.md` from the working directory, so the
  profile SOUL files are staged under `output/profiles/`, not in the workspace.
- The script never writes secrets and never overwrites existing files without
  `--force` (context/templates) or `--overwrite-soul` (SOUL.md).
- Profiles inherit model/provider config from `default` via `--clone-from default`; if
  you have no configured default, use the non-clone path plus `<profile> setup`.
- **Single context file** — Hermes loads one project context file (first match wins:
  `.hermes.md → HERMES.md → AGENTS.md → CLAUDE.md → .cursorrules`). `HERMES.md` is the
  canonical loaded file; the other context files carry "not auto-loaded" banners.
- **Concurrency** — set `kanban.max_in_progress: 3` (PRD target; Hermes defaults to
  unlimited) and optionally `max_in_progress_per_profile`. The dispatcher interval is
  `dispatch_interval_seconds` (default 60); children promote `todo → ready` as parents complete.
- **`dir:` workspace** — Hermes expects an absolute path. Each request gets one
  ticket-isolated workspace (e.g. `workspaces/TICKET-0001`) shared by its related role cards;
  unrelated tickets never share one. The script prints the expanded path. The `~` in
  `README.md`/`TICKET-0001` examples is illustrative.

## Next recommended action

Run the setup script, then execute the printed profile-creation commands and confirm
each profile path with `hermes profile show`. After that, create the sample ticket and
watch it move through the board with `hermes kanban watch`.
