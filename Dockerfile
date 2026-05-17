# Simple personal container - learning the basics
FROM alpine:3.21

# Install one useful tool to prove the container works
RUN apk add --no-cache curl

# Print a message when the container runs
CMD ["echo", "My container is working!"]