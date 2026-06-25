# Global Codex Guidance

## Working agreements

- Start by reading the local code, docs, and commands before assuming how a project works.
- Prefer `rg` and `rg --files` for searches.
- Keep edits scoped to the requested behavior and the surrounding code patterns.
- Preserve user changes. Do not revert, reset, or overwrite unrelated work unless explicitly asked.
- Use structured parsers and project tools over ad hoc text manipulation when practical.
- Ask before destructive commands, broad rewrites, dependency additions, credential changes, or production-impacting actions.
- Run the smallest relevant verification command after changes when feasible. If verification is skipped or blocked, say why.
- For UI work, match the existing design system first and check responsive behavior before finishing.
- Keep final responses concise: outcome, files changed, verification, and any real risks.

## Default quality bar

- Favor simple, direct code over new abstractions unless the abstraction removes real duplication or complexity.
- Prefer tests for behavior changes, shared contracts, bug fixes, and risky paths.
- Surface assumptions and tradeoffs clearly when they affect implementation or safety.
- Avoid adding comments that restate code; add short comments only for non-obvious logic.
