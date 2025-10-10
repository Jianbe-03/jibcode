# JibCode Programming Language

A custom programming language that compiles to ARM64 assembly.

## Features

✅ **Variables**
- Numeric variables: `var x = 10;`
- String variables: `var name = "John";`
- Variable reassignment supported.
- Always encase a variable like this {x} otherwise it will not be seen as a variable by the compiler.

✅ **Math Operators**
- Addition: `{x} + {y}`
- Subtraction: `{x} - {y}`
- Multiplication: `{x} * {y}`
- Division: `{x} / {y}`
- Modulo: `{x} % {y}`

✅ **Comparison Operators** (returns 1 for true, 0 for false)
- Equal: `{x} == {y}`
- Not equal: `{x} != {y}`
- Less than: `{x} < {y}`
- Greater than: `{x} > {y}`
- Less than or equal: `{x} <= {y}`
- Greater than or equal: `{x} >= {y}`

✅ **If/Else Statement**
- You can use if statements by encasing the comparison in {}
- Example = 
```jibcode
if {{x} == 15} {
    print "x equals 15";
} else {
    print "x does not equal 15";
}
```

✅ **String Concatenation**
- `print "Hello, "{name}"!";`

✅ **Compile-time Validation**
- Requires `printTo(terminal);` before any print statements
- Shows errors in red

✅ **Expression Evaluation**
- Compile-time expression evaluation
- Mix variables and literals: `var result = {x} + 5;`

## Example Code

```jibcode
printTo(terminal);

var x = 15;
var y = 4;
var sum = {x} + {y};
var mod = {x} % {y};
var isGreater = {x} > {y};

print "x = "{x}", y = "{y};
print "sum = "{sum};
print "mod = "{mod};
print "x > y: "{isGreater};
```

## Building and Running

```bash
# Compile JibCode to assembly
make

# Run the compiled program
./input
```

## Roadmap

### Coming Soon
- [ ] Nested if/else statements
- [ ] Multi mathematical operations in a single var
- [ ] Comments (// and /* */)
- [ ] Loops (while, for)
- [ ] Functions
- [ ] Arrays

## Architecture

- **Compiler**: Written in ARM64 assembly (`compiler.s`)
- **Output**: Generates ARM64 assembly code
- **Evaluation**: Compile-time expression evaluation
- **Platform**: macOS ARM64 (Apple Silicon)
