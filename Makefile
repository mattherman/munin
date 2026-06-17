# Variables
JPM = jpm
BUILD_DIR = ./build
TREE_DIR = ./jpm_tree
BINARY_NAME = munin

.PHONY: deps build test run repl help

deps:
	@echo "Installing dependencies..."
	$(JPM) -l deps

# Build the executable using the local jpm_tree
build:
	@echo "Building executable..."
	$(JPM) -l clean && $(JPM) -l build

test:
	@echo "Running tests..."
	$(JPM) -l test

run:
	$(BUILD_DIR)/munin build

repl:
	$(JPM) -l janet

# Show help
help:
	@echo "Available targets:"
	@echo "  make deps   - Install dependendencies
	@echo "  make build  - Build the Janet executable"
	@echo "  make test   - Run tests"
	@echo "  make run"   - Run the application"
	@echo "  make repl   - Start REPL"
