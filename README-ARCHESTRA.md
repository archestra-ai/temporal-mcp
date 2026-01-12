# Temporal MCP Server for Archestra

This is a fork of [temporal-mcp](https://github.com/Mocksi/temporal-mcp) with enhanced configuration support via environment variables, making it easy to deploy in Archestra or any containerized environment.

## Docker Image

```
europe-west1-docker.pkg.dev/friendly-path-465518-r6/archestra-public/temporal-io-mcp-server:latest
```

## Configuration

The server can be configured in three ways (in order of priority):

### 1. Inline YAML via Environment Variable

Set the `TEMPORAL_MCP_CONFIG` environment variable with your full YAML configuration:

```bash
TEMPORAL_MCP_CONFIG='
temporal:
  hostPort: "your-temporal-server:7233"
  namespace: "default"
  environment: "local"
  defaultTaskQueue: "your-task-queue"

workflows:
  YourWorkflow:
    purpose: "Description of what this workflow does"
    input:
      type: "YourInputType"
      fields:
        - field_name: "Description"
    output:
      type: "YourOutputType"
      description: "Output description"
    taskQueue: "your-task-queue"
'
```

### 2. Config File Path via Environment Variable

Set `TEMPORAL_MCP_CONFIG_FILE` to point to your config file:

```bash
TEMPORAL_MCP_CONFIG_FILE=/path/to/your/config.yml
```

### 3. Mount Config File

Mount your config file to `/app/config/config.yml` (the default path).

## Environment Variable Overrides

Individual Temporal connection settings can be overridden via environment variables, regardless of which configuration method you use:

| Environment Variable | Description | Default |
|---------------------|-------------|---------|
| `TEMPORAL_HOST_PORT` | Temporal server address | `localhost:7233` |
| `TEMPORAL_NAMESPACE` | Temporal namespace | `default` |
| `TEMPORAL_ENVIRONMENT` | Environment type (`local` or `remote`) | `local` |
| `TEMPORAL_TIMEOUT` | Connection timeout | `5s` |
| `TEMPORAL_DEFAULT_TASK_QUEUE` | Default task queue for workflows | (none) |

## Deploying in Archestra

### Option A: Using Inline Config (Recommended for Simple Setups)

1. Go to **MCP Catalog** → **Add Local MCP Server**
2. Configure:
   - **Name**: `temporal-mcp`
   - **Docker Image**: `europe-west1-docker.pkg.dev/friendly-path-465518-r6/archestra-public/temporal-io-mcp-server:latest`
   - **Transport Type**: `stdio`
   - **Command**: Leave empty
   - **Environment Variables**:
     - `TEMPORAL_HOST_PORT`: Your Temporal server address
     - `TEMPORAL_NAMESPACE`: Your namespace
     - `TEMPORAL_MCP_CONFIG`: Your full YAML config (for workflows)

### Option B: Using Config File

1. Create a ConfigMap or Secret with your config.yml
2. Mount it to `/app/config/config.yml` in the MCP server pod
3. Set environment variable overrides as needed

## Example Workflow Configuration

```yaml
workflows:
  AccountTransferWorkflow:
    purpose: "Transfers money between accounts with validation and notification. Handles the happy path scenario where everything works as expected."
    workflowIDRecipe: "transfer_{{.from_account}}_{{.to_account}}_{{.amount}}"
    input:
      type: "TransferInput"
      fields:
        - from_account: "Source account ID"
        - to_account: "Destination account ID"
        - amount: "Amount to transfer"
    output:
      type: "TransferOutput"
      description: "Transfer confirmation with charge ID"
    taskQueue: "account-transfer-queue"

  DataProcessingWorkflow:
    purpose: "Processes data files and generates reports. Supports CSV, JSON, and XML formats."
    workflowIDRecipe: "process_{{.file_id}}"
    input:
      type: "ProcessInput"
      fields:
        - file_id: "Unique file identifier"
        - format: "File format (csv, json, xml)"
        - output_path: "Optional. Path for output file"
    output:
      type: "ProcessOutput"
      description: "Processing result with statistics"
    taskQueue: "data-processing-queue"
```

## Troubleshooting

### Connection Refused
- Verify `TEMPORAL_HOST_PORT` is correct
- Ensure the MCP server pod can reach your Temporal server (check network policies)

### Workflow Not Found
- Ensure the workflow is registered in Temporal
- Check that the workflow name in config matches exactly

### No Workflows Available
- Verify your `TEMPORAL_MCP_CONFIG` or config file is valid YAML
- Check the MCP server logs for configuration errors

## Building from Source

```bash
# Clone the repository
git clone https://github.com/archestra-ai/temporal-mcp.git
cd temporal-mcp

# Build for local testing
go build -o temporal-mcp ./cmd/temporal-mcp

# Build multi-arch Docker image
docker buildx build --platform linux/amd64,linux/arm64 \
  -t your-registry/temporal-mcp:latest \
  --push .
```

## License

MIT License - see the original [temporal-mcp](https://github.com/Mocksi/temporal-mcp) repository.
