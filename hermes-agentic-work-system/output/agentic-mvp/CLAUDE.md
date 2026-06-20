# Claude Code Context: Agentic Hermes MVP

This project defines a Hermes-based agentic Kanban workflow.

When working in this directory, do not assume the task is software-only.

Your job may be to create profile files, templates, documentation, setup scripts, or workflow scaffolding.

## Build Task

Create and maintain the files needed to operate the MVP:

- profile SOUL.md contents
- project context files
- workflow documentation
- ticket templates
- review templates
- setup scripts
- sample tickets

## Safety Rules

Do not place secrets in committed files.
Do not overwrite existing Hermes config without backing it up.
Do not assume profile paths; use `hermes profile show <name>` to confirm.
Make setup scripts idempotent where possible.
Prefer clear Markdown files over hidden behavior.

## Deliverable Standard

Every change should be understandable to a human operator.

Include:

- what changed
- where files were written
- setup commands
- validation steps
