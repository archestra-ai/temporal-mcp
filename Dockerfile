# Build stage
FROM --platform=$BUILDPLATFORM golang:1.24-alpine AS builder

ARG TARGETOS
ARG TARGETARCH

WORKDIR /app

# Install git for fetching dependencies
RUN apk add --no-cache git

# Copy go mod files first for better caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary for the target platform
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -ldflags="-s -w" -o temporal-mcp ./cmd/temporal-mcp

# Runtime stage
FROM alpine:3.19

# Install ca-certificates for HTTPS connections
RUN apk add --no-cache ca-certificates

# Create non-root user
RUN adduser -D -u 1000 temporal-mcp

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/temporal-mcp /usr/local/bin/temporal-mcp

# Create config directory
RUN mkdir -p /app/config && chown -R temporal-mcp:temporal-mcp /app

USER temporal-mcp

# Default entrypoint - config can be provided via:
# 1. TEMPORAL_MCP_CONFIG env var (inline YAML)
# 2. TEMPORAL_MCP_CONFIG_FILE env var (path to config file)
# 3. Mount config file to /app/config/config.yml
ENTRYPOINT ["temporal-mcp"]
CMD ["-config", "/app/config/config.yml"]
