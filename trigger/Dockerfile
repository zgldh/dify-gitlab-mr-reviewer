FROM jeffail/benthos:latest

# Copy Benthos config files
COPY benthos_gitlab.yaml /benthos_gitlab.yaml
COPY start.sh /start.sh

# Make the start script executable
RUN chmod +x /start.sh

# Run the start script
CMD ["/start.sh"]