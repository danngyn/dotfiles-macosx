#!/bin/bash
# Retrieve logs from a specific Docker service
# Usage: get-logs.sh <service-name> [lines]

set -euo pipefail

# Check arguments
if [ $# -lt 1 ]; then
    echo '{"error": "Usage: get-logs.sh <service-name> [lines]"}' >&2
    exit 1
fi

SERVICE_NAME="$1"
LINES="${2:-100}"

# Validate lines is a number
if ! [[ "$LINES" =~ ^[0-9]+$ ]]; then
    echo '{"error": "Lines must be a number"}' >&2
    exit 1
fi

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
CONTAINER=""

# First try with project filter
if docker ps -aq --filter "label=com.docker.compose.project=$PROJECT_NAME" 2>/dev/null | grep -q .; then
    FILTER="--filter label=com.docker.compose.project=$PROJECT_NAME"
else
    FILTER=""
fi

# Search for container (case-insensitive)
while IFS=$'\t' read -r name state; do
    if echo "$name" | grep -qi "$SERVICE_NAME"; then
        CONTAINER="$name"
        break
    fi
done < <(docker ps -a $FILTER --format '{{.Names}}\t{{.State}}')

# If not found, report error
if [ -z "$CONTAINER" ]; then
    echo "{"
    echo "  \"service\": \"$SERVICE_NAME\","
    echo "  \"found\": false,"
    echo "  \"error\": \"No container found matching '$SERVICE_NAME'\","
    echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
    echo "}"
    exit 1
fi

# Get logs and strip ANSI color codes
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOGS=$(docker logs --tail "$LINES" "$CONTAINER" 2>&1 | sed 's/\x1b\[[0-9;]*m//g')

# Escape JSON special characters in logs
# Replace backslash, double quote, newline, carriage return, tab
LOGS_ESCAPED=$(echo "$LOGS" | jq -Rs .)

# Output JSON
echo "{"
echo "  \"service\": \"$SERVICE_NAME\","
echo "  \"container\": \"$CONTAINER\","
echo "  \"lines\": $LINES,"
echo "  \"timestamp\": \"$TIMESTAMP\","
echo "  \"logs\": $LOGS_ESCAPED"
echo "}"
