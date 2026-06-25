#!/bin/bash
# Check health of a specific Docker service
# Usage: health-check.sh <service-name>

set -euo pipefail

# Check arguments
if [ $# -lt 1 ]; then
    echo '{"error": "Usage: health-check.sh <service-name>"}' >&2
    exit 1
fi

SERVICE_NAME="$1"
# Lowercase for consistency with container names
SERVICE_NAME=$(echo "$SERVICE_NAME" | tr '[:upper:]' '[:lower:]')

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo '{"error": "Docker daemon not accessible", "service": "'$SERVICE_NAME'"}' >&2
    exit 1
fi

# Detect project name
PROJECT_NAME="${COMPOSE_PROJECT_NAME:-}"
if [ -z "$PROJECT_NAME" ]; then
    # Try to detect from dev.yml if it exists
    if [ -f "dev.yml" ]; then
        PROJECT_NAME=$(grep -E '^application:' dev.yml | awk '{print $2}' | tr -d '"' | tr -d "'" | xargs)
    fi
    # Fall back to directory name if dev.yml not found or no application field
    if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME=$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]')
    fi
fi

# Try to find container matching the service name
# Look for exact match or partial match in container name
CONTAINER=""
CONTAINER_STATE=""
CONTAINER_STATUS=""
CONTAINER_PORTS=""
CONTAINER_IMAGE=""

# Always use project filter to avoid picking up containers from other projects
FILTER="--filter label=com.docker.compose.project=$PROJECT_NAME"

# Search for containers - collect all matches
MATCHES=()

while IFS=$'\t' read -r name state; do
    # Check if service name matches (case-insensitive)
    if echo "$name" | grep -qi "$SERVICE_NAME"; then
        MATCHES+=("$name")
    fi
done < <(docker ps -a $FILTER --format '{{.Names}}\t{{.State}}')

# Check match count
MATCH_COUNT=${#MATCHES[@]}

if [ "$MATCH_COUNT" -eq 0 ]; then
    # No matches found
    echo "{"
    echo "  \"service\": \"$SERVICE_NAME\","
    echo "  \"found\": false,"
    echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"message\": \"No container found matching '$SERVICE_NAME'\""
    echo "}"
    exit 0
elif [ "$MATCH_COUNT" -gt 1 ]; then
    # Multiple matches - ambiguous
    echo "{"
    echo "  \"service\": \"$SERVICE_NAME\","
    echo "  \"error\": \"ambiguous\","
    echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"message\": \"Multiple containers match '$SERVICE_NAME': ${MATCHES[*]}\","
    echo "  \"matches\": ["
    for i in "${!MATCHES[@]}"; do
        if [ "$i" -gt 0 ]; then echo ","; fi
        echo "    \"${MATCHES[$i]}\""
    done
    echo "  ]"
    echo "}"
    exit 1
fi

# Exactly one match - get details using docker inspect for reliability
CONTAINER="${MATCHES[0]}"

# Get container details using docker inspect (more reliable than ps format parsing)
CONTAINER_STATE=$(docker inspect "$CONTAINER" --format '{{.State.Status}}' 2>/dev/null)
CONTAINER_IMAGE=$(docker inspect "$CONTAINER" --format '{{.Config.Image}}' 2>/dev/null)

# Get ports - handle both running and stopped containers
CONTAINER_PORTS=""
if [ "$CONTAINER_STATE" = "running" ]; then
    # For running containers, use docker ps format for consistency
    CONTAINER_PORTS=$(docker ps --filter "name=^${CONTAINER}$" --format '{{.Ports}}' 2>/dev/null)
fi

# Get human-readable status
CONTAINER_STATUS=$(docker ps -a --filter "name=^${CONTAINER}$" --format '{{.Status}}' 2>/dev/null)

# Determine health
HEALTH="unknown"
RUNNING=false

if [ "$CONTAINER_STATE" = "running" ]; then
    RUNNING=true
    if echo "$CONTAINER_STATUS" | grep -q "healthy"; then
        HEALTH="healthy"
    elif echo "$CONTAINER_STATUS" | grep -q "unhealthy"; then
        HEALTH="unhealthy"
    elif echo "$CONTAINER_STATUS" | grep -q "starting"; then
        HEALTH="starting"
    else
        HEALTH="running"
    fi
elif [ "$CONTAINER_STATE" = "exited" ]; then
    HEALTH="stopped"
elif [ "$CONTAINER_STATE" = "created" ]; then
    HEALTH="created"
fi

# Try to get additional health info if container has health check
HEALTHCHECK_STATUS=""
if [ "$RUNNING" = true ]; then
    HEALTHCHECK_STATUS=$(docker inspect "$CONTAINER" --format '{{.State.Health.Status}}' 2>/dev/null || echo "none")
    # Trim whitespace and newlines
    HEALTHCHECK_STATUS=$(echo "$HEALTHCHECK_STATUS" | tr -d '\n' | xargs)
    if [ "$HEALTHCHECK_STATUS" != "none" ] && [ "$HEALTHCHECK_STATUS" != "<no value>" ] && [ -n "$HEALTHCHECK_STATUS" ]; then
        HEALTH="$HEALTHCHECK_STATUS"
    fi
fi

# Parse ports into JSON array
PORTS_JSON="["
if [ -n "$CONTAINER_PORTS" ]; then
    PORT_FIRST=true
    IFS=',' read -ra PORT_ARRAY <<< "$CONTAINER_PORTS"
    for port in "${PORT_ARRAY[@]}"; do
        port=$(echo "$port" | xargs)  # Trim whitespace
        if [ "$PORT_FIRST" = false ]; then
            PORTS_JSON="$PORTS_JSON, "
        fi
        PORTS_JSON="$PORTS_JSON\"$port\""
        PORT_FIRST=false
    done
fi
PORTS_JSON="$PORTS_JSON]"

# Extract uptime from status
UPTIME="$CONTAINER_STATUS"

# Output JSON
echo "{"
echo "  \"service\": \"$SERVICE_NAME\","
echo "  \"found\": true,"
echo "  \"running\": $RUNNING,"
echo "  \"container\": \"$CONTAINER\","
echo "  \"state\": \"$CONTAINER_STATE\","
echo "  \"health\": \"$HEALTH\","
echo "  \"status\": \"$CONTAINER_STATUS\","
echo "  \"uptime\": \"$UPTIME\","
echo "  \"ports\": $PORTS_JSON,"
echo "  \"image\": \"$CONTAINER_IMAGE\","
echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
echo "}"
