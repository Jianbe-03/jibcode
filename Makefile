# Top-level Makefile for JibCode Compiler
ARCH ?= arm64  # Default architecture

# Supported architectures (add more as you create folders)
SUPPORTED_ARCHS := arm64

# Check if ARCH is valid
ifeq ($(filter $(ARCH),$(SUPPORTED_ARCHS)),)
  $(error Unsupported architecture: $(ARCH). Supported: $(SUPPORTED_ARCHS))
endif

# Paths
ARCH_DIR := architectures/$(ARCH)
OUTPUT_DIR := outputs/$(ARCH)

# Ensure output directory exists
$(shell mkdir -p $(OUTPUT_DIR))

# Default target
all: buildCompiler

# Build the compiler for the selected architecture
buildCompiler:
	@echo "Building compiler for $(ARCH)..."
	$(MAKE) -C $(ARCH_DIR) compiler
	@echo "Compiler for $(ARCH) built successfully in $(ARCH_DIR)/."

# Compile JibCode to assembly for the selected architecture
compile: buildCompiler
	@echo "Compiling JibCode for $(ARCH)..."
	$(MAKE) -C $(ARCH_DIR) compile
	@echo "Compiled for $(ARCH). Output in $(OUTPUT_DIR)/."

# Clean up for specific architecture
clean:
	@echo "Cleaning for $(ARCH)..."
	$(MAKE) -C $(ARCH_DIR) clean
	@echo "Cleaned $(ARCH)."

# Clean all architectures
clean-all:
	@echo "Cleaning all architectures..."
	for arch in $(SUPPORTED_ARCHS); do \
		$(MAKE) -C architectures/$$arch clean; \
	done
	@echo "All architectures cleaned."

# Test compilation and execution
test: compile
	@echo "Testing for $(ARCH)..."
	$(MAKE) -C $(ARCH_DIR) test
	@echo "Test completed for $(ARCH)."

# Run the compiled program
run: compile
	@echo "Running compiled program for $(ARCH)..."
	$(MAKE) -C $(ARCH_DIR) run
	@echo "Program executed for $(ARCH)."

# Help
help:
	@echo "Usage: make [ARCH=<arch>] [target]"
	@echo "Supported ARCH: $(SUPPORTED_ARCHS)"
	@echo "Targets:"
	@echo "  all          - Build compiler (default)"
	@echo "  compiler     - Build the compiler binary"
	@echo "  compile      - Compile JibCode to assembly and executable"
	@echo "  run          - Compile and run the JibCode program"
	@echo "  clean        - Clean build artifacts for specified ARCH"
	@echo "  clean-all    - Clean all architectures"
	@echo "  test         - Build, compile, and run tests"
	@echo "Examples:"
	@echo "  make ARCH=arm64 run"
	@echo "  make clean ARCH=arm64"
