all: clean compile

compiler: compiler.o
	clang compiler.o -o compiler

compiler.o: compiler.s
	clang -c compiler.s -o compiler.o

output.s: compiler input.jibcode
	./compiler input.jibcode > output.s

outputerror.s: compiler test_error.jibcode
	./compiler test_error.jibcode > outputerror.s

outputif.s: compiler test_if.jibcode
	./compiler test_if.jibcode > outputif.s

compile: output.s
	clang output.s -o input

clean:
	rm -f main.o main compiler.o compiler output.s input

test_error: outputerror.s
	clang outputerror.s -o input

test_if: outputif.s
	clang outputif.s -o input