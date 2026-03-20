---
title: Bash Logical Evaluation & Math Operators
description: Deep dive into bash's evaluation and arithmetic constructs — [[ ]], [ ], (( )), and $(( )) — covering conditional logic, pattern matching, and math operations.
created: 2026-03-19
updated: 2026-03-19
tags:
  - bash
  - shell
  - conditionals
  - arithmetic
  - testing
  - logic
category: Bash
references:
  - https://www.gnu.org/software/bash/manual/bash.html#Bash-Conditional-Expressions
  - https://www.gnu.org/software/bash/manual/bash.html#Arithmetic-Evaluation
---

# Bash Logical Evaluation & Math Operators

This brief covers the four constructs bash uses for **conditional testing** and **arithmetic**: `[ ]`, `[[ ]]`, `(( ))`, and `$(( ))`.

---

## `[ ]` — Test (POSIX/Single Bracket)

### What It Is
`[ ]` is an alias for the `test` built-in command. It is the POSIX-standard way to evaluate conditions. The closing `]` is just a required argument to `test`, not syntax.

### How It Works
```bash
# These two are identical
test -f file.txt && echo "exists"
[ -f file.txt ] && echo "exists"
```

### Space Rules — Critical
There must be **spaces** inside the brackets:
```bash
[ -f file.txt ]   # ✓ Correct
[-f file.txt]     # ✗ Error: command not found
```

### Quoting — Required
Variables must be quoted to avoid word-splitting issues:
```bash
name="John Doe"

[ $name = "John Doe" ]    # ✗ Breaks — expands to [ John Doe = John Doe ]
[ "$name" = "John Doe" ]  # ✓ Correct
```

### Common Tests

**File Tests:**
```bash
[ -f file.txt ]     # Regular file exists
[ -d /tmp ]         # Directory exists
[ -e path ]         # Any file/dir exists
[ -r file ]         # File is readable
[ -w file ]         # File is writable
[ -x file ]         # File is executable
[ -s file ]         # File exists and is non-empty
[ -L symlink ]      # Is a symbolic link
[ f1 -nt f2 ]       # f1 is newer than f2
[ f1 -ot f2 ]       # f1 is older than f2
```

**String Tests:**
```bash
[ -z "$str" ]       # String is empty (zero length)
[ -n "$str" ]       # String is non-empty
[ "$a" = "$b" ]     # Strings are equal (use = not ==)
[ "$a" != "$b" ]    # Strings are not equal
```

**Numeric Tests:**
```bash
[ $a -eq $b ]       # Equal
[ $a -ne $b ]       # Not equal
[ $a -lt $b ]       # Less than
[ $a -le $b ]       # Less than or equal
[ $a -gt $b ]       # Greater than
[ $a -ge $b ]       # Greater than or equal
```

**Combining Conditions:**
```bash
[ "$a" = "yes" ] && [ "$b" = "true" ]     # AND (preferred)
[ "$a" = "yes" -a "$b" = "true" ]         # AND (older style, avoid)
[ "$a" = "yes" ] || [ "$b" = "true" ]     # OR (preferred)
[ "$a" = "yes" -o "$b" = "true" ]         # OR (older style, avoid)
[ ! -f file.txt ]                          # NOT
```

### Use Case
Use `[ ]` when writing POSIX-portable scripts that need to run on `sh`, `dash`, or other non-bash shells.

---

## `[[ ]]` — Extended Test (Double Bracket)

### What It Is
`[[ ]]` is a bash built-in keyword (not a command). It is a superset of `[ ]` with safer behavior and more powerful features. **Preferred for all modern bash scripts.**

### Key Advantages Over `[ ]`

**1. No word-splitting — quotes optional:**
```bash
name="John Doe"
[[ $name = "John Doe" ]]    # ✓ Works without quotes
```

**2. Pattern matching with `=` and `!=`:**
```bash
file="report_2026.txt"
[[ $file = *.txt ]]        # ✓ Glob pattern match
[[ $file != *.csv ]]       # ✓ Inverted pattern match
```

**3. Regex matching with `=~`:**
```bash
email="user@example.com"
[[ $email =~ ^[a-z]+@[a-z]+\.[a-z]+$ ]] && echo "Valid email"

# Capture groups via BASH_REMATCH
date_str="2026-03-19"
if [[ $date_str =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})$ ]]; then
  year="${BASH_REMATCH[1]}"
  month="${BASH_REMATCH[2]}"
  day="${BASH_REMATCH[3]}"
  echo "Year: $year, Month: $month, Day: $day"
fi
```

**4. Logical `&&` and `||` inside the brackets:**
```bash
[[ -f file.txt && -r file.txt ]]          # Inside [[ ]] is fine
[[ $a = "yes" || $b = "true" ]]           # Inside [[ ]] is fine
# (Don't use -a / -o inside [[ ]])
```

**5. No need to worry about `<` and `>` being redirections:**
```bash
[[ "apple" < "banana" ]]   # String comparison — safe in [[ ]]
[ "apple" \< "banana" ]    # Requires escaping in [ ]
```

### `[ ]` vs `[[ ]]` Side-by-Side

| Feature | `[ ]` | `[[ ]]` |
|---|---|---|
| POSIX portable | ✓ | ✗ (bash only) |
| Quote variables | Required | Optional |
| Glob patterns | ✗ | ✓ |
| Regex matching | ✗ | ✓ (`=~`) |
| `&&` / `||` inside | ✗ | ✓ |
| Word splitting | Yes | No |

### Practical Example
```bash
#!/bin/bash

check_file() {
  local path="$1"

  if [[ -f "$path" && -r "$path" ]]; then
    echo "File is readable"
  elif [[ -d "$path" ]]; then
    echo "That's a directory, not a file"
  elif [[ "$path" =~ \.txt$ ]]; then
    echo "Path looks like a text file but doesn't exist"
  else
    echo "Unknown path type"
  fi
}
```

---

## `(( ))` — Arithmetic Evaluation

### What It Is
`(( ))` evaluates an arithmetic expression in the **current shell**. It does not produce output — instead, it sets an **exit code**: `0` (true) if the result is non-zero, `1` (false) if the result is zero. This makes it usable directly in `if` and `while` conditions.

### Syntax Rules
- Variables inside do **not** need a `$` prefix (though it still works with one)
- Supports C-style syntax

```bash
x=5

(( x > 3 ))         # True — exit code 0
(( x > 10 ))        # False — exit code 1

(( x++ ))           # Increment x (post-increment)
(( ++x ))           # Pre-increment x
(( x += 2 ))        # Add 2 to x
```

### In Conditionals
```bash
x=10
y=20

if (( x < y )); then
  echo "$x is less than $y"
fi

if (( x % 2 == 0 )); then
  echo "$x is even"
fi
```

### In Loops (C-style for loop)
```bash
for (( i = 0; i < 5; i++ )); do
  echo "Iteration $i"
done
```

### Boolean Logic in `(( ))`
```bash
a=1
b=0

(( a && b ))     # False (1 AND 0)
(( a || b ))     # True (1 OR 0)
(( !a ))         # False (NOT 1)
```

### Assigning Results
```bash
x=3
(( result = x * x + 2 ))
echo $result     # 11
```

### Pitfall — Zero Is False
```bash
x=0
if (( x )); then
  echo "This won't print — 0 is false in arithmetic context"
fi
```

---

## `$(( ))` — Arithmetic Expansion

### What It Is
`$(( ))` evaluates an arithmetic expression and **substitutes the result inline** (like command substitution, but for math). It returns the numeric value directly.

### Key Difference from `(( ))`
| Construct | Purpose | Returns |
|---|---|---|
| `(( x + 1 ))` | Evaluate, set exit code | Nothing to stdout |
| `$(( x + 1 ))` | Evaluate, expand to value | The numeric result |

```bash
x=5
y=3

echo $(( x + y ))        # 8
echo $(( x * y ))        # 15
echo $(( x ** 2 ))       # 25 (exponentiation)
echo $(( x / y ))        # 1 (integer division)
echo $(( x % y ))        # 2 (modulo)
```

### Inline Substitution
```bash
total=100
used=37
free=$(( total - used ))
echo "Free: $free"       # Free: 63
```

### In String Context
```bash
day=5
echo "Day $day of $(( day * 2 )) total days"
# Day 5 of 10 total days
```

### Hex, Octal, and Binary Literals
```bash
echo $(( 0xFF ))     # 255 (hex)
echo $(( 0777 ))     # 511 (octal)
echo $(( 2#1010 ))   # 10 (binary)
```

### No Floating Point
Integer math only. For decimals, use `bc` or `awk`:
```bash
echo "scale=2; 10 / 3" | bc     # 3.33
awk 'BEGIN { printf "%.2f\n", 10/3 }'   # 3.33
```

---

## Quick Decision Guide

```
Need to test files, strings, or numbers?
 ├─ Writing for POSIX/sh compatibility → use [ ]
 └─ Writing bash scripts             → use [[ ]]
       ├─ Need glob matching?         → [[ $var = pattern* ]]
       └─ Need regex?                 → [[ $var =~ regex ]]

Need arithmetic?
 ├─ Want the numeric result inline (assign/echo) → $(( expr ))
 └─ Want to test a condition or mutate a variable → (( expr ))
       └─ C-style for loop?  → for (( i=0; i<n; i++ ))
```
