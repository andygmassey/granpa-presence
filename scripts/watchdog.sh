#!/bin/bash
# Dad Presence Monitoring - Docker Watchdog
# Ensures all containers are running and healthy

LOG_FILE="/home/massey/watchdog.log"
COMPOSE_DIR="/home/massey"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

check_container() {
    local name=$1
    local status=$(docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null)
    
    if [ "$status" != "true" ]; then
        log "WARNING: Container $name is not running. Attempting restart..."
        cd "$COMPOSE_DIR"
        docker compose up -d "$name"
        sleep 10
        
        status=$(docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null)
        if [ "$status" = "true" ]; then
            log "SUCCESS: Container $name restarted successfully"
        else
            log "ERROR: Failed to restart container $name"
        fi
    fi
}

# Check all containers
check_container "homeassistant"
check_container "influxdb"
check_container "grafana"

# Rotate log if too large (>1MB)
if [ -f "$LOG_FILE" ] && [ $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null) -gt 1048576 ]; then
    mv "$LOG_FILE" "${LOG_FILE}.old"
    log "Log rotated"
fi
