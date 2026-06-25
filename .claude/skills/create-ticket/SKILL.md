---
name: create-ticket
description: Draft and post a Linear ticket from conversation context. Defaults to ROOT team. Invoke with /create-ticket or /create-ticket [team].
---

# Create Ticket Skill

Draft a Linear ticket from the current conversation context, show it for review, then post it only after explicit confirmation.

## Steps

1. Infer the ticket content from the conversation — the problem, proposed fix, affected code, and acceptance criteria.
2. Determine the team: use the argument passed to the skill if provided, otherwise default to **ROOT**.
3. Draft the ticket (title + description) and show it to the user in a clearly labelled block.
4. Wait for explicit confirmation ("yes", "post it", "looks good", etc.) before calling `mcp__claude_ai_Linear__save_issue`.
5. Post the ticket and return the issue ID and URL.

## Title Rules

- Short imperative phrase — no ticket ID prefix (Linear assigns it)
- Under 70 characters
- No filler ("This ticket...", "We should...")

## Description Format

Use this structure, omitting sections that don't apply:

```
## Problem

What is broken or missing. Reference specific file paths, method names, or endpoints where relevant.

## Fix

The proposed solution at a high level. Numbered steps if multi-part.

## Affected code

Bulleted list of specific files / methods / endpoints touched.

## Acceptance Criteria

Bulleted list of concrete, testable conditions that define done.
```

## Style Rules

- Lead directly with substance — no preamble
- Problem: readable by anyone on the team
- Fix: technical enough for an engineer to scope
- Acceptance criteria: specific and testable, not vague
- Omit "Affected code" if the scope is obvious from the Problem section

## Confirmation Gate

NEVER call `mcp__claude_ai_Linear__save_issue` without explicit user confirmation. Always show the full draft first and ask "Good to post?"
