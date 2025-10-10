ARCH := arm64
OUTPUT_DIR := ../../../outputs/$(ARCH)

# Ensure output directory exists
$(shell mkdir -p $(OUTPUT_DIR))

all: compiler

compiler: compiler.o
	clang compiler.o -o compiler

compiler.o: compiler.s
	clang -c compiler.s -o compiler.o

output.s: compiler ../../input.jibcode
	./compiler ../../input.jibcode > $(OUTPUT_DIR)/output.s

outputerror.s: compiler ../../test_error.jibcode
	./compiler ../../test_error.jibcode > $(OUTPUT_DIR)/outputerror.s

outputif.s: compiler ../../test_if.jibcode
	./compiler ../../test_if.jibcode > $(OUTPUT_DIR)/outputif.s

compile: output.s
	clang $(OUTPUT_DIR)/output.s -o $(OUTPUT_DIR)/input

clean:
	rm -f compiler.o compiler $(OUTPUT_DIR)/output.s $(OUTPUT_DIR)/input $(OUTPUT_DIR)/outputerror.s $(OUTPUT_DIR)/outputif.s

test_error: outputerror.s
	clang $(OUTPUT_DIR)/outputerror.s -o $(OUTPUT_DIR)/input

test_if: outputif.s
	clang $(OUTPUT_DIR)/outputif.s -o $(OUTPUT_DIR)/input

test: compile
	$(OUTPUT_DIR)/input