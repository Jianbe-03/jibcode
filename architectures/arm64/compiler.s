.text
.extern _open
.extern _read
.extern _close
.extern _write
.extern _exit

.global _main
_main:
    // Save frame pointer
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    // Initialize nesting depth counter
    mov x9, #0
    
    // Check if we have a command-line argument for filename
    // x0 = argc, x1 = argv
    // Default to "input.jibcode" if no argument provided
    cmp x0, #2
    b.lt use_default_filename
    
    // Use argv[1] as filename
    ldr x0, [x1, #8]  // argv[1]
    b open_file
    
use_default_filename:
    adrp x0, default_filename@PAGE
    add x0, x0, default_filename@PAGEOFF

open_file:
    // Open the file
    mov x1, #0  // O_RDONLY
    bl _open
    cmp x0, #0
    b.lt error
    mov x19, x0  // Save file descriptor

    // Read file into buffer
    mov x0, x19
    adrp x1, inputBuffer@PAGE
    add x1, x1, inputBuffer@PAGEOFF
    mov x2, #4096  // Increased buffer size
    bl _read
    mov x20, x0  // Save bytes read

    // Close file
    mov x0, x19
    bl _close

    // Check for printTo(terminal); - search for "printTo" in input
    adrp x21, inputBuffer@PAGE
    add x21, x21, inputBuffer@PAGEOFF
    mov x22, #0
    mov x15, #0  // Flag: 0 = not found, 1 = found

check_printTo:
    cmp x22, x20
    b.ge check_printTo_done
    
    // Check if we have enough chars for "printTo"
    add x23, x22, #7
    cmp x23, x20
    b.gt skip_check
    
    // Check for 'p'
    ldrb w0, [x21, x22]
    cmp w0, #'p'
    b.ne next_char
    
    // Check for 'r'
    add x23, x22, #1
    ldrb w0, [x21, x23]
    cmp w0, #'r'
    b.ne next_char
    
    // Check for 'i'
    add x23, x22, #2
    ldrb w0, [x21, x23]
    cmp w0, #'i'
    b.ne next_char
    
    // Check for 'n'
    add x23, x22, #3
    ldrb w0, [x21, x23]
    cmp w0, #'n'
    b.ne next_char
    
    // Check for 't'
    add x23, x22, #4
    ldrb w0, [x21, x23]
    cmp w0, #'t'
    b.ne next_char
    
    // Check for 'T'
    add x23, x22, #5
    ldrb w0, [x21, x23]
    cmp w0, #'T'
    b.ne next_char
    
    // Check for 'o'
    add x23, x22, #6
    ldrb w0, [x21, x23]
    cmp w0, #'o'
    b.ne next_char
    
    // Found printTo!
    mov x15, #1
    b check_printTo_done

next_char:
    add x22, x22, #1
    b check_printTo

skip_check:
    add x22, x22, #1
    b check_printTo

check_printTo_done:
    // Now check if there's a print statement
    mov x22, #0
    mov x16, #0  // Flag: 0 = no print found, 1 = print found

check_for_print:
    cmp x22, x20
    b.ge validation_done
    
    // Check for "print" (5 chars)
    add x23, x22, #5
    cmp x23, x20
    b.gt skip_print_check
    
    ldrb w0, [x21, x22]
    cmp w0, #'p'
    b.ne next_print_char
    
    add x23, x22, #1
    ldrb w0, [x21, x23]
    cmp w0, #'r'
    b.ne next_print_char
    
    add x23, x22, #2
    ldrb w0, [x21, x23]
    cmp w0, #'i'
    b.ne next_print_char
    
    add x23, x22, #3
    ldrb w0, [x21, x23]
    cmp w0, #'n'
    b.ne next_print_char
    
    add x23, x22, #4
    ldrb w0, [x21, x23]
    cmp w0, #'t'
    b.ne next_print_char
    
    // Check if next char is 'T' (printTo) or not (print)
    add x23, x22, #5
    cmp x23, x20
    b.ge found_print_stmt
    ldrb w0, [x21, x23]
    cmp w0, #'T'
    b.eq next_print_char
    
found_print_stmt:
    mov x16, #1
    b validation_done

next_print_char:
    add x22, x22, #1
    b check_for_print

skip_print_check:
    add x22, x22, #1
    b check_for_print

validation_done:
    // If print found but no printTo, show error
    cmp x16, #1
    b.ne continue_compile
    cmp x15, #1
    b.eq continue_compile
    
    // Error: print without printTo
    mov x0, #2  // stderr
    adrp x1, error_msg@PAGE
    add x1, x1, error_msg@PAGEOFF
    mov x2, #error_msg_len
    bl _write
    mov x0, #1
    bl _exit

continue_compile:
    // Initialize output buffer for combined strings
    adrp x28, outputBuffer@PAGE
    add x28, x28, outputBuffer@PAGEOFF
    mov x29, #0  // Total output length

    // Initialize variable storage
    adrp x13, varBuffer@PAGE
    add x13, x13, varBuffer@PAGEOFF
    mov x14, #0  // Number of variables
    
    mov x17, #0  // Flag: 0 = not in print statement, 1 = in print statement

    // Parse all var and print statements
    mov x22, #0  // Current position in input

parse_loop:
    cmp x22, x20
    b.ge done_parsing

    // Check for comments first
    ldrb w0, [x21, x22]
    cmp w0, #'/'
    b.eq check_comment

    // Check for "if" keyword
    add x23, x22, #2
    cmp x23, x20
    b.gt check_print_keyword
    
    ldrb w0, [x21, x22]
    cmp w0, #'i'
    b.ne check_print_keyword
    
    add x23, x22, #1
    ldrb w0, [x21, x23]
    cmp w0, #'f'
    b.ne check_print_keyword
    
    // Check next char is whitespace or {
    add x23, x22, #2
    cmp x23, x20
    b.ge parse_if
    ldrb w0, [x21, x23]
    cmp w0, #' '
    b.eq parse_if
    cmp w0, #'\t'
    b.eq parse_if
    cmp w0, #'{'
    b.eq parse_if
    b check_print_keyword

check_comment:
    // Check if this is // or /*
    add x23, x22, #1
    cmp x23, x20
    b.ge parse_error  // Single / at end of file
    
    ldrb w0, [x21, x23]
    cmp w0, #'/'  // Single line comment //
    b.eq skip_single_comment
    cmp w0, #'*'  // Multi line comment /*
    b.eq skip_multi_comment
    b parse_error  // Just a single / which is invalid

skip_single_comment:
    // Skip until end of line or end of file
    add x22, x22, #2  // Skip the //
skip_single_loop:
    cmp x22, x20
    b.ge parse_loop
    ldrb w0, [x21, x22]
    cmp w0, #'\n'
    b.eq skip_single_done
    add x22, x22, #1
    b skip_single_loop
skip_single_done:
    add x22, x22, #1  // Skip the newline
    b parse_loop

skip_multi_comment:
    // Skip until */ or end of file
    add x22, x22, #2  // Skip the /*
skip_multi_loop:
    cmp x22, x20
    b.ge parse_error  // Unclosed comment
    ldrb w0, [x21, x22]
    cmp w0, #'*'
    b.ne skip_multi_next
    // Check if next char is /
    add x23, x22, #1
    cmp x23, x20
    b.ge parse_error  // * at end of file
    ldrb w0, [x21, x23]
    cmp w0, #'/'
    b.eq skip_multi_done
skip_multi_next:
    add x22, x22, #1
    b skip_multi_loop
skip_multi_done:
    add x22, x22, #2  // Skip the */
    b parse_loop

parse_if:
    // Skip "if" and find condition
    add x22, x22, #2
    
    // Skip whitespace
skip_if_ws:
    cmp x22, x20
    b.ge parse_error
    ldrb w0, [x21, x22]
    cmp w0, #' '
    b.eq skip_if_ws_inc
    cmp w0, #'\t'
    b.eq skip_if_ws_inc
    cmp w0, #'{'
    b.eq found_if_cond
    b parse_error

skip_if_ws_inc:
    add x22, x22, #1
    b skip_if_ws

found_if_cond:
    // x22 points to opening { of condition
    add x22, x22, #1
    mov x24, x22  // Start of condition
    mov x25, #0   // Length
    mov x26, #1   // Brace depth (already inside one opening brace)

    // Find closing } while respecting nested braces
find_cond_end:
    add x23, x22, x25
    cmp x23, x20
    b.ge parse_error
    ldrb w0, [x21, x23]
    cmp w0, #'{'
    b.eq cond_depth_inc
    cmp w0, #'}'
    b.eq cond_depth_dec
    add x25, x25, #1
    b find_cond_end

cond_depth_inc:
    add x26, x26, #1
    add x25, x25, #1
    b find_cond_end

cond_depth_dec:
    sub x26, x26, #1
    cbz x26, eval_if_condition
    add x25, x25, #1
    b find_cond_end

eval_if_condition:
    // Evaluate condition (reuse expression evaluator)
    // x24 = condition start, x25 = length
    mov x4, #0   // Second operand
    mov x5, #0   // Position in condition
    mov x6, #0   // Result
    mov x7, #0   // Operator
    mov x8, #0   // Have operator flag
    
eval_cond_loop:
    cmp x5, x25
    b.ge cond_done
    
    add x23, x24, x5
    ldrb w0, [x21, x23]
    
    // Skip whitespace
    cmp w0, #' '
    b.eq cond_skip_ws
    cmp w0, #'\t'
    b.eq cond_skip_ws
    
    // Check for variable reference
    cmp w0, #'{'
    b.eq cond_var_ref
    cmp w0, #'a'
    b.lt cond_check_upper
    cmp w0, #'z'
    b.le cond_invalid_token

cond_check_upper:
    cmp w0, #'A'
    b.lt cond_check_underscore
    cmp w0, #'Z'
    b.le cond_invalid_token

cond_check_underscore:
    cmp w0, #'_'
    b.eq cond_invalid_token
    
    // Check for operators
    cmp w0, #'+'
    b.eq cond_op_single
    cmp w0, #'-'
    b.eq cond_op_single
    cmp w0, #'*'
    b.eq cond_op_single
    cmp w0, #'/'
    b.eq cond_op_single
    cmp w0, #'%'
    b.eq cond_op_single
    cmp w0, #'<'
    b.eq cond_op_maybe_double
    cmp w0, #'>'
    b.eq cond_op_maybe_double
    cmp w0, #'='
    b.eq cond_op_must_double
    cmp w0, #'!'
    b.eq cond_op_must_double
    
    // Must be a number
    b cond_parse_num

cond_skip_ws:
    add x5, x5, #1
    b eval_cond_loop

cond_op_single:
    mov x7, x0
    mov x8, #1
    add x5, x5, #1
    b eval_cond_loop

cond_op_maybe_double:
    // Check if next char is =
    add x23, x24, x5
    add x23, x23, #1
    cmp x23, x20
    b.ge cond_op_single
    ldrb w1, [x21, x23]
    cmp w1, #'='
    b.ne cond_op_single
    // It's <= or >=
    cmp w0, #'<'
    b.eq set_cond_le
    mov x7, #259  // >=
    mov x8, #1
    add x5, x5, #2
    b eval_cond_loop

set_cond_le:
    mov x7, #258  // <=
    mov x8, #1
    add x5, x5, #2
    b eval_cond_loop

cond_op_must_double:
    // Must be == or !=
    add x23, x24, x5
    add x23, x23, #1
    cmp x23, x20
    b.ge parse_error
    ldrb w1, [x21, x23]
    cmp w1, #'='
    b.ne parse_error
    cmp w0, #'='
    b.eq set_cond_eq
    mov x7, #257  // !=
    mov x8, #1
    add x5, x5, #2
    b eval_cond_loop

set_cond_eq:
    mov x7, #256  // ==
    mov x8, #1
    add x5, x5, #2
    b eval_cond_loop

cond_parse_num:
    mov x9, #0
cond_digit_loop:
    cmp x5, x25
    b.ge cond_num_done
    add x23, x24, x5
    ldrb w0, [x21, x23]
    cmp w0, #'0'
    b.lt cond_num_done
    cmp w0, #'9'
    b.gt cond_num_done
    mov x10, #10
    mul x9, x9, x10
    sub x0, x0, #'0'
    add x9, x9, x0
    add x5, x5, #1
    b cond_digit_loop

cond_num_done:
    cmp x8, #0
    b.eq store_cond_first
    mov x4, x9
    b apply_cond_op

store_cond_first:
    mov x6, x9
    b eval_cond_loop

cond_invalid_token:
    // Skip over an identifier-like token and treat as zero literal
    mov x9, #0
cond_invalid_loop:
    add x10, x23, x9
    sub x11, x10, x24
    cmp x11, x25
    b.ge cond_invalid_done
    ldrb w1, [x21, x10]
    cmp w1, #' '
    b.eq cond_invalid_done
    cmp w1, #'\t'
    b.eq cond_invalid_done
    cmp w1, #'+' 
    b.eq cond_invalid_done
    cmp w1, #'-'
    b.eq cond_invalid_done
    cmp w1, #'*'
    b.eq cond_invalid_done
    cmp w1, #'/'
    b.eq cond_invalid_done
    cmp w1, #'%'
    b.eq cond_invalid_done
    cmp w1, #'<'
    b.eq cond_invalid_done
    cmp w1, #'>'
    b.eq cond_invalid_done
    cmp w1, #'='
    b.eq cond_invalid_done
    cmp w1, #'!'
    b.eq cond_invalid_done
    cmp w1, #'}'
    b.eq cond_invalid_done
    add x9, x9, #1
    b cond_invalid_loop

cond_invalid_done:
    add x5, x5, x9
    cmp x8, #0
    b.eq store_cond_invalid_first
    mov x4, #0
    b apply_cond_op

store_cond_invalid_first:
    mov x6, #0
    b eval_cond_loop

cond_var_ref:
    // Parse variable reference wrapped in {}
    add x5, x5, #1
    add x23, x24, x5
    b cond_var_count_start

cond_var_count_start:
    mov x9, #0

cond_var_count_loop:
    add x10, x23, x9
    // Bounds check - make sure we don't read past condition end
    sub x11, x10, x24  // x11 = offset from condition start
    cmp x11, x25  // Compare with condition length
    b.ge lookup_cond_var  // If we've gone past condition end, treat as end of name
    ldrb w0, [x21, x10]
    // Variable name ends at space, tab, operator, or closing brace
    cmp w0, #' '
    b.eq lookup_cond_var
    cmp w0, #'	'
    b.eq lookup_cond_var
    cmp w0, #'+'
    b.eq lookup_cond_var
    cmp w0, #'-'
    b.eq lookup_cond_var
    cmp w0, #'*'
    b.eq lookup_cond_var
    cmp w0, #'/'
    b.eq lookup_cond_var
    cmp w0, #'%'
    b.eq lookup_cond_var
    cmp w0, #'<'
    b.eq lookup_cond_var
    cmp w0, #'>'
    b.eq lookup_cond_var
    cmp w0, #'='
    b.eq lookup_cond_var
    cmp w0, #'!'
    b.eq lookup_cond_var
    cmp w0, #'}'
    b.eq lookup_cond_var
    add x9, x9, #1
    b cond_var_count_loop

lookup_cond_var:
    // Look up variable: x23 = var name start, x9 = length
    mov x10, #0
find_cond_var_loop:
    cmp x10, x14
    b.ge parse_error
    mov x11, x10
    lsl x11, x11, #6
    add x11, x13, x11
    mov x12, #0
cmp_cond_var_loop:
    cmp x12, x9
    b.ge check_cond_var_match
    ldrb w0, [x11, x12]
    add x15, x23, x12
    ldrb w1, [x21, x15]
    cmp w0, w1
    b.ne next_cond_var
    add x12, x12, #1
    b cmp_cond_var_loop

check_cond_var_match:
    ldrb w0, [x11, x12]
    cbz w0, found_cond_var
next_cond_var:
    add x10, x10, #1
    b find_cond_var_loop

found_cond_var:
    // Get variable value
    mov x11, x10
    lsl x11, x11, #6
    add x11, x11, #32
    add x11, x13, x11
    mov x12, #0
    mov x15, #0
cond_var_to_num:
    ldrb w0, [x11, x15]
    cbz w0, cond_var_num_done
    cmp w0, #'0'
    b.lt cond_var_num_done
    cmp w0, #'9'
    b.gt cond_var_num_done
    mov x16, #10
    mul x12, x12, x16
    sub x0, x0, #'0'
    add x12, x12, x0
    add x15, x15, #1
    b cond_var_to_num

cond_var_num_done:
    add x5, x5, x9  // Skip past variable name (no closing } in condition)
    // Skip optional closing brace if variable was wrapped in {}
    cmp x5, x25
    b.ge cond_var_after_skip
    add x23, x24, x5
    ldrb w0, [x21, x23]
    cmp w0, #'}'
    b.ne cond_var_after_skip
    add x5, x5, #1

cond_var_after_skip:
    cmp x8, #0
    b.eq store_cond_first_var
    mov x4, x12
    b apply_cond_op

store_cond_first_var:
    mov x6, x12
    b eval_cond_loop

apply_cond_op:
    // Apply operator: x6 op x4 -> x6
    cmp x7, #'+'
    b.eq cond_add
    cmp x7, #'-'
    b.eq cond_sub
    cmp x7, #'*'
    b.eq cond_mul
    cmp x7, #'/'
    b.eq cond_div
    cmp x7, #'%'
    b.eq cond_mod
    cmp x7, #256
    b.eq cond_eq
    cmp x7, #257
    b.eq cond_ne
    cmp x7, #'<'
    b.eq cond_lt
    cmp x7, #'>'
    b.eq cond_gt
    cmp x7, #258
    b.eq cond_le
    cmp x7, #259
    b.eq cond_ge
    b eval_cond_loop

cond_add:
    add x6, x6, x4
    mov x8, #0
    b eval_cond_loop
cond_sub:
    sub x6, x6, x4
    mov x8, #0
    b eval_cond_loop
cond_mul:
    mul x6, x6, x4
    mov x8, #0
    b eval_cond_loop
cond_div:
    udiv x6, x6, x4
    mov x8, #0
    b eval_cond_loop
cond_mod:
    udiv x10, x6, x4
    msub x6, x10, x4, x6
    mov x8, #0
    b eval_cond_loop
cond_eq:
    cmp x6, x4
    cset x6, eq
    mov x8, #0
    b eval_cond_loop
cond_ne:
    cmp x6, x4
    cset x6, ne
    mov x8, #0
    b eval_cond_loop
cond_lt:
    cmp x6, x4
    cset x6, lt
    mov x8, #0
    b eval_cond_loop
cond_gt:
    cmp x6, x4
    cset x6, gt
    mov x8, #0
    b eval_cond_loop
cond_le:
    cmp x6, x4
    cset x6, le
    mov x8, #0
    b eval_cond_loop
cond_ge:
    cmp x6, x4
    cset x6, ge
    mov x8, #0
    b eval_cond_loop

cond_done:
    // x6 has condition result (0=false, nonzero=true)
    // Move past condition } and find if block
    add x22, x24, x25
    add x22, x22, #1  // Skip }
    
    // Skip whitespace to find if block {
skip_to_if_block:
    cmp x22, x20
    b.ge parse_error
    ldrb w0, [x21, x22]
    cmp w0, #' '
    b.eq skip_to_if_block_inc
    cmp w0, #'\t'
    b.eq skip_to_if_block_inc
    cmp w0, #'{'
    b.eq found_if_block
    b parse_error

skip_to_if_block_inc:
    add x22, x22, #1
    b skip_to_if_block

found_if_block:
    // x22 points to { of if block
    add x22, x22, #1
    mov x24, x22  // Start of if block content
    mov x25, #0   // Length
    mov x26, #1   // Brace depth
    
    // Find matching closing }
find_if_block_end:
    add x23, x22, x25
    cmp x23, x20
    b.ge parse_error
    ldrb w0, [x21, x23]
    cmp w0, #'{'
    b.eq if_open_brace
    cmp w0, #'}'
    b.eq if_close_brace
    add x25, x25, #1
    b find_if_block_end

if_open_brace:
    add x26, x26, #1
    add x25, x25, #1
    b find_if_block_end

if_close_brace:
    sub x26, x26, #1
    cbz x26, if_block_complete
    add x25, x25, #1
    b find_if_block_end

if_block_complete:
    // x24 = if block start, x25 = if block length, x6 = condition result
    // Move past if block
    add x22, x24, x25
    add x22, x22, #1  // Position after }
    
    // Check for else
    mov x27, x22  // Save position after if
    
skip_to_else:
    cmp x22, x20
    b.ge check_if_result
    ldrb w0, [x21, x22]
    cmp w0, #' '
    b.eq skip_to_else_inc
    cmp w0, #'\t'
    b.eq skip_to_else_inc
    cmp w0, #'\n'
    b.eq skip_to_else_inc
    
    // Check for "else"
    add x23, x22, #4
    cmp x23, x20
    b.gt check_if_result
    ldrb w0, [x21, x22]
    cmp w0, #'e'
    b.ne check_if_result
    add x23, x22, #1
    ldrb w0, [x21, x23]
    cmp w0, #'l'
    b.ne check_if_result
    add x23, x22, #2
    ldrb w0, [x21, x23]
    cmp w0, #'s'
    b.ne check_if_result
    add x23, x22, #3
    ldrb w0, [x21, x23]
    cmp w0, #'e'
    b.ne check_if_result
    
    // Found else - skip "else" and find else block
    add x22, x22, #4
    b skip_to_else_block

skip_to_else_inc:
    add x22, x22, #1
    b skip_to_else

skip_to_else_block:
    cmp x22, x20
    b.ge parse_error
    ldrb w0, [x21, x22]
    cmp w0, #' '
    b.eq skip_to_else_block_inc
    cmp w0, #'\t'
    b.eq skip_to_else_block_inc
    cmp w0, #'{'
    b.eq found_else_block
    b parse_error

skip_to_else_block_inc:
    add x22, x22, #1
    b skip_to_else_block

found_else_block:
    // x22 points to { of else block
    add x22, x22, #1
    mov x27, x22  // Start of else block
    mov x16, #0   // Length
    mov x26, #1   // Brace depth
    
find_else_block_end:
    add x23, x22, x16
    cmp x23, x20
    b.ge parse_error
    ldrb w0, [x21, x23]
    cmp w0, #'{'
    b.eq else_open_brace
    cmp w0, #'}'
    b.eq else_close_brace
    add x16, x16, #1
    b find_else_block_end

else_open_brace:
    add x26, x26, #1
    add x16, x16, #1
    b find_else_block_end

else_close_brace:
    sub x26, x26, #1
    cbz x26, else_block_complete
    add x16, x16, #1
    b find_else_block_end

else_block_complete:
    // x27 = else block start, x16 = else block length
    // Move past else block
    add x22, x27, x16
    add x22, x22, #1
    
    // Now decide which block to include
    cbz x6, include_else_block
    // Condition true - include if block (x24, x25)
    mov x27, x24
    mov x16, x25
    b include_chosen_block

include_else_block:
    // Condition false - x27 and x28 already have else block
    
include_chosen_block:
    // Copy chosen block content to continue parsing
    // x27 = start of chosen block, x16 = length of chosen block
    // x22 = position after entire if/else statement
    // x20 = original end of input (we need to save this!)
    
    add x18, x18, #1  // Increment nesting depth
    stp x22, x20, [sp, #-16]!  // Save position after if/else and original end
    
    mov x22, x27  // Start parsing from chosen block
    add x20, x27, x16  // Parse until end of chosen block
    b parse_loop

check_if_result:
    // No else block - just use if block if condition is true
    cbz x6, skip_if_only
    // Include if block
    // x24 = if block start, x25 = if block length
    // x27 = position after if block
    // x20 = original end
    add x18, x18, #1  // Increment nesting depth
    stp x27, x20, [sp, #-16]!  // Save position after if and original end
    mov x22, x24  // Start of if block
    add x20, x24, x25  // End of if block
    b parse_loop

skip_if_only:
    // Skip if block entirely
    mov x22, x27
    b parse_loop

check_print_keyword:
    cmp x23, x20
    b.gt check_var_stmt
    
    ldrb w0, [x21, x22]
    cmp w0, #'p'
    b.ne check_var_stmt
    
    add x23, x22, #1
    ldrb w0, [x21, x23]
    cmp w0, #'r'
    b.ne check_var_stmt
    
    add x23, x22, #2
    ldrb w0, [x21, x23]
    cmp w0, #'i'
    b.ne check_var_stmt
    
    add x23, x22, #3
    ldrb w0, [x21, x23]
    cmp w0, #'n'
    b.ne check_var_stmt
    
    add x23, x22, #4
    ldrb w0, [x21, x23]
    cmp w0, #'t'
    b.ne check_var_stmt
    
    // Check if next char is space or not 'T' (to avoid printTo)
    add x23, x22, #5
    cmp x23, x20
    b.ge found_print_keyword
    ldrb w0, [x21, x23]
    cmp w0, #'T'
    b.eq check_var_stmt
    
found_print_keyword:
    // We're entering a print statement
    mov x17, #1
    add x22, x22, #5
    b parse_loop

check_var_stmt:
    add x23, x22, #4
    cmp x23, x20
    b.gt check_print_stmt
    
    ldrb w0, [x21, x22]
    cmp w0, #'v'
    b.ne check_print_stmt
    
    add x23, x22, #1
    ldrb w0, [x21, x23]
    cmp w0, #'a'
    b.ne check_print_stmt
    
    add x23, x22, #2
    ldrb w0, [x21, x23]
    cmp w0, #'r'
    b.ne check_print_stmt
    
    add x23, x22, #3
    ldrb w0, [x21, x23]
    cmp w0, #' '
    b.ne check_print_stmt
    
    // Found var statement - parse it
    add x22, x23, #1  // Skip past "var "
    
    // Find variable name (until '=')
    mov x24, x22  // Start of var name
    mov x25, #0   // Length of var name
find_var_name_end:
    add x23, x22, x25
    cmp x23, x20
    b.ge parse_error
    ldrb w0, [x21, x23]
    cmp w0, #' '
    b.eq found_var_name_end
    cmp w0, #'='
    b.eq found_var_name_end
    add x25, x25, #1
    b find_var_name_end

found_var_name_end:
    // Check if variable already exists
    mov x10, #0  // var index for search
check_existing_var:
    cmp x10, x14
    b.ge create_new_var  // Variable doesn't exist, create new one
    
    // Compare with existing variable name
    mov x11, x10
    lsl x11, x11, #6
    add x11, x13, x11  // Pointer to var name
    
    // Check if lengths match first
    mov x12, #0
strlen_existing:
    ldrb w0, [x11, x12]
    cbz w0, check_existing_len
    add x12, x12, #1
    b strlen_existing

check_existing_len:
    cmp x12, x25
    b.ne next_existing_var
    
    // Compare strings
    mov x12, #0
compare_existing:
    cmp x12, x25
    b.ge update_existing_var  // Found match, update it
    ldrb w0, [x11, x12]
    add x5, x24, x12
    ldrb w1, [x21, x5]
    cmp w0, w1
    b.ne next_existing_var
    add x12, x12, #1
    b compare_existing

next_existing_var:
    add x10, x10, #1
    b check_existing_var

update_existing_var:
    // Update existing variable value (x10 has the index)
    // Find the string value (after '="' and before '"')
    add x22, x24, x25  // Move to after var name
find_update_quote:
    cmp x22, x20
    b.ge parse_error
    ldrb w0, [x21, x22]
    cmp w0, #'"'
    b.eq found_update_quote
    add x22, x22, #1
    b find_update_quote

found_update_quote:
    add x22, x22, #1  // Move past opening quote
    mov x24, x22      // Start of value
    mov x25, #0       // Length of value

find_update_value_end:
    add x23, x22, x25
    cmp x23, x20
    b.ge parse_error
    ldrb w0, [x21, x23]
    cmp w0, #'"'
    b.eq found_update_value_end
    add x25, x25, #1
    b find_update_value_end

found_update_value_end:
    // Overwrite variable value
    mov x11, x10
    lsl x11, x11, #6
    add x11, x11, #32  // Offset to value part
    
    // Clear old value first (write nulls)
    mov x12, #0
clear_old_value:
    cmp x12, #32
    b.ge write_new_value
    add x23, x13, x11
    strb wzr, [x23, x12]
    add x12, x12, #1
    b clear_old_value

write_new_value:
    // Write new value
    mov x12, #0
copy_update_value:
    cmp x12, x25
    b.ge update_value_done
    add x23, x24, x12
    ldrb w0, [x21, x23]
    add x23, x13, x11
    strb w0, [x23, x12]
    add x12, x12, #1
    b copy_update_value

update_value_done:
    // Null terminate
    add x23, x13, x11
    strb wzr, [x23, x25]
    add x22, x24, x25
    add x22, x22, #1  // Move past closing quote
    b parse_loop

create_new_var:
    // Save variable name (new variable)
    mov x10, #0
    mov x11, x14
    lsl x11, x11, #6  // Each var entry is 64 bytes (32 name + 32 value), 64 = 2^6
save_var_name:
    cmp x10, x25
    b.ge save_var_name_done
    add x23, x24, x10
    ldrb w0, [x21, x23]
    add x23, x13, x11
    strb w0, [x23, x10]
    add x10, x10, #1
    b save_var_name

save_var_name_done:
    // Null terminate name
    add x23, x13, x11
    strb wzr, [x23, x25]
    
    // Find the string value (after '="' and before '"') or numeric/expression value
    add x22, x24, x25  // Move to after var name
find_var_value_start:
    cmp x22, x20
    b.ge parse_error
    ldrb w0, [x21, x22]
    cmp w0, #'='
    b.eq after_equals
    add x22, x22, #1
    b find_var_value_start

after_equals:
    add x22, x22, #1  // Move past '='
    
    // Skip whitespace
skip_ws_value:
    cmp x22, x20
    b.ge parse_error
    ldrb w0, [x21, x22]
    cmp w0, #' '
    b.eq skip_one_ws
    cmp w0, #'\t'
    b.eq skip_one_ws
    b check_value_type
skip_one_ws:
    add x22, x22, #1
    b skip_ws_value

check_value_type:
    ldrb w0, [x21, x22]
    cmp w0, #'"'
    b.eq found_var_quote
    
    // Otherwise, it's a numeric/expression value
    b parse_expression

found_var_quote:
    add x22, x22, #1  // Move past opening quote
    mov x24, x22      // Start of value
    mov x25, #0       // Length of value

find_var_value_end:
    add x23, x22, x25
    cmp x23, x20
    b.ge parse_error
    ldrb w0, [x21, x23]
    cmp w0, #'"'
    b.eq found_var_value_end
    add x25, x25, #1
    b find_var_value_end

found_var_value_end:
    // Save variable value
    mov x10, #0
    mov x11, x14
    lsl x11, x11, #6
    add x11, x11, #32  // Offset to value part
save_var_value:
    cmp x10, x25
    b.ge save_var_value_done
    add x23, x24, x10
    ldrb w0, [x21, x23]
    add x23, x13, x11
    strb w0, [x23, x10]
    add x10, x10, #1
    b save_var_value

save_var_value_done:
    // Null terminate value and save length
    add x23, x13, x11
    strb wzr, [x23, x25]
    
    add x14, x14, #1  // Increment var count
    add x22, x24, x25
    add x22, x22, #1  // Move past closing quote
    b parse_loop

parse_expression:
    // Parse numeric expression (number or {var} op {var})
    mov x24, x22      // Start of expression
    mov x25, #0       // Length
    
    // Find end of expression (semicolon)
find_expr_end:
    add x23, x22, x25
    cmp x23, x20
    b.ge parse_error
    ldrb w0, [x21, x23]
    cmp w0, #';'
    b.eq eval_expression
    add x25, x25, #1
    b find_expr_end

eval_expression:
    // Evaluate the expression
    // For now, support: number, {var}, {var} op {var}, {var} op number, number op {var}
    
    mov x4, #0   // Result accumulator
    mov x5, #0   // Position in expression
    mov x6, #0   // First operand
    mov x7, #0   // Operator ('+' '-' '*' '/')
    mov x8, #0   // Flag: 0 = need first operand, 1 = have first operand
    
parse_expr_loop:
    cmp x5, x25
    b.ge expr_complete
    
    add x23, x24, x5
    ldrb w0, [x21, x23]
    
    // Skip whitespace
    cmp w0, #' '
    b.eq skip_expr_ws
    cmp w0, #'\t'
    b.eq skip_expr_ws
    
    // Check for {var}
    cmp w0, #'{'
    b.eq parse_expr_var
    
    // Check for operator
    cmp w0, #'+'
    b.eq found_operator
    cmp w0, #'-'
    b.eq found_operator
    cmp w0, #'*'
    b.eq found_operator
    cmp w0, #'/'
    b.eq found_operator
    cmp w0, #'%'
    b.eq found_operator
    
    // Check for comparison operators (need to look ahead for ==, !=, <=, >=)
    cmp w0, #'='
    b.eq check_double_char_op
    cmp w0, #'!'
    b.eq check_double_char_op
    cmp w0, #'<'
    b.eq check_comparison_op
    cmp w0, #'>'
    b.eq check_comparison_op
    
    // Must be a digit - parse number
    b parse_expr_number

check_double_char_op:
    // Check for == or !=
    add x23, x24, x5
    add x23, x23, #1
    cmp x23, x20
    b.ge parse_expr_number  // Not a valid operator
    ldrb w1, [x21, x23]
    cmp w1, #'='
    b.ne parse_expr_number  // Not a double char operator
    
    // Encode == as 256, != as 257
    cmp w0, #'='
    b.eq found_eq_op
    // It's !=
    mov x7, #257
    mov x8, #1
    add x5, x5, #2  // Skip both chars
    b parse_expr_loop

found_eq_op:
    mov x7, #256
    mov x8, #1
    add x5, x5, #2
    b parse_expr_loop

check_comparison_op:
    // Could be < > <= >=
    add x23, x24, x5
    add x23, x23, #1
    cmp x23, x20
    b.ge single_char_comparison
    ldrb w1, [x21, x23]
    cmp w1, #'='
    b.ne single_char_comparison
    
    // It's <= or >=
    cmp w0, #'<'
    b.eq found_le_op
    // It's >=
    mov x7, #259
    mov x8, #1
    add x5, x5, #2
    b parse_expr_loop

found_le_op:
    mov x7, #258
    mov x8, #1
    add x5, x5, #2
    b parse_expr_loop

single_char_comparison:
    // It's < or >
    cmp w0, #'<'
    b.eq found_lt_op
    // It's >
    mov x7, #'>'
    mov x8, #1
    add x5, x5, #1
    b parse_expr_loop

found_lt_op:
    mov x7, #'<'
    mov x8, #1
    add x5, x5, #1
    b parse_expr_loop

skip_expr_ws:
    add x5, x5, #1
    b parse_expr_loop

found_operator:
    mov x7, x0  // Save operator
    mov x8, #1  // Mark that we have first operand
    add x5, x5, #1
    b parse_expr_loop

parse_expr_number:
    // Parse a decimal number
    mov x9, #0  // Accumulated number
parse_digit_loop:
    cmp x5, x25
    b.ge got_number
    add x23, x24, x5
    ldrb w0, [x21, x23]
    cmp w0, #'0'
    b.lt got_number
    cmp w0, #'9'
    b.gt got_number
    
    // Multiply current by 10 and add digit
    mov x10, #10
    mul x9, x9, x10
    sub x0, x0, #'0'
    add x9, x9, x0
    add x5, x5, #1
    b parse_digit_loop

got_number:
    // x9 has the number
    cmp x8, #0
    b.eq store_first_operand
    // We have operator, this is second operand
    mov x4, x9  // Second operand
    b apply_operator

store_first_operand:
    mov x6, x9  // First operand
    b parse_expr_loop

parse_expr_var:
    // Parse {varname}
    add x5, x5, #1  // Skip '{'
    add x23, x24, x5
    mov x9, #0  // var name length
count_var_name:
    add x10, x23, x9
    cmp x10, x20
    b.ge parse_error
    ldrb w0, [x21, x10]
    cmp w0, #'}'
    b.eq lookup_expr_var
    add x9, x9, #1
    b count_var_name

lookup_expr_var:
    // Look up variable value (x23 = start, x9 = length)
    mov x10, #0  // var index
find_expr_var:
    cmp x10, x14
    b.ge parse_error  // var not found
    
    mov x11, x10
    lsl x11, x11, #6
    add x11, x13, x11
    
    // Compare name
    mov x12, #0
cmp_expr_var_name:
    cmp x12, x9
    b.ge cmp_expr_var_len
    ldrb w0, [x11, x12]
    add x15, x23, x12
    ldrb w1, [x21, x15]
    cmp w0, w1
    b.ne next_expr_var
    add x12, x12, #1
    b cmp_expr_var_name

cmp_expr_var_len:
    ldrb w0, [x11, x12]
    cbz w0, found_expr_var
next_expr_var:
    add x10, x10, #1
    b find_expr_var

found_expr_var:
    // Convert var value to number (x10 = var index)
    mov x11, x10
    lsl x11, x11, #6
    add x11, x11, #32
    add x11, x13, x11  // Pointer to value string
    
    // Convert string to number
    mov x12, #0  // Result
    mov x15, #0  // Position
str_to_num:
    ldrb w0, [x11, x15]
    cbz w0, got_var_number
    cmp w0, #'0'
    b.lt got_var_number
    cmp w0, #'9'
    b.gt got_var_number
    mov x16, #10
    mul x12, x12, x16
    sub x0, x0, #'0'
    add x12, x12, x0
    add x15, x15, #1
    b str_to_num

got_var_number:
    // x12 has the number
    add x5, x5, x9
    add x5, x5, #1  // Skip '}'
    
    cmp x8, #0
    b.eq store_first_var_operand
    mov x4, x12  // Second operand
    b apply_operator

store_first_var_operand:
    mov x6, x12
    b parse_expr_loop

apply_operator:
    // Apply operator: x6 op x4 -> x6
    cmp x7, #'+'
    b.eq do_add
    cmp x7, #'-'
    b.eq do_sub
    cmp x7, #'*'
    b.eq do_mul
    cmp x7, #'/'
    b.eq do_div
    cmp x7, #'%'
    b.eq do_mod
    cmp x7, #256  // ==
    b.eq do_eq
    cmp x7, #257  // !=
    b.eq do_ne
    cmp x7, #'<'
    b.eq do_lt
    cmp x7, #'>'
    b.eq do_gt
    cmp x7, #258  // <=
    b.eq do_le
    cmp x7, #259  // >=
    b.eq do_ge
    b expr_complete

do_add:
    add x6, x6, x4
    mov x8, #0
    b parse_expr_loop
do_sub:
    sub x6, x6, x4
    mov x8, #0
    b parse_expr_loop
do_mul:
    mul x6, x6, x4
    mov x8, #0
    b parse_expr_loop
do_div:
    udiv x6, x6, x4
    mov x8, #0
    b parse_expr_loop
do_mod:
    udiv x10, x6, x4
    msub x6, x10, x4, x6  // x6 = x6 - (x6/x4)*x4
    mov x8, #0
    b parse_expr_loop
do_eq:
    cmp x6, x4
    cset x6, eq  // Set to 1 if equal, 0 otherwise
    mov x8, #0
    b parse_expr_loop
do_ne:
    cmp x6, x4
    cset x6, ne
    mov x8, #0
    b parse_expr_loop
do_lt:
    cmp x6, x4
    cset x6, lt
    mov x8, #0
    b parse_expr_loop
do_gt:
    cmp x6, x4
    cset x6, gt
    mov x8, #0
    b parse_expr_loop
do_le:
    cmp x6, x4
    cset x6, le
    mov x8, #0
    b parse_expr_loop
do_ge:
    cmp x6, x4
    cset x6, ge
    mov x8, #0
    b parse_expr_loop

expr_complete:
    // Result is in x6, convert to string and save
    mov x0, x6
    mov x11, x14
    lsl x11, x11, #6
    add x11, x11, #32
    add x1, x13, x11
    bl int_to_str
    
    add x14, x14, #1  // Increment var count
    add x22, x24, x25
    add x22, x22, #1  // Move past semicolon
    b parse_loop

check_print_stmt:
    // Check for opening quote or brace for print statement
    ldrb w0, [x21, x22]
    
    // Check for semicolon - if we're in a print statement, end it
    cmp w0, #';'
    b.ne not_semicolon
    cmp x17, #1  // Are we in a print statement?
    b.ne not_in_print
    
    // End of print statement - add newline
    mov w12, #'\\'
    strb w12, [x28, x29]
    add x29, x29, #1
    mov w12, #'n'
    strb w12, [x28, x29]
    add x29, x29, #1
    mov x17, #0  // No longer in print statement
    add x22, x22, #1
    b parse_loop

not_in_print:
    add x22, x22, #1
    b parse_loop

not_semicolon:
    // Check for variable reference {varname}
    cmp w0, #'{'
    b.eq found_var_ref
    
    // Check for string literal "..."
    cmp w0, #'"'
    b.eq found_print_quote
    
    add x22, x22, #1
    b parse_loop

found_var_ref:
    add x22, x22, #1  // Move past opening brace
    mov x24, x22  // Save start position of var name
    mov x23, #0   // Var name length

    // Find closing brace
find_close_brace:
    add x25, x22, x23
    cmp x25, x20
    b.ge parse_error
    ldrb w0, [x21, x25]
    cmp w0, #'}'
    b.eq found_close_brace
    add x23, x23, #1
    b find_close_brace

found_close_brace:
    // Look up variable by name
    mov x10, #0  // var index
lookup_var:
    cmp x10, x14
    b.ge var_not_found
    
    // Compare with variable name
    mov x11, x10
    lsl x11, x11, #6
    add x11, x13, x11  // Pointer to var name
    
    // Check if lengths match first
    mov x12, #0
strlen_lookup:
    ldrb w0, [x11, x12]
    cbz w0, check_lookup_len
    add x12, x12, #1
    b strlen_lookup

check_lookup_len:
    cmp x12, x23
    b.ne next_lookup_var
    
    // Compare strings
    mov x12, #0
compare_lookup:
    cmp x12, x23
    b.ge use_var_value
    ldrb w0, [x11, x12]
    add x5, x24, x12
    ldrb w1, [x21, x5]
    cmp w0, w1
    b.ne next_lookup_var
    add x12, x12, #1
    b compare_lookup

next_lookup_var:
    add x10, x10, #1
    b lookup_var

var_not_found:
    // Variable not found - error
    b parse_error

use_var_value:
    // Copy variable value to output
    mov x11, x10
    lsl x11, x11, #6
    add x11, x11, #32  // Offset to value
    add x11, x13, x11  // Pointer to var value
    
    // Get value length
    mov x23, #0
strlen_use_val:
    ldrb w0, [x11, x23]
    cbz w0, copy_var_to_output
    add x23, x23, #1
    b strlen_use_val

copy_var_to_output:
    // Copy variable value to output buffer
    mov x10, #0
copy_var_output:
    cmp x10, x23
    b.ge var_copy_done
    ldrb w12, [x11, x10]
    strb w12, [x28, x29]
    add x29, x29, #1
    add x10, x10, #1
    b copy_var_output

var_copy_done:
    // Move position past closing brace (no newline here)
    add x22, x25, #1
    b parse_loop

found_print_quote:
    add x22, x22, #1  // Move past opening quote
    mov x24, x22  // Save start position of string
    mov x23, #0   // String length

    // Find closing quote
find_end_quote:
    add x25, x22, x23
    cmp x25, x20
    b.ge parse_error
    ldrb w0, [x21, x25]
    cmp w0, #'"'
    b.eq found_end
    add x23, x23, #1
    b find_end_quote

found_end:
    // Copy literal string to output buffer
    mov x10, #0
copy_string:
    cmp x10, x23
    b.ge copy_done
    add x11, x24, x10
    ldrb w12, [x21, x11]
    strb w12, [x28, x29]
    add x29, x29, #1
    add x10, x10, #1
    b copy_string

copy_done:
    // Move position past closing quote (no newline here)
    add x22, x25, #1
    b parse_loop

done_parsing:
    // Check if we're in a nested if/else block
    cbz x18, truly_done_parsing
    
    // We were in a nested block - restore and continue
    sub x18, x18, #1
    ldp x22, x20, [sp], #16
    b parse_loop

truly_done_parsing:
    // Remove the last \n (2 chars) if we added any strings
    cmp x29, #1
    b.le parse_error
    sub x29, x29, #2  // Remove trailing \n

write_output:

    // Convert total length to string for assembly output
    mov x0, x29
    adrp x1, lenBuffer@PAGE
    add x1, x1, lenBuffer@PAGEOFF
    bl int_to_str
    mov x26, x0  // Length of length string

    // Write to stdout
    mov x19, #1  // stdout

    // Write header
    mov x0, x19
    adrp x1, header@PAGE
    add x1, x1, header@PAGEOFF
    mov x2, #headerLen
    bl _write

    // Write length
    mov x0, x19
    adrp x1, lenBuffer@PAGE
    add x1, x1, lenBuffer@PAGEOFF
    mov x2, x26
    bl _write

    // Write mid
    mov x0, x19
    adrp x1, mid@PAGE
    add x1, x1, mid@PAGEOFF
    mov x2, #midLen
    bl _write

    // Write the combined output string
    mov x0, x19
    mov x1, x28
    mov x2, x29
    bl _write

    // Write end
    mov x0, x19
    adrp x1, end@PAGE
    add x1, x1, end@PAGEOFF
    mov x2, #endLen
    bl _write

    // Exit
    mov x0, #0
    bl _exit

error:
    mov x0, #1
    bl _exit

parse_error:
    mov x0, #2  // stderr
    adrp x1, parse_error_msg@PAGE
    add x1, x1, parse_error_msg@PAGEOFF
    mov x2, #parse_error_len
    bl _write
    mov x0, #1
    bl _exit

// int_to_str: x0 = num, x1 = buffer, return x0 = length
int_to_str:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    mov x2, #10
    mov x3, x1  // start
    cmp x0, #0
    b.eq zero
loop:
    udiv x4, x0, x2
    msub x5, x4, x2, x0
    add x5, x5, #'0'
    strb w5, [x1], #1
    mov x0, x4
    cmp x0, #0
    b.ne loop
    
    // Reverse
    sub x4, x1, x3  // length
    mov x5, x3      // start pointer
    sub x6, x1, #1  // end pointer
    
reverse_loop:
    cmp x5, x6
    b.ge reverse_done
    ldrb w7, [x5]
    ldrb w8, [x6]
    strb w8, [x5], #1
    strb w7, [x6], #-1
    b reverse_loop
    
reverse_done:
    mov x0, x4  // return length
    ldp x29, x30, [sp], #16
    ret
    
zero:
    mov x0, #'0'
    strb w0, [x1], #1
    mov x0, #1
    ldp x29, x30, [sp], #16
    ret

.data
default_filename: .asciz "input.jibcode"
initial_sp: .quad 0            // Store initial stack pointer
inputBuffer: .space 4096       // Increased from 1024
outputBuffer: .space 8192      // Increased from 2048
varBuffer: .space 2560         // 40 variables max (was 10), 64 bytes each
lenBuffer: .space 32           // Increased from 20
error_msg: .ascii "\033[31mError: print statement found without printTo(terminal); declaration\033[0m\n"
error_msg_len = . - error_msg
parse_error_msg: .ascii "\033[31mError: Failed to parse jibcode\033[0m\n"
parse_error_len = . - parse_error_msg
header: .ascii ".text\n.extern _write\n.extern _exit\n\n.global _main\n_main:\n    mov x0, #1\n    adrp x1, myString@PAGE\n    add x1, x1, myString@PAGEOFF\n    mov x2, #"
headerLen = . - header
mid: .ascii "\n    bl _write\n\n    mov x0, #0\n    bl _exit\n\n.data\nmyString: .asciz \""
midLen = . - mid
end: .ascii "\"\n"
endLen = . - end
