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

✅ **Nested If/Else Statements**
- Full support for nested if/else blocks
- Example:
```jibcode
if {{x} > 10} {
    print "x is greater than 10";
    if {{x} > 20} {
        print "x is also greater than 20";
    } else {
        print "x is between 10 and 20";
    }
} else {
    print "x is 10 or less";
}
```

✅ **Multi-Operation Expressions**
- Support for multiple operations in a single expression
- Example: `var result = {a} + {b} + {c} - {d};`
- Note: Currently evaluates left-to-right (no operator precedence yet)

✅ **Comments**
- Single-line comments: `// This is a comment`
- Multi-line comments: `/* This is a multi-line comment */`

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

make compile

# Run the compiled program
make run
```

This will build a ARM64 assembly program and run it.

If you want a different supported architecture you can for example do:

```bash
make ARCH=x86_60

make compile ARCH=x86_60

make run ARCH=x86_60
```

Currently only ARM64 is supported.

## Roadmap

### Coming Soon
- [ ] Operator precedence (e.g., `*` and `/` before `+` and `-`)
- [ ] Parentheses support in expressions
- [ ] Loops (while, for)
- [ ] Functions
- [ ] Arrays
- [ ] Boolean operators (&&, ||, !)
- [ ] More architectures (x86_64, RISC-V)
- [ ] or/and operations for if/else statements

## Architecture

- **Compiler**: Written in ARM64 assembly (`compiler.s`)
- **Output**: Generates ARM64 assembly code
- **Evaluation**: Compile-time expression evaluation
- **Platform**: macOS ARM64 (Apple Silicon)
