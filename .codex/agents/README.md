# Custom Subagents

Codex has built-in subagent support. This folder is for optional custom role config files referenced from `~/.codex/config.toml`.

Example config entry:

```toml
[agents.reviewer]
description = "Find correctness, security, and test risks in code."
config_file = "./agents/reviewer.toml"
nickname_candidates = ["Ada", "Grace"]
```

Keep these role files narrow. A useful custom role should describe one responsibility, the evidence it should gather, and what output format the parent agent should expect.
