#!/usr/local/bin/bash

# Configuration
REQUESTS_DIR="/app/requests"
LOG_FILE="process_requests.log"
TIMEOUT="${DIFY_TIMEOUT:-1800}"
MAX_PAYLOAD_SIZE="${MAX_PAYLOAD_SIZE:-102400}" # 100KB default


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

        # Check payload size
        body_size=${#body}
        if [[ $body_size -gt $MAX_PAYLOAD_SIZE ]]; then
            log "ERROR" "Payload size exceeded for $request_file. Size: $body_size bytes, Max: $MAX_PAYLOAD_SIZE bytes"
            rm "$request_file"
            continue
        fi
        
        # Transform the request
            payload=$(jq -c '{inputs: {payload: .|tostring}, response_mode: "blocking", user: "AiCodeReview"}' <<< "$body")
            
            # Send to Dify
            response=$(curl -i -s -X POST "$dify_url" \
                -m "$TIMEOUT" \
                -H "Authorization: Bearer $auth_token" \
                -H "Content-Type: application/json" \
                -d "$payload" \
                -w "\n%{http_code}")
            curl_exit_code=$?
            status_code=$(echo "$response" | tail -n1)
            response=$(echo "$response" | sed '$d')
            
            # Check response
            if [[ $curl_exit_code -eq 0 || $curl_exit_code -eq 28 ]]; then
                if [[ $curl_exit_code -eq 0 ]]; then
                    log "INFO" "Successfully processed $request_file"
                else
                    log "WARNING" "Request timed out for $request_file"
                fi
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
