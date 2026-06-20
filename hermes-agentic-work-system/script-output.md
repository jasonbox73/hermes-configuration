[1mAgentic Hermes MVP setup[0m
----------------------------------------------------------------------
  Bundle:     /Users/box/Desktop/hermes-agentic-work-system /output/agentic-mvp
  Workspace:  /Users/box/HermesWork/agentic-mvp
  Hermes home:/Users/box/.hermes

[1m1) Create workspace directory structure[0m
  dir:              ~/HermesWork/agentic-mvp/
  dir:              ~/HermesWork/agentic-mvp/tickets
  dir:              ~/HermesWork/agentic-mvp/workspaces
  dir:              ~/HermesWork/agentic-mvp/outputs
  dir:              ~/HermesWork/agentic-mvp/templates
  dir:              ~/HermesWork/agentic-mvp/scripts

[1m2) Copy context files, templates, and sample ticket[0m
  keep (exists):    ~/HermesWork/agentic-mvp/README.md
  keep (exists):    ~/HermesWork/agentic-mvp/AGENTS.md
  keep (exists):    ~/HermesWork/agentic-mvp/HERMES.md
  keep (exists):    ~/HermesWork/agentic-mvp/CLAUDE.md
  keep (exists):    ~/HermesWork/agentic-mvp/TEAM.md
  keep (exists):    ~/HermesWork/agentic-mvp/WORKFLOW.md
  keep (exists):    ~/HermesWork/agentic-mvp/MEMORY_POLICY.md
  keep (exists):    ~/HermesWork/agentic-mvp/REVIEW_CHECKLIST.md
  keep (exists):    ~/HermesWork/agentic-mvp/CARD_TEMPLATE.md
  keep (exists):    ~/HermesWork/agentic-mvp/HANDOFF_TEMPLATE.md
  keep (exists):    ~/HermesWork/agentic-mvp/templates/CARD_TEMPLATE.md
  keep (exists):    ~/HermesWork/agentic-mvp/templates/HANDOFF_TEMPLATE.md
  dir:              ~/HermesWork/agentic-mvp/tickets/TICKET-0001
  keep (exists):    ~/HermesWork/agentic-mvp/tickets/TICKET-0001/TASK.md

[1m3) Stage profile SOUL.md files[0m
  SOUL.md lives at: /Users/box/.hermes/profiles/<name>/SOUL.md
  Profiles must be created by Hermes first (see the printed commands in step 4).
  [chief] keep existing SOUL.md (use --overwrite-soul to replace)
  [researcher] profile dir not found yet. After creating the profile, run:
    cp "/Users/box/Desktop/hermes-agentic-work-system /output/profiles/researcher/SOUL.md" "/Users/box/.hermes/profiles/researcher/SOUL.md"
  [builder] profile dir not found yet. After creating the profile, run:
    cp "/Users/box/Desktop/hermes-agentic-work-system /output/profiles/builder/SOUL.md" "/Users/box/.hermes/profiles/builder/SOUL.md"
  [reviewer] profile dir not found yet. After creating the profile, run:
    cp "/Users/box/Desktop/hermes-agentic-work-system /output/profiles/reviewer/SOUL.md" "/Users/box/.hermes/profiles/reviewer/SOUL.md"

[1m4) Hermes commands to run yourself  (this script does NOT run them)[0m
----------------------------------------------------------------------
[1m4a) Create the four profiles (cloned deterministically from 'default')[0m
  Use --clone-from default (not --clone): --clone copies the *active* profile,
  which is nondeterministic. --clone-from default is explicit (and implies --clone).
    hermes profile create chief --clone-from default --description "Orchestrates Kanban work, clarifies requests, creates tickets, assigns profiles, tracks status, manages handoffs, and archives final outcomes."
    hermes profile create researcher --clone-from default --description "Researches, analyzes, compares options, diagnoses problems, studies documentation, and produces briefs or recommendations for assigned tickets."
    hermes profile create builder --clone-from default --description "Creates requested artifacts for assigned tickets, including code, scripts, documents, plans, summaries, configuration, and automation."
    hermes profile create reviewer --clone-from default --description "Reviews completed work against acceptance criteria, checks quality and risks, requests revisions, and approves work for completion."
  The --description is how the Kanban orchestrator routes a task to the right
  role by name, so keep it accurate per profile.
  If no default profile is configured, create without --clone and run setup:
    hermes profile create chief
    hermes profile create researcher
    hermes profile create builder
    hermes profile create reviewer
    chief setup
    researcher setup
    builder setup
    reviewer setup

[1m4b) Confirm profile paths (use the displayed dir for SOUL.md)[0m
    hermes profile show chief
    hermes profile show researcher
    hermes profile show builder
    hermes profile show reviewer
  Then place each SOUL.md (if not already staged in step 3):
    cp "/Users/box/Desktop/hermes-agentic-work-system /output/profiles/chief/SOUL.md" "/Users/box/.hermes/profiles/chief/SOUL.md"
    cp "/Users/box/Desktop/hermes-agentic-work-system /output/profiles/researcher/SOUL.md" "/Users/box/.hermes/profiles/researcher/SOUL.md"
    cp "/Users/box/Desktop/hermes-agentic-work-system /output/profiles/builder/SOUL.md" "/Users/box/.hermes/profiles/builder/SOUL.md"
    cp "/Users/box/Desktop/hermes-agentic-work-system /output/profiles/reviewer/SOUL.md" "/Users/box/.hermes/profiles/reviewer/SOUL.md"

[1m4c) Point each profile at the MVP workspace[0m
    chief config set terminal.cwd "/Users/box/HermesWork/agentic-mvp"
    researcher config set terminal.cwd "/Users/box/HermesWork/agentic-mvp"
    builder config set terminal.cwd "/Users/box/HermesWork/agentic-mvp"
    reviewer config set terminal.cwd "/Users/box/HermesWork/agentic-mvp"

[1m4d) Configure Chief as the Kanban orchestrator + WIP limits[0m
  Chief builds the dependency graph, so its CLI platform must load the documented
  'hermes-cli' and 'kanban' toolsets. Do not use the nonexistent name 'hermes'.
  Scalars ('hermes config set' takes a dotted key + a single value):
    chief config set kanban.orchestrator_profile chief
    chief config set kanban.default_assignee chief
    chief config set kanban.auto_decompose false   # explicit graph (may already be false)
    chief config set kanban.max_in_progress 3      # PRD WIP target (default: unlimited)
  Toolsets are LISTS. Edit the file directly and ensure both lists contain:
    chief config path        # -> ~/.hermes/profiles/chief/config.yaml
    #   toolsets:
    #     - hermes-cli
    #     - kanban
    #   platform_toolsets:
    #     cli:
    #       - hermes-cli
    #       - kanban
  For another gateway surface, add its matching Hermes toolset and 'kanban'
  under that platform too (for example: hermes-telegram + kanban).

[1m4e) Verify the bundled Kanban skills[0m
  Restore a required skill only when it is absent:
    chief skills list | grep kanban-orchestrator || chief skills reset kanban-orchestrator --restore --yes
    researcher skills list | grep kanban-worker || researcher skills reset kanban-worker --restore --yes
    builder skills list | grep kanban-worker || builder skills reset kanban-worker --restore --yes
    reviewer skills list | grep kanban-worker || reviewer skills reset kanban-worker --restore --yes
  Chief hosts the gateway ('chief gateway start' below), so Chief's
  kanban.* block governs the dispatcher.

[1m4f) Initialize Kanban and create the board[0m
    hermes kanban init
    hermes kanban boards create agentic-mvp \
      --name "Agentic Hermes MVP" \
      --description "Generic agentic work system using chief, researcher, builder, and reviewer profiles." \
      --switch
    hermes kanban boards list
    hermes kanban boards show

[1m4g) Start the gateway dispatcher (as chief — the gateway host)[0m
    chief gateway start
  Chief hosts the gateway, so its kanban.* config governs the dispatcher.
  One-shot dispatch for debugging:
    hermes kanban dispatch --max 1

[1m4h) Create an executable validation graph[0m
  Chief creates one task per role and links them with --parent. The dispatcher
  promotes a child 'todo -> ready' only when ALL its parents are 'done', so the
  pipeline advances automatically with no human in the loop between stages.
  This simple document request skips research. Its related cards share one
  ticket-isolated workspace so artifacts pass between roles.
    command -v jq
    TICKET_WS="/Users/box/HermesWork/agentic-mvp/workspaces/TICKET-0001"
    mkdir -p "$TICKET_WS"
    BUILD=$(hermes kanban create "Build: Agentic Hermes MVP overview" \
      --assignee builder \
      --body "Type: document; Stage: build; Goal: Create a one-page Markdown overview of the Agentic Hermes MVP; Desired Output: outputs/hello-hermes.md; Acceptance Criteria: explain chief, researcher, builder, and reviewer; explain build -> review -> finalize; clear structure; no placeholders; Workspace: $TICKET_WS; Done Means: artifact and review handoff completed." \
      --workspace "dir:$TICKET_WS" --json | jq -r .id)
    REVIEW=$(hermes kanban create "Review: Agentic Hermes MVP overview" \
      --assignee reviewer --parent "$BUILD" \
      --body "Type: review; Stage: review; Goal: Verify outputs/hello-hermes.md; Acceptance Criteria: all four roles explained; dependency graph accurate; clear and placeholder-free; record PASS, PASS_WITH_NOTES, or NEEDS_REVISION in REVIEW.md; Workspace: $TICKET_WS." \
      --workspace "dir:$TICKET_WS" --json | jq -r .id)
    FINALIZE=$(hermes kanban create "Finalize: Agentic Hermes MVP overview" \
      --assignee chief --parent "$REVIEW" \
      --body "Type: finalize; Stage: finalize; Goal: Close after an accepted review; Acceptance Criteria: record output path and review verdict; recommend memory only if warranted; Workspace: $TICKET_WS." \
      --workspace "dir:$TICKET_WS" --json | jq -r .id)
    hermes kanban show "$BUILD"
    hermes kanban show "$REVIEW"
    hermes kanban show "$FINALIZE"
  Watch the board and dispatcher:
    hermes kanban watch
    hermes kanban list
    hermes kanban stats
    hermes kanban diagnostics
    hermes kanban runs "$BUILD"
    hermes kanban runs "$REVIEW"

[1m4i) Operator actions (only for blocked cards / finalize)[0m
  Stages advance on their own via kanban_complete. The operator only steps in for
  blocked cards or to archive a finished one:
    hermes kanban unblock <id>                 # resume after a worker blocked for input
    hermes kanban archive <id>                 # archive a completed card
  For NEEDS_REVISION, reviewer comments and blocks the existing review. Chief
  creates a revision with BUILD as parent, links REVISION as another parent of
  REVIEW, then unblocks that same REVIEW after REVISION completes:
    REVISION=$(hermes kanban create "Revise: Agentic Hermes MVP overview" --assignee builder --parent "$BUILD" --body "Address review comments in the shared ticket workspace." --workspace "dir:$TICKET_WS" --json | jq -r .id)
    hermes kanban link "$REVISION" "$REVIEW"
    hermes kanban unblock "$REVIEW"   # run after REVISION is done

[1m5) Validation plan (run after the commands above)[0m
----------------------------------------------------------------------
    hermes profile list
    hermes profile show chief
    hermes profile show researcher
    hermes profile show builder
    hermes profile show reviewer
    ls -la "/Users/box/HermesWork/agentic-mvp"
    ls -la "/Users/box/HermesWork/agentic-mvp/templates"
    hermes kanban boards list
    hermes kanban boards show
    hermes kanban stats

[1mNOTES[0m
----------------------------------------------------------------------
  - This script ran NO hermes commands. Copy the commands above to run them.
  - '--description' on 'hermes profile create' IS supported and is used by the
    Kanban orchestrator to route tasks to roles by name. '--clone-from default'
    is the deterministic clone (plain '--clone' copies the active profile).
  - SOUL.md is read from HERMES_HOME (/Users/box/.hermes); Hermes does not read
    SOUL.md from the current working directory.
  - Routing is a DEPENDENCY GRAPH: chief creates linked role-tasks (kanban_create
    + --parent) and the dispatcher promotes 'todo -> ready' when all parents are
    'done'. Workers are task-scoped: they terminate their OWN card with
    kanban_complete (or kanban_block for a blocker / review gate) and CANNOT
    reassign or archive cards. Artifact files are written in ADDITION to the
    tool calls. Only chief/operator finalizes and archives.
  - Acceptance criteria live in the card --body and in kanban_complete metadata
    (read downstream via kanban_show); TASK.md files are a human mirror only.
  - One request/ticket gets one isolated workspace shared by its related role
    cards. Unrelated requests never share a workspace or the project root.
  - WIP: set 'kanban.max_in_progress: 3' (per the PRD) and optionally
    'max_in_progress_per_profile' on the chief profile (step 4d).
  - No secrets are written by this script. Keep API keys in ~/.hermes/.env.

[1mDone. Local scaffolding is in place; Hermes commands are printed above.[0m
