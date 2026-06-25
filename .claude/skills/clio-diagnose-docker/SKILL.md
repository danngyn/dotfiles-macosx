---
name: clio-diagnose-docker
description: Diagnose Docker environments by discovering running services, checking health, and analyzing logs. Works across any Docker-based project. CRITICAL: Docker access requires required_permissions=["all"] (bypass Cursor sandbox).
compatibility:
  requires:
    - Docker
    - Docker Compose (optional)
  notes: Requires user approval via required_permissions=["all"] to bypass sandbox and access Docker
---

# Diagnose Docker Environment Skill

Discover and diagnose Docker services in any project, using the scripts bundled with this skill.

## When to Use

- User asks "what services are running?" or "is MySQL running?"
- User reports errors like "can't connect to Redis" or "database not responding"
- User asks for logs from a specific service
- Diagnosing development environment issues

---

## Mandatory Requirements (Read This First)

- **Permissions**: Every command that touches Docker **MUST** be executed with:

When using Shell tool, include: `required_permissions=["all"]`

- **Why**: Docker runs outside Cursor’s sandbox; sandbox blocks Unix sockets (e.g. Docker socket). Without `required_permissions=["all"]`, these scripts will fail with Docker permission/daemon errors.

- **Use the bundled scripts first**: Only if no other alternative run raw docker commands such as `docker ps`, `docker logs`, or `docker inspect`. Use:
  - `scripts/query-docker.sh`
  - `scripts/health-check.sh`
  - `scripts/get-logs.sh`

---

## Script Location

These scripts live next to this file:

```
clio-diagnose-docker/
├── SKILL.md
└── scripts/
    ├── query-docker.sh
    ├── health-check.sh
    └── get-logs.sh
```

Always invoke scripts via their **full path**, derived from this `SKILL.md` location.

## Available Commands

### List All Services

```bash
bash ./scripts/query-docker.sh
```

Returns JSON with all running containers, their status, and ports.

### Check Specific Service Health

```bash
bash ./scripts/health-check.sh <service-name>
```

Examples: `mysql`, `redis`, `elasticsearch`, `postgres`

### Get Service Logs

```bash
bash ./scripts/get-logs.sh <service-name> [lines]
```

Default retrieves last 100 lines. Examples:
- `bash ./scripts/get-logs.sh mysql`
- `bash ./scripts/get-logs.sh redis 500`

## How It Works

1. Detects project name (directory name, dev.yml file or `COMPOSE_PROJECT_NAME`)
2. Filters containers to that project
3. Extracts service names from container names
4. Reports running state / uptime / health where available

### Project Detection Examples

- Running from `~/clio/grow/` → Shows only grow containers (or none if not running)
- Running from `~/clio/themis/` → Shows only themis containers

## Output Format

All scripts output JSON for easy parsing. Example:

```json
{
  "timestamp": "2026-01-16T15:30:00Z",
  "project": "grow",
  "services": [
    {
      "name": "mysql",
      "container": "grow-mysql-1",
      "state": "running",
      "status": "Up 2 hours",
      "ports": ["3308:3306"],
      "health": "healthy"
    }
  ]
}
```

---

## Suggested Diagnostic Workflow

1. Run `query-docker.sh` to see project services and health.
2. If a service is missing/stopped/unhealthy, run `get-logs.sh <service> [lines]`.
3. Optionally run `health-check.sh <service>` for a quick single-service view.

## Reporting Guidelines

**CRITICAL**: When diagnosing Docker issues, agents MUST follow these reporting standards:

1. **Always Provide Context Summary**: Begin your diagnostic report with a clear summary that includes:
   - What services are expected vs. actually running
   - Current state of relevant services (running/stopped/healthy/unhealthy)
   - Key findings from logs or health checks

2. **Phrase Uncertain Findings as Suggestions**: When you identify potential problems but aren't certain about the root cause:
   - ❌ DON'T say: "The database is failing because of X"
   - ✅ DO say: "Consider investigating X, which might be causing the issue"
   - ✅ DO say: "You may want to manually check if Y is configured correctly"
   - ✅ DO say: "This could be related to Z - worth investigating further"

3. **Separate Facts from Possibilities**: Clearly distinguish between:
   - Confirmed facts (service is stopped, error in logs, port conflict detected)
   - Uncertain hypotheses (possible causes that need manual verification)

## Common Patterns

In all cases, use the **full script path** and include **`required_permissions=["all"]`**.

### Pattern: User reports "can't connect to database"
1. List services with `query-docker.sh`
2. If DB service isn’t `running` / `healthy`, fetch logs with `get-logs.sh <service> 200`
3. Look for port conflicts, init failures, auth errors, OOM/disk issues

### Pattern: User asks "is everything running?"
1. List services with `query-docker.sh`
2. Report running vs stopped/unhealthy and the impacted service names

### Pattern: Service is running but unresponsive
1. Fetch logs with `get-logs.sh <service> 200`
2. Look for OOM, timeouts, disk full, config errors
3. Compare with reported health in `query-docker.sh`

```

