#!/bin/bash
# Portable Docker service discovery script
# Works with any Docker-based project

set -euo pipefail

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

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo '{"error": "Docker daemon not accessible", "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' >&2
    exit 1
fi

# Check if this project has containers
FILTER="--filter label=com.docker.compose.project=$PROJECT_NAME"
if docker ps -aq $FILTER 2>/dev/null | grep -q .; then
    # Found containers for this project
    FOUND_PROJECT=true
else
    # No containers for this project
    FOUND_PROJECT=false
    echo "{\"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"project\": \"$PROJECT_NAME\", \"project_found\": false, \"services\": [], \"message\": \"No containers found for project '$PROJECT_NAME'\"}"
    exit 0
fi

# Get timestamp
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Query Docker and build JSON
echo "{"
echo "  \"timestamp\": \"$TIMESTAMP\","
echo "  \"project\": \"$PROJECT_NAME\","
if [ "$FOUND_PROJECT" = true ]; then
    echo "  \"project_found\": true,"
else
    echo "  \"project_found\": false,"
fi
echo "  \"services\": ["

FIRST=true
docker ps -a $FILTER --format '{{.Names}}\t{{.State}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}' | while IFS=$'\t' read -r name state status image ports; do
    # Extract service name from container name
    # Handle formats: "project-service-1" -> "service", "service-1" -> "service"
    service_name="$name"
    
    # Remove project prefix if it exists
    if [[ "$name" == "$PROJECT_NAME"-* ]]; then
        service_name="${name#$PROJECT_NAME-}"
    fi
    
    # Remove numeric suffix (e.g., "-1")
    service_name=$(echo "$service_name" | sed 's/-[0-9]*$//')
    
    # Parse ports into array format
    ports_json="["
    if [ -n "$ports" ]; then
        # Split ports by comma and format as JSON array
        port_first=true
        IFS=',' read -ra PORT_ARRAY <<< "$ports"
        for port in "${PORT_ARRAY[@]}"; do
            port=$(echo "$port" | xargs)  # Trim whitespace
            if [ "$port_first" = false ]; then
                ports_json="$ports_json, "
            fi
            ports_json="$ports_json\"$port\""
            port_first=false
        done
    fi
    ports_json="$ports_json]"
    
    # Determine health status
    health="unknown"
    if [[ "$state" == "running" ]]; then
        if [[ "$status" == *"healthy"* ]]; then
            health="healthy"
        elif [[ "$status" == *"unhealthy"* ]]; then
            health="unhealthy"
        elif [[ "$status" == *"starting"* ]]; then
            health="starting"
        else
            health="running"
        fi
    elif [[ "$state" == "exited" ]]; then
        health="stopped"
    elif [[ "$state" == "created" ]]; then
        health="created"
    fi
    
    # Add comma for all but first entry
    if [ "$FIRST" = false ]; then
        echo "    ,"
    fi
    FIRST=false
    
    # Output service JSON
    echo "    {"
    echo "      \"name\": \"$service_name\","
    echo "      \"container\": \"$name\","
    echo "      \"state\": \"$state\","
    echo "      \"status\": \"$status\","
    echo "      \"ports\": $ports_json,"
    echo "      \"image\": \"$image\","
    echo "      \"health\": \"$health\""
    echo -n "    }"
done

echo ""
echo "  ]"
echo "}"
