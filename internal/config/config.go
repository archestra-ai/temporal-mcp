package config

import (
	"fmt"
	"os"
	"strings"

	"gopkg.in/yaml.v3"
)

// Config holds the top-level configuration
type Config struct {
	Temporal  TemporalConfig         `yaml:"temporal"`
	Workflows map[string]WorkflowDef `yaml:"workflows"`
}

// TemporalConfig defines connection settings for Temporal service
type TemporalConfig struct {
	HostPort         string `yaml:"hostPort"`
	Namespace        string `yaml:"namespace"`
	Environment      string `yaml:"environment"`
	Timeout          string `yaml:"timeout,omitempty"`
	DefaultTaskQueue string `yaml:"defaultTaskQueue,omitempty"`
}

// WorkflowDef describes a Temporal workflow exposed as a tool
type WorkflowDef struct {
	Purpose          string       `yaml:"purpose"`
	Input            ParameterDef `yaml:"input"`
	Output           ParameterDef `yaml:"output"`
	TaskQueue        string       `yaml:"taskQueue"`
	WorkflowIDRecipe string       `yaml:"workflowIDRecipe"`
}

// ParameterDef defines input/output schema for a workflow
type ParameterDef struct {
	Type        string              `yaml:"type"`
	Fields      []map[string]string `yaml:"fields"`
	Description string              `yaml:"description,omitempty"`
}

// LoadConfig reads and parses configuration from file or environment variables.
// Priority:
// 1. If TEMPORAL_MCP_CONFIG env var is set, parse it as YAML
// 2. If TEMPORAL_MCP_CONFIG_FILE env var is set, read from that path
// 3. Otherwise, read from the provided path argument
// 
// Additionally, individual Temporal connection settings can be overridden via env vars:
// - TEMPORAL_HOST_PORT (default: localhost:7233)
// - TEMPORAL_NAMESPACE (default: default)
// - TEMPORAL_ENVIRONMENT (default: local)
// - TEMPORAL_TIMEOUT (default: 5s)
// - TEMPORAL_DEFAULT_TASK_QUEUE
func LoadConfig(path string) (*Config, error) {
	var cfg Config
	var data []byte
	var err error

	// Check for inline YAML config in env var first
	if configYAML := os.Getenv("TEMPORAL_MCP_CONFIG"); configYAML != "" {
		data = []byte(configYAML)
	} else {
		// Determine config file path
		configPath := path
		if envPath := os.Getenv("TEMPORAL_MCP_CONFIG_FILE"); envPath != "" {
			configPath = envPath
		}

		// Read config file
		data, err = os.ReadFile(configPath)
		if err != nil {
			// If no config file and no env var, create minimal config
			if os.IsNotExist(err) && os.Getenv("TEMPORAL_MCP_CONFIG") == "" {
				cfg = Config{
					Workflows: make(map[string]WorkflowDef),
				}
			} else {
				return nil, fmt.Errorf("failed to read config file %s: %w", configPath, err)
			}
		}
	}

	// Parse YAML if we have data
	if len(data) > 0 {
		if err := yaml.Unmarshal(data, &cfg); err != nil {
			return nil, fmt.Errorf("failed to parse config YAML: %w", err)
		}
	}

	// Apply environment variable overrides for Temporal connection settings
	applyEnvOverrides(&cfg)

	// Validate required settings
	if cfg.Temporal.HostPort == "" {
		return nil, fmt.Errorf("temporal hostPort is required (set via config or TEMPORAL_HOST_PORT env var)")
	}

	return &cfg, nil
}

// applyEnvOverrides applies environment variable overrides to the config
func applyEnvOverrides(cfg *Config) {
	// Override Temporal connection settings from env vars
	if hostPort := os.Getenv("TEMPORAL_HOST_PORT"); hostPort != "" {
		cfg.Temporal.HostPort = hostPort
	} else if cfg.Temporal.HostPort == "" {
		cfg.Temporal.HostPort = "localhost:7233"
	}

	if namespace := os.Getenv("TEMPORAL_NAMESPACE"); namespace != "" {
		cfg.Temporal.Namespace = namespace
	} else if cfg.Temporal.Namespace == "" {
		cfg.Temporal.Namespace = "default"
	}

	if environment := os.Getenv("TEMPORAL_ENVIRONMENT"); environment != "" {
		cfg.Temporal.Environment = strings.ToLower(environment)
	} else if cfg.Temporal.Environment == "" {
		cfg.Temporal.Environment = "local"
	}

	if timeout := os.Getenv("TEMPORAL_TIMEOUT"); timeout != "" {
		cfg.Temporal.Timeout = timeout
	} else if cfg.Temporal.Timeout == "" {
		cfg.Temporal.Timeout = "5s"
	}

	if taskQueue := os.Getenv("TEMPORAL_DEFAULT_TASK_QUEUE"); taskQueue != "" {
		cfg.Temporal.DefaultTaskQueue = taskQueue
	}
}
