# Variables
JPM = jpm
BUILD_DIR = build
TREE_DIR = jpm_tree
BINARY_NAME = munin

.PHONY: all clean deps build test help

all: deps build

# Install dependencies from the lockfile into the local jpm_tree
deps:
	@echo "Installing dependencies from lockfile..."
	$(JPM) -l load-lockfile

# Build the executable using the local jpm_tree
build:
	@echo "Building executable..."
	$(JPM) -l build

test:
	@echo "Running tests..."
	$(JPM) test

# Clean up build artifacts and the local dependency tree
clean:
	@echo "Cleaning up..."
	rm -rf $(BUILD_DIR)
	rm -rf $(TREE_DIR)

# Show help
help:
	@echo "Available targets:"
	@echo "  make deps   - Install dependencies from lockfile.jdn"
	@echo "  make build  - Build the Janet executable"
	@echo "  make test   - Run tests"
	@echo "  make all    - Install deps and build (default)"
	@echo "  make clean  - Remove build artifacts and jpm_tree"
