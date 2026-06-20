#!/usr/bin/env bash
#
# setup-agentic-hermes-mvp.sh
#
# Scaffolds the Agentic Hermes MVP Work System locally and PRINTS the Hermes
# CLI commands you need to run yourself.
#
# IMPORTANT: This script never executes any `hermes ...` command. It only:
#   1. Creates the workspace directory structure.
#   2. Copies the bundled context files, templates, and sample ticket into place
#      (no-clobber by default; existing files are never overwritten).
#   3. Stages each profile's SOUL.md into ~/.hermes/profiles/<name>/ when that
#      profile directory already exists (guarded by --overwrite-soul).
#   4. Prints — but does not run — the Hermes profile, config, and Kanban
#      commands, plus the validation plan.
#
# Command syntax verified against the Hermes docs:
#   https://hermes-agent.nousresearch.com/docs/
# Routing follows the documented dependency-graph model: Chief (the orchestrator)
# creates linked role-tasks with `kanban_create ... --parent <id>` and the
# dispatcher promotes `todo -> ready` when all parents are `done`. Workers are
# task-scoped: they terminate their own card with `kanban_complete` (or
# `kanban_block` for a genuine blocker / review gate) and never reassign or
# archive cards.
#
# No secrets are written by this script.

set -euo pipefail

# --------------------------------------------------------------------------- #
# Resolve locations
# --------------------------------------------------------------------------- #
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"          # the agentic-mvp/ bundle
PROFILES_SRC="$(cd "$BUNDLE_DIR/.." && pwd)/profiles"  # ../profiles/<name>/SOUL.md
HERMES_HOME_DIR="${HERMES_HOME:-$HOME/.hermes}"

# Defaults (override with flags)
WORKSPACE="${HOME}/HermesWork/agentic-mvp"
BOARD_SLUG="agentic-mvp"
BOARD_NAME="Agentic Hermes MVP"
BOARD_DESC="Generic agentic work system using chief, researcher, builder, and reviewer profiles."
OVERWRITE_SOUL=0
FORCE=0
DRY_RUN=0

PROFILES=(chief researcher builder reviewer)

# Per-profile routing descriptions (used in the printed profile-create commands)
desc_chief="Orchestrates Kanban work, clarifies requests, creates tickets, assigns profiles, tracks status, manages handoffs, and archives final outcomes."
desc_researcher="Researches, analyzes, compares options, diagnoses problems, studies documentation, and produces briefs or recommendations for assigned tickets."
desc_builder="Creates requested artifacts for assigned tickets, including code, scripts, documents, plans, summaries, configuration, and automation."
desc_reviewer="Reviews completed work against acceptance criteria, checks quality and risks, requests revisions, and approves work for completion."

# --------------------------------------------------------------------------- #
# Output helpers
# --------------------------------------------------------------------------- #
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
info()  { printf '  %s\n' "$*"; }
cmd()   { printf '    %s\n' "$*"; }   # a command for the USER to run (never executed)
hr()    { printf '%s\n' "----------------------------------------------------------------------"; }

usage() {
  cat <<USAGE
Usage: bash setup-agentic-hermes-mvp.sh [options]

Scaffolds the Agentic Hermes MVP workspace and PRINTS (does not run) the
Hermes CLI commands.

Options:
  --workspace <path>   Target workspace dir (default: ~/HermesWork/agentic-mvp)
  --overwrite-soul     Overwrite existing profile SOUL.md files when staging
  --force              Overwrite existing context/template files in the workspace
  --dry-run            Print everything; do not touch the filesystem at all
  --help               Show this help

This script NEVER runs a 'hermes' command. It only creates local files and
prints the commands for you to run.
USAGE
}

# --------------------------------------------------------------------------- #
# Parse args
# --------------------------------------------------------------------------- #
while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace)       WORKSPACE="${2:?--workspace needs a path}"; shift 2 ;;
    --overwrite-soul)  OVERWRITE_SOUL=1; shift ;;
    --force)           FORCE=1; shift ;;
    --dry-run)         DRY_RUN=1; shift ;;
    --help|-h)         usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

# Expand a leading ~ in --workspace if the user passed one literally
WORKSPACE="${WORKSPACE/#\~/$HOME}"

# copy_file SRC DST  -- no-clobber unless $FORCE; respects --dry-run
copy_file() {
  local src="$1" dst="$2"
  if [[ ! -f "$src" ]]; then
    info "skip (missing source): $src"
    return 0
  fi
  if [[ -f "$dst" && $FORCE -eq 0 ]]; then
    info "keep (exists):    ${dst/#$HOME/~}"
    return 0
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    info "would copy:       ${dst/#$HOME/~}"
  else
    cp "$src" "$dst"
    info "wrote:            ${dst/#$HOME/~}"
  fi
}

make_dir() {
  local d="$1"
  if [[ $DRY_RUN -eq 1 ]]; then
    info "would mkdir:      ${d/#$HOME/~}"
  else
    mkdir -p "$d"
    info "dir:              ${d/#$HOME/~}"
  fi
}

# --------------------------------------------------------------------------- #
bold "Agentic Hermes MVP setup"
hr
info "Bundle:     $BUNDLE_DIR"
info "Workspace:  $WORKSPACE"
info "Hermes home:$HERMES_HOME_DIR"
[[ $DRY_RUN -eq 1 ]] && info "Mode:       DRY RUN (no filesystem changes)"
echo

# --------------------------------------------------------------------------- #
# Step 1: workspace directory structure
# --------------------------------------------------------------------------- #
bold "1) Create workspace directory structure"
for sub in "" tickets workspaces outputs templates scripts; do
  make_dir "$WORKSPACE/$sub"
done
echo

# --------------------------------------------------------------------------- #
# Step 2: copy context files + templates + sample ticket
# --------------------------------------------------------------------------- #
bold "2) Copy context files, templates, and sample ticket"
CONTEXT_FILES=(
  README.md AGENTS.md HERMES.md CLAUDE.md TEAM.md WORKFLOW.md
  MEMORY_POLICY.md REVIEW_CHECKLIST.md CARD_TEMPLATE.md HANDOFF_TEMPLATE.md
)
for f in "${CONTEXT_FILES[@]}"; do
  copy_file "$BUNDLE_DIR/$f" "$WORKSPACE/$f"
done
copy_file "$BUNDLE_DIR/templates/CARD_TEMPLATE.md"    "$WORKSPACE/templates/CARD_TEMPLATE.md"
copy_file "$BUNDLE_DIR/templates/HANDOFF_TEMPLATE.md" "$WORKSPACE/templates/HANDOFF_TEMPLATE.md"
if [[ -f "$BUNDLE_DIR/tickets/TICKET-0001/TASK.md" ]]; then
  make_dir "$WORKSPACE/tickets/TICKET-0001"
  copy_file "$BUNDLE_DIR/tickets/TICKET-0001/TASK.md" "$WORKSPACE/tickets/TICKET-0001/TASK.md"
fi
echo

# --------------------------------------------------------------------------- #
# Step 3: stage SOUL.md files (only if the profile dir already exists)
# --------------------------------------------------------------------------- #
bold "3) Stage profile SOUL.md files"
info "SOUL.md lives at: $HERMES_HOME_DIR/profiles/<name>/SOUL.md"
info "Profiles must be created by Hermes first (see the printed commands in step 4)."
for p in "${PROFILES[@]}"; do
  src="$PROFILES_SRC/$p/SOUL.md"
  dst_dir="$HERMES_HOME_DIR/profiles/$p"
  dst="$dst_dir/SOUL.md"
  if [[ ! -f "$src" ]]; then
    info "[$p] skip (no bundled SOUL.md at $src)"
    continue
  fi
  if [[ ! -d "$dst_dir" ]]; then
    info "[$p] profile dir not found yet. After creating the profile, run:"
    cmd "cp \"$src\" \"$dst\""
    continue
  fi
  if [[ -f "$dst" && $OVERWRITE_SOUL -eq 0 ]]; then
    info "[$p] keep existing SOUL.md (use --overwrite-soul to replace)"
    continue
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    info "[$p] would write ${dst/#$HOME/~}"
  else
    cp "$src" "$dst"
    info "[$p] wrote ${dst/#$HOME/~}"
  fi
done
echo

# --------------------------------------------------------------------------- #
# Step 4: PRINT the Hermes commands (NOT executed)
# --------------------------------------------------------------------------- #
bold "4) Hermes commands to run yourself  (this script does NOT run them)"
hr

bold "4a) Create the four profiles (cloned deterministically from 'default')"
info "Use --clone-from default (not --clone): --clone copies the *active* profile,"
info "which is nondeterministic. --clone-from default is explicit (and implies --clone)."
for p in "${PROFILES[@]}"; do
  d="desc_${p}"
  cmd "hermes profile create $p --clone-from default --description \"${!d}\""
done
info "The --description is how the Kanban orchestrator routes a task to the right"
info "role by name, so keep it accurate per profile."
info "If no default profile is configured, create without --clone and run setup:"
for p in "${PROFILES[@]}"; do
  cmd "hermes profile create $p"
done
for p in "${PROFILES[@]}"; do
  cmd "$p setup"
done
echo

bold "4b) Confirm profile paths (use the displayed dir for SOUL.md)"
for p in "${PROFILES[@]}"; do
  cmd "hermes profile show $p"
done
info "Then place each SOUL.md (if not already staged in step 3):"
for p in "${PROFILES[@]}"; do
  cmd "cp \"$PROFILES_SRC/$p/SOUL.md\" \"$HERMES_HOME_DIR/profiles/$p/SOUL.md\""
done
echo

bold "4c) Point each profile at the MVP workspace"
for p in "${PROFILES[@]}"; do
  cmd "$p config set terminal.cwd \"$WORKSPACE\""
done
echo

bold "4d) Configure Chief as the Kanban orchestrator + WIP limits"
info "Chief builds the dependency graph, so its CLI platform must load the documented"
info "'hermes-cli' and 'kanban' toolsets. Do not use the nonexistent name 'hermes'."
info "Scalars ('hermes config set' takes a dotted key + a single value):"
cmd "chief config set kanban.orchestrator_profile chief"
cmd "chief config set kanban.default_assignee chief"
cmd "chief config set kanban.auto_decompose false   # explicit graph (may already be false)"
cmd "chief config set kanban.max_in_progress 3      # PRD WIP target (default: unlimited)"
info "Toolsets are LISTS. Edit the file directly and ensure both lists contain:"
cmd "chief config path        # -> ~/.hermes/profiles/chief/config.yaml"
cmd "#   toolsets:"
cmd "#     - hermes-cli"
cmd "#     - kanban"
cmd "#   platform_toolsets:"
cmd "#     cli:"
cmd "#       - hermes-cli"
cmd "#       - kanban"
info "For another gateway surface, add its matching Hermes toolset and 'kanban'"
info "under that platform too (for example: hermes-telegram + kanban)."
echo

bold "4e) Verify the bundled Kanban skills"
info "Restore a required skill only when it is absent:"
cmd "chief skills list | grep kanban-orchestrator || chief skills reset kanban-orchestrator --restore --yes"
for p in researcher builder reviewer; do
  cmd "$p skills list | grep kanban-worker || $p skills reset kanban-worker --restore --yes"
done
info "Chief hosts the gateway ('chief gateway start' below), so Chief's"
info "kanban.* block governs the dispatcher."
echo

bold "4f) Initialize Kanban and create the board"
cmd "hermes kanban init"
cmd "hermes kanban boards create $BOARD_SLUG \\"
cmd "  --name \"$BOARD_NAME\" \\"
cmd "  --description \"$BOARD_DESC\" \\"
cmd "  --switch"
cmd "hermes kanban boards list"
cmd "hermes kanban boards show"
echo

bold "4g) Start the gateway dispatcher (as chief — the gateway host)"
cmd "chief gateway start"
info "Chief hosts the gateway, so its kanban.* config governs the dispatcher."
info "One-shot dispatch for debugging:"
cmd "hermes kanban dispatch --max 1"
echo

bold "4h) Create an executable validation graph"
info "Chief creates one task per role and links them with --parent. The dispatcher"
info "promotes a child 'todo -> ready' only when ALL its parents are 'done', so the"
info "pipeline advances automatically with no human in the loop between stages."
info "This simple document request skips research. Its related cards share one"
info "ticket-isolated workspace so artifacts pass between roles."
cmd "command -v jq"
cmd "TICKET_WS=\"$WORKSPACE/workspaces/TICKET-0001\""
cmd "mkdir -p \"\$TICKET_WS\""
cmd "BUILD=\$(hermes kanban create \"Build: Agentic Hermes MVP overview\" \\"
cmd "  --assignee builder \\"
cmd "  --body \"Type: document; Stage: build; Goal: Create a one-page Markdown overview of the Agentic Hermes MVP; Desired Output: outputs/hello-hermes.md; Acceptance Criteria: explain chief, researcher, builder, and reviewer; explain build -> review -> finalize; clear structure; no placeholders; Workspace: \$TICKET_WS; Done Means: artifact and review handoff completed.\" \\"
cmd "  --workspace \"dir:\$TICKET_WS\" --json | jq -r .id)"
cmd "REVIEW=\$(hermes kanban create \"Review: Agentic Hermes MVP overview\" \\"
cmd "  --assignee reviewer --parent \"\$BUILD\" \\"
cmd "  --body \"Type: review; Stage: review; Goal: Verify outputs/hello-hermes.md; Acceptance Criteria: all four roles explained; dependency graph accurate; clear and placeholder-free; record PASS, PASS_WITH_NOTES, or NEEDS_REVISION in REVIEW.md; Workspace: \$TICKET_WS.\" \\"
cmd "  --workspace \"dir:\$TICKET_WS\" --json | jq -r .id)"
cmd "FINALIZE=\$(hermes kanban create \"Finalize: Agentic Hermes MVP overview\" \\"
cmd "  --assignee chief --parent \"\$REVIEW\" \\"
cmd "  --body \"Type: finalize; Stage: finalize; Goal: Close after an accepted review; Acceptance Criteria: record output path and review verdict; recommend memory only if warranted; Workspace: \$TICKET_WS.\" \\"
cmd "  --workspace \"dir:\$TICKET_WS\" --json | jq -r .id)"
cmd "hermes kanban show \"\$BUILD\""
cmd "hermes kanban show \"\$REVIEW\""
cmd "hermes kanban show \"\$FINALIZE\""
info "Watch the board and dispatcher:"
cmd "hermes kanban watch"
cmd "hermes kanban list"
cmd "hermes kanban stats"
cmd "hermes kanban diagnostics"
cmd "hermes kanban runs \"\$BUILD\""
cmd "hermes kanban runs \"\$REVIEW\""
echo

bold "4i) Operator actions (only for blocked cards / finalize)"
info "Stages advance on their own via kanban_complete. The operator only steps in for"
info "blocked cards or to archive a finished one:"
cmd "hermes kanban unblock <id>                 # resume after a worker blocked for input"
cmd "hermes kanban archive <id>                 # archive a completed card"
info "For NEEDS_REVISION, reviewer comments and blocks the existing review. Chief"
info "creates a revision with BUILD as parent, links REVISION as another parent of"
info "REVIEW, then unblocks that same REVIEW after REVISION completes:"
cmd "REVISION=\$(hermes kanban create \"Revise: Agentic Hermes MVP overview\" --assignee builder --parent \"\$BUILD\" --body \"Address review comments in the shared ticket workspace.\" --workspace \"dir:\$TICKET_WS\" --json | jq -r .id)"
cmd "hermes kanban link \"\$REVISION\" \"\$REVIEW\""
cmd "hermes kanban unblock \"\$REVIEW\"   # run after REVISION is done"
echo

# --------------------------------------------------------------------------- #
# Step 5: validation plan
# --------------------------------------------------------------------------- #
bold "5) Validation plan (run after the commands above)"
hr
cmd "hermes profile list"
for p in "${PROFILES[@]}"; do
  cmd "hermes profile show $p"
done
cmd "ls -la \"$WORKSPACE\""
cmd "ls -la \"$WORKSPACE/templates\""
cmd "hermes kanban boards list"
cmd "hermes kanban boards show"
cmd "hermes kanban stats"
echo

# --------------------------------------------------------------------------- #
bold "NOTES"
hr
info "- This script ran NO hermes commands. Copy the commands above to run them."
info "- '--description' on 'hermes profile create' IS supported and is used by the"
info "  Kanban orchestrator to route tasks to roles by name. '--clone-from default'"
info "  is the deterministic clone (plain '--clone' copies the active profile)."
info "- SOUL.md is read from HERMES_HOME (${HERMES_HOME_DIR}); Hermes does not read"
info "  SOUL.md from the current working directory."
info "- Routing is a DEPENDENCY GRAPH: chief creates linked role-tasks (kanban_create"
info "  + --parent) and the dispatcher promotes 'todo -> ready' when all parents are"
info "  'done'. Workers are task-scoped: they terminate their OWN card with"
info "  kanban_complete (or kanban_block for a blocker / review gate) and CANNOT"
info "  reassign or archive cards. Artifact files are written in ADDITION to the"
info "  tool calls. Only chief/operator finalizes and archives."
info "- Acceptance criteria live in the card --body and in kanban_complete metadata"
info "  (read downstream via kanban_show); TASK.md files are a human mirror only."
info "- One request/ticket gets one isolated workspace shared by its related role"
info "  cards. Unrelated requests never share a workspace or the project root."
info "- WIP: set 'kanban.max_in_progress: 3' (per the PRD) and optionally"
info "  'max_in_progress_per_profile' on the chief profile (step 4d)."
info "- No secrets are written by this script. Keep API keys in ~/.hermes/.env."
echo
bold "Done. Local scaffolding is in place; Hermes commands are printed above."
