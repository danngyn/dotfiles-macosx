---
name: ticket-description
description: Generate a Linear ticket description from a feature request or finding. Produces a What/Why/Blocked by/Proposed implementation/Acceptance criteria write-up. Invoke with /ticket-description.
---

# Ticket Description Skill

Generate a Linear ticket description based on the feature, bug, or finding described by the user.

## Steps

1. Understand the feature or finding from the conversation context — what it is, why it matters, and any blockers or open questions.
2. If there is relevant code context (files, components, endpoints), reference the specific file paths.
3. Write the description in the format below.

## Output Format

**{Brief title}**

## What

Plain-language description of the feature or change from a user/product perspective. One short paragraph.

## Why

The motivation — user value, design requirement, or product reason. One or two sentences.

## Blocked by

Any technical blockers, missing data, or prerequisite work that prevents implementation. Omit this section if there are no blockers.

## Proposed implementation

Numbered or bulleted steps describing the implementation approach at a high level. Reference specific file paths, endpoints, or component names where relevant.

## Acceptance criteria

Bulleted list of specific, testable conditions that define done.

## Style Rules

- Title: short, imperative phrase — no ticket ID prefix (Linear assigns it)
- No filler ("This ticket...", "We should...") — lead directly with the substance
- What/Why: readable by anyone on the team, not just the implementor
- Proposed implementation: technical enough for an engineer to scope the work
- Acceptance criteria: concrete and testable, not vague ("works correctly")
- Tone: direct, technical, no fluff
- Omit sections that are not applicable (e.g. no blockers → skip Blocked by)

## Example

**Show "(You)" label for self in participants list**

## What

In the participants popover (visible on both thread messages and inbox items), contacts that belong to the logged-in user should display "(You)" next to their name — e.g. "Sharon Smith (You)".

## Why

Improves readability when scanning a thread's From/To/Cc/Bcc participants, making it immediately clear which address belongs to the current user.

## Blocked by

The current user's email is not available in the inbox/thread-reader component tree. `listConnections` (`GET communications/oauth/connections`) returns connected mailbox emails but is only consumed by `send-mail` and `email-integration` — not the inbox.

Additionally, `ThreadItem` currently has no `mailbox_id`, which makes it ambiguous which connected email to match against in the inbox item context.

## Proposed implementation

1. Make connected emails available to the inbox/thread-reader (either via a dedicated fetch on init or hoisted from a parent component).
2. Pass `connectedEmails: string[]` as a prop to `comms-participants-list`.
3. Append "(You)" to any participant whose email is in the set.

## Acceptance criteria

- Participants whose email matches a connected mailbox show "(You)" after their name in both the thread message and inbox item participants popovers.
- No "(You)" label appears for other participants.
- No regressions to the participants popover layout.
