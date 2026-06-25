# Codex Home

This directory contains user-level Codex configuration and local runtime state.

## Files to edit

- `config.toml`: Default model, sandbox, approvals, profiles, features, MCP servers, and trusted projects.
- `AGENTS.md`: Global instructions Codex reads for every workspace.
- `agents/`: Optional custom subagent role config files.
- `templates/`: Local templates for skills, prompts, and reusable setup.
- `memories/`: User memory files when memory features are enabled.

## Files to leave alone

- `auth.json`: Login credentials.
- `state_*.sqlite`, `logs_*.sqlite`, `sessions/`, `cache/`, `tmp/`, `.tmp/`, `shell_snapshots/`: Codex-managed runtime state.

## Useful commands

```sh
codex features list
codex mcp list
codex --profile fast
codex --profile deep
codex --profile review review
codex --ask-for-approval never "Summarize the current instructions."
```

Install personal skills under `~/.agents/skills`. Use `~/.codex/skills/.system` as read-only reference material for bundled skills.
