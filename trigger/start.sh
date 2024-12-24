#!/bin/bash

# Start the Benthos service for GitLab system hooks
benthos -c /benthos_gitlab.yaml &

# Wait for all background jobs to finish
wait