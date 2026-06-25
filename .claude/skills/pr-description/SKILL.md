---
name: pr-description
description: Generate a PR description in What/How format. What explains the change from a user/product perspective; How explains the implementation. Invoke with /pr-description.
---

# PR Description Skill

Generate a PR description by reviewing the current branch's commits and diff against the base branch, then produce a **What / How** write-up.

## Steps

1. Run `git log main..HEAD --oneline` to see the commits in scope.
2. Run `git diff main..HEAD` to understand what changed.
3. Write the description in the format below, wrapped in a markdown code block (` ```markdown `) so the user can copy-paste it directly.

## Output Format

**{TICKET-ID} {Brief title}**

## What

Plain-language description of what changed from a user/product perspective. Group related changes under bold subheadings if there are multiple distinct behaviours. Use bullet points for lists of specifics.

## How

Bullet points describing the implementation approach — key state, data flow, methods, patterns. Reference specific names (functions, properties, classes) in backticks. Keep it concise and technical.

## Style Rules

- Title matches the PR naming convention: `{TICKET-ID} {brief description}`
- No filler ("This PR...", "In this change...") — lead directly with the substance
- What section: readable by anyone on the team, not just the implementor
- How section: implementation detail, useful for reviewers and future readers
- Tone: direct, technical, no fluff

## Example

**ROOT-400-3 Thread reader: handling many messages**

## What

Implements two opening behaviours for `comms-thread-reader`:

**Scroll to most recent on open**
When a thread is loaded, the most recent message is expanded and the messages container scrolls to it automatically.

**Collapsed view for threads with 5+ messages**
Rather than rendering the full list, the reader shows a condensed layout:
- First message — collapsed
- Middle messages — hidden behind a "Show X messages" button
- Second most recent — collapsed
- Most recent — expanded

Clicking "Show X messages" reveals the full list and scrolls so the first revealed message is in view.

## How

- `expandedMessageIds` is seeded with only the last message id on thread load; `scrollTop = scrollHeight` runs after `updateComplete`
- `showAllMessages` boolean gates the middle messages; resets to `false` when the thread changes
- `handleShowAll` sets the flag, awaits `updateComplete`, then calls `scrollIntoView({ block: "nearest" })` on the second `comms-thread-message` element (first of the revealed messages)
- `renderManyMessages()` handles the 5+ layout; `renderMessage()` extracted as a shared helper
