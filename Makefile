.PHONY: all build clean test fmt vet lint run install help docker-build docker-push docker-buildx-setup

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod
GOFMT=$(GOCMD) fmt
GOVET=$(GOCMD) vet
GOLINT=golangci-lint

# Binary name
BINARY_NAME=temporal-mcp

# Binary path
BIN_DIR=./bin
BINARY=$(BIN_DIR)/$(BINARY_NAME)

# Docker parameters
DOCKER_REGISTRY=europe-west1-docker.pkg.dev/friendly-path-465518-r6/archestra-public
DOCKER_IMAGE=temporal-io-mcp-server
DOCKER_TAG?=latest
DOCKER_PLATFORMS=linux/amd64,linux/arm64
BUILDX_BUILDER=temporal-mcp-builder

all: clean fmt vet test build

build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BIN_DIR)
	$(GOBUILD) -o $(BINARY) ./cmd/temporal-mcp
	@echo "Binary built at $(BINARY)"
	@chmod +x $(BINARY)

clean:
	@echo "Cleaning..."
	$(GOCLEAN)
	@rm -rf $(BIN_DIR)
	@echo "Cleaned build artifacts"

test:
	@echo "Running tests..."
	$(GOTEST) -v ./...

fmt:
	@echo "Formatting code..."
	find ./cmd ./internal ./pkg ./test -type f -name "*.go" | xargs -I{} go fmt {}

vet:
	@echo "Vetting code..."
	$(GOVET) ./...

lint:
	@echo "Linting code..."
	$(GOLINT) run

run: build
	@echo "Running $(BINARY_NAME)..."
	$(BINARY)

install:
	@echo "Installing dependencies..."
	$(GOMOD) tidy
	$(GOGET) -u ./...

# Docker commands
docker-buildx-setup:
	@echo "Setting up Docker buildx for multi-arch builds..."
	@docker buildx create --name $(BUILDX_BUILDER) --use 2>/dev/null || docker buildx use $(BUILDX_BUILDER)
	@docker buildx inspect --bootstrap

docker-build: docker-buildx-setup
	@echo "Building multi-arch Docker image..."
	docker buildx build \
		--platform $(DOCKER_PLATFORMS) \
		-t $(DOCKER_REGISTRY)/$(DOCKER_IMAGE):$(DOCKER_TAG) \
		--load \
		.

docker-push: docker-buildx-setup
	@echo "Building and pushing multi-arch Docker image..."
	docker buildx build \
		--platform $(DOCKER_PLATFORMS) \
		-t $(DOCKER_REGISTRY)/$(DOCKER_IMAGE):$(DOCKER_TAG) \
		--push \
		.

docker-push-release: docker-buildx-setup
	@echo "Building and pushing multi-arch Docker image with latest and version tags..."
	docker buildx build \
		--platform $(DOCKER_PLATFORMS) \
		-t $(DOCKER_REGISTRY)/$(DOCKER_IMAGE):latest \
		-t $(DOCKER_REGISTRY)/$(DOCKER_IMAGE):$(DOCKER_TAG) \
		--push \
		.

help:
	@echo "Makefile commands:"
	@echo ""
	@echo "Build commands:"
	@echo "  make build           - Build the temporal-mcp binary"
	@echo "  make clean           - Clean build artifacts"
	@echo "  make test            - Run tests"
	@echo "  make fmt             - Format code"
	@echo "  make vet             - Vet code"
	@echo "  make lint            - Lint code"
	@echo "  make run             - Build and run temporal-mcp"
	@echo "  make install         - Install dependencies"
	@echo "  make all             - Clean, format, vet, test, and build"
	@echo ""
	@echo "Docker commands:"
	@echo "  make docker-buildx-setup  - Setup Docker buildx for multi-arch builds"
	@echo "  make docker-build         - Build multi-arch Docker image (local)"
	@echo "  make docker-push          - Build and push multi-arch Docker image"
	@echo "  make docker-push-release  - Build and push with both latest and version tags"
	@echo ""
	@echo "Docker variables:"
	@echo "  DOCKER_TAG=v1.0.0    - Set the Docker image tag (default: latest)"
	@echo ""
	@echo "Examples:"
	@echo "  make docker-push DOCKER_TAG=v1.0.0"
	@echo "  make docker-push-release DOCKER_TAG=v1.0.0"
	@echo ""
	@echo "  make help            - Show this help message"
