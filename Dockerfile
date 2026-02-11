# ============================================================
# PicoClaw Docker - Multi-stage build
# Agente IA ultra-leve com Gemini 2.5 Flash Lite
# ============================================================

# --- Stage 1: Build ---
FROM golang:1.24-alpine AS builder

RUN apk add --no-cache git make

WORKDIR /src
RUN git clone https://github.com/sipeed/picoclaw.git .

# Apply patches
# Patch 1: Add gemma model support to Gemini provider detection
RUN sed -i 's/strings.Contains(lowerModel, "gemini")/strings.Contains(lowerModel, "gemini") || strings.Contains(lowerModel, "gemma")/' pkg/providers/http_provider.go

# Patch 2: Flexible allow_from filter (accepts ID-only, username-only, or full ID|USERNAME)
COPY patches/base.go /src/pkg/channels/base.go

# Build the binary
RUN make deps && make build

# --- Stage 2: Runtime ---
FROM alpine:3.21

RUN apk add --no-cache ca-certificates bash jq

# Create picoclaw user
RUN adduser -D -h /home/picoclaw picoclaw

# Copy binary from builder
COPY --from=builder /src/build/picoclaw /usr/local/bin/picoclaw
RUN chmod +x /usr/local/bin/picoclaw

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy default config
COPY config.json /defaults/config.json

# Setup picoclaw home directory
RUN mkdir -p /home/picoclaw/.picoclaw/workspace && \
    chown -R picoclaw:picoclaw /home/picoclaw

USER picoclaw
WORKDIR /home/picoclaw

ENV HOME=/home/picoclaw

ENTRYPOINT ["/entrypoint.sh"]
CMD ["gateway"]
