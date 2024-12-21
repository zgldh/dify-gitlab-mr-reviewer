FROM bash:5.1

# Dependencies
RUN apk add --no-cache \
    curl \
    jq \
    bc

# Create the work dir
WORKDIR /app

# Copy all code
COPY trigger.sh /app/trigger.sh

# Run the script
CMD ["bash", "/app/trigger.sh"]
