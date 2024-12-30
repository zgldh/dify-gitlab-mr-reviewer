FROM bash:5.1

# Install dependencies
RUN apk update && \
    apk add --no-cache \
    curl \
    jq \
    supervisor

# Install Benthos
RUN curl -L https://github.com/benthosdev/benthos/releases/download/v4.27.0/benthos_4.27.0_linux_amd64.tar.gz | \
    tar -xz -C /usr/local/bin && \
    chmod +x /usr/local/bin/benthos

# Create app directory
RUN mkdir -p /app

# Copy configuration files
COPY receiver.yaml /app/receiver.yaml
COPY process_requests.sh /app/process_requests.sh

# Make scripts executable
RUN chmod +x /app/process_requests.sh

# Configure supervisor
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Run supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
