---
name: pr-review
description: Review a GitHub PR by fetching its diff, reading the PR description, looking up the linked ticket, and researching context via Unblocked. Outputs a structured review locally. Invoke with /pr-review <pr-url>.
---

# PR Review Skill

Review a pull request end-to-end: gather context from the PR, the linked ticket, and Unblocked, then produce a thorough inline review locally.

## Input

The user provides a GitHub PR URL, e.g. `https://github.com/clio/ruby_service_bucket/pull/4826`.

Parse the PR number from the URL. If the URL is just a number, treat it as a PR in the current repo.

## Steps

### 1. Fetch PR metadata and diff (parallel)

Run these in parallel using Bash (prepend `unset GITHUB_TOKEN &&` to each command to avoid token override issues):

- `unset GITHUB_TOKEN && gh pr view <number> --json title,body,author,state,baseRefName,headRefName,files`
- `unset GITHUB_TOKEN && gh pr diff <number>`

If `gh` fails, ask the user to check their GitHub auth.

### 2. Extract ticket ID and research context (parallel)

From the PR title or branch name, extract the ticket ID (e.g. `ROOT-642`, `KIWI-123`, `MUSH-45`).

Launch these in parallel:

**a) Ticket lookup via Linear** — Use `mcp__claude_ai_Linear__get_issue` with the ticket ID to fetch requirements, acceptance criteria, and context.

**b) Unblocked research** — MANDATORY. Use `mcp__unblocked__context_research` to search for context about the PR: prior discussions, related PRs, why the change is being made, any rejected approaches. Do NOT skip this step.

### 3. Read changed source files — THOROUGHLY

**Do NOT cut corners on this step.** Every changed source file must be read in full context:

- For EVERY file in the PR's changed file list, read the **full current version** (not just the first 100 lines). If a file is large, read it in chunks until you have the full picture.
- Read related files that the changed code depends on (imported types, called methods, base classes, concerns). Trace cross-file dependencies.
- For frontend changes: read the full component file, understand the reactive lifecycle, verify types match across serialization boundaries.
- For companion/dependent PRs mentioned in the description: verify the endpoints/types they introduce actually exist or will exist. Note unverified assumptions explicitly.
- If the PR is in a different repo (e.g., Grow) and you can't read the source files locally, state this explicitly — do NOT pretend you verified something you didn't.

### 4. Verify — do NOT assume

Before writing the review, check each of these. If you cannot verify one, say so explicitly in the review:

- **Type compatibility**: Do types/interfaces match across file boundaries? Don't assume — read both sides.
- **All call sites**: Grep for the changed function/method to find all callers. Are they all compatible with the change?
- **State management**: For frontend components, trace how state flows through the full lifecycle (connectedCallback → updated → disconnectedCallback). Are there re-render, re-connection, or race condition risks?
- **Error paths**: What happens when each async call fails? Is every failure path handled?
- **Companion PRs**: If the PR depends on another PR, verify the dependency is real and note whether it's merged or not.

### 5. Produce the review

Write a structured review covering:

#### Header
- PR title, author, branch, state
- Link to the ticket with a one-line summary of what the ticket requires

#### Summary
- 2-3 sentence summary of what the PR does and the approach taken

#### Architecture & Approach
- Is the approach sound? Does it match the ticket requirements?
- Are there simpler alternatives?
- Does it follow codebase conventions?

#### Issues (blocking)
- Bugs, logic errors, missing edge cases
- Security concerns
- Missing firm_identifier scoping (every Communications model query must include firm_identifier)
- Unsafe DDL on large tables
- Each issue: file path + line reference, code snippet, explanation, suggested fix

#### Nits (non-blocking)
- Style, naming, minor improvements
- Test coverage gaps
- Unrelated changes bundled in

#### Verdict
- One-line summary: approve / request changes / needs discussion
- Call out the main concern if requesting changes

## Style Rules

- Lead with substance, no filler
- Reference specific file paths and line numbers
- Show code snippets for issues
- Be direct about problems but acknowledge good work
- Do NOT post anything to GitHub, Linear, or any external service — output is local only
- Never use the `code-review` skill — this skill replaces it with direct inline review

## IMPORTANT

- This is a READ-ONLY review. Do NOT post comments to GitHub, do NOT approve/reject the PR via API.
- Do NOT modify any files.
- Output everything as text in the conversation.
