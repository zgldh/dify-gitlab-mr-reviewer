#!/usr/local/bin/bash

# Configuration
REQUESTS_DIR="/app/requests"
LOG_FILE="process_requests.log"

# Logging function
log() {
    local level=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" | tee -a "$LOG_FILE"
}

# Main processing loop
process_requests() {
    while true; do
        # Find all request files
        for request_file in "$REQUESTS_DIR"/request*.json; do
            [ -e "$request_file" ] || continue
            
            log "INFO" "Processing file: $request_file"
            
            # Read and parse the request
            request_content=$(cat "$request_file")
            body=$(echo "$request_content" | jq -r '.body')
            auth_token=$(echo "$request_content" | jq -r '.headers."X-Gitlab-Token"')
            dify_url=$(echo "$request_content" | jq -r '.headers.dify')
            
            # Transform the request
            payload=$(jq -c '{inputs: {payload: .|tostring}, response_mode: "blocking", user: "AiCodeReview"}' <<< "$body")
            
            # Send to Dify
            response=$(curl -s -X POST "$dify_url" \
                -H "Authorization: Bearer $auth_token" \
                -H "Content-Type: application/json" \
                -d "$payload")
            status_code=$?
            
            # Check response
            if [[ $status_code -eq 0 ]]; then
                log "INFO" "Successfully processed $request_file"
                rm "$request_file"
            else
                log "ERROR" "Failed to process $request_file. Response: $response"
            fi
        done
        
        # Wait before next iteration
        sleep 5
    done
}

# Start processing
log "INFO" "Starting request processor"
process_requests
