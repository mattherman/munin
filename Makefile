# Variables
JPM = jpm
BUILD_DIR = build
TREE_DIR = jpm_tree
BINARY_NAME = munin

.PHONY: all build test help

all: build

# Build the executable using the local jpm_tree
build:
	@echo "Building executable..."
	$(JPM) -l clean && $(JPM) -l build

test:
	@echo "Running tests..."
	$(JPM) test

# Show help
help:
	@echo "Available targets:"
	@echo "  make build  - Build the Janet executable"
	@echo "  make test   - Run tests"
	@echo "  make all    - Install deps and build (default)"
