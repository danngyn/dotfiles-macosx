---
name: pr-review
description: Review GitHub pull requests or local review branches with a code-review stance. Use when the user asks Codex to review a PR, validate a branch for review, inspect PR comments, assess query/performance risk, compare a branch to a plan or ticket, or produce review feedback. Prefer local branch inspection when available; use GitHub APIs only when local code is unavailable or the user explicitly wants live PR context.
---

# PR Review

## Core Rule

Review as a senior engineer, not as a summarizer. Lead with findings: bugs, regressions, data risks, concurrency issues, migration risks, query/performance problems, missing tests, and rollout gaps. Keep summaries secondary.

Do not run specs unless the user explicitly asks. Static reads, `git diff`, `rg`, syntax checks, and lightweight non-test commands are acceptable when useful.

## Inputs To Request

If the user provides only a GitHub PR URL, prefer asking for or creating a local review branch before deep review:

```bash
git fetch origin pull/<PR_NUMBER>/head:review-<PR_NUMBER>
git checkout review-<PR_NUMBER>
```

Ask for only the missing information that changes review quality:

- Whether the branch is already checked out locally.
- The base branch or stacked base when it is not `main`.
- The plan, Linear ticket, or acceptance criteria if the review must validate product scope.
- Whether to inspect live GitHub comments or only local code.
- Whether specs should be skipped, which is the default for this user.

Do not block on these if the answer can be discovered from local git state, branch names, PR metadata, or files in the repo.

## Local-First Workflow

1. Inspect repository state:

```bash
git status --short
git branch --show-current
git log --oneline --decorate -n 20
```

2. Identify the right comparison base. For stacked branches, compare only the relevant commits when the user says the branch is stacked.

```bash
git merge-base HEAD main
git diff --stat <base>...HEAD
git diff --name-only <base>...HEAD
```

3. Read changed files and surrounding code. Use `rg`, `sed`, `nl`, and `git diff`; prefer `rg` for searches.

4. Cross-check the behavior against any plan, ticket, PR description, or reviewer comment the user references.

5. Check high-risk paths explicitly:

- Database migrations on live tables: locks, full scans, foreign keys, online DDL, idempotency, rollback behavior.
- Background jobs: idempotency, batching, throttling, kill switches, retries, cursor behavior, rollout sequencing.
- Data backfills: partial runs, concurrent writes, stale rows, soft-deleted rows, source of truth, reconciliation.
- API/read paths: authorization, filtering, pagination, serializers, response compatibility, query count, N+1 risk.
- Write paths: dual writes, data consistency, transaction scope, race conditions, retry safety.
- Index usage: make sure new filters and joins have matching leftmost-prefix indexes or bounded cardinality.

## GitHub Context

Use live GitHub PR context when the user asks about review comments, PR description, approvals, or exact diff from a URL. Prefer `gh api` if available. If live fetch is slow or blocked, stop and ask for a local branch or pasted diff instead of burning time.

Useful commands:

```bash
gh api repos/<owner>/<repo>/pulls/<number>
gh api repos/<owner>/<repo>/pulls/<number>/files
gh api repos/<owner>/<repo>/pulls/<number>/comments
gh api repos/<owner>/<repo>/pulls/<number>/reviews
```

For exact line references from a remote PR, fetch file contents at the head SHA only when needed. Avoid repeated network fetches for files that are present locally.

## Output Shape

Use this order:

1. Findings, ordered by severity, with file and line references.
2. Open questions or assumptions.
3. Brief change summary only if useful.
4. Verification status, including if specs were intentionally skipped.

If no issues are found, say that clearly and mention residual risk or untested areas.

Keep review comments actionable. For each finding, explain:

- What can break.
- Why the current code permits it.
- What change would resolve or reduce the risk.

Prefer concise wording the user can paste into a PR thread.

## User-Specific Defaults

For this user and repository:

- Default to not running specs unless explicitly asked.
- Prefer local branch review over live GitHub review.
- For `ruby_service_bucket`, pay special attention to Communications database migrations, background jobs, Clio-thread consistency, data-association dual writes, and endpoint response compatibility.
- If a PR is stacked, review only the requested branch’s delta when the user says prior stacked work was already reviewed.
