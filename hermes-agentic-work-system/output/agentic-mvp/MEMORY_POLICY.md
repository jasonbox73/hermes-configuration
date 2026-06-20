# Memory Policy

> **Human reference only — not auto-loaded.** `HERMES.md` is the single context file Hermes
> loads; the operative memory policy is consolidated there.

## Core Rule

Ticket-specific facts stay in the ticket.

## What Belongs in Memory

Store only durable information such as:

- stable user preferences
- long-term project conventions
- recurring workflow decisions
- reusable operating principles
- environment facts that are likely to remain valid

## What Does Not Belong in Memory

Do not store:

- temporary ticket details
- one-time research findings
- draft-specific notes
- transient errors
- credentials
- secrets
- assumptions that have not been confirmed
- incomplete or unreviewed outputs

## Memory Recommendation Process

Workers may recommend memory updates.

The Chief decides whether the recommendation is durable enough.

The Reviewer may challenge questionable memory updates.

## Examples

Good memory candidate:

```text
Jason prefers an MVP with chief, researcher, builder, and reviewer profiles.
```

Bad memory candidate:

```text
Ticket 004 is currently waiting for the Builder.
```
