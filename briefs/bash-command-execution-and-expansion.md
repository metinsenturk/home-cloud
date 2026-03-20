---
title: Bash Command Execution & Expansion
description: How bash groups, executes, and captures output using subshells ( ), brace groups { }, command substitution $( ) and backticks — covering scope, nesting, and practical patterns.
created: 2026-03-19
updated: 2026-03-19
tags:
  - bash
  - shell
  - command-substitution
  - subshells
  - brace-groups
  - expansion
category: Bash
references:
  - https://www.gnu.org/software/bash/manual/bash.html#Command-Grouping
  - https://www.gnu.org/software/bash/manual/bash.html#Command-Substitution
---

# Bash Command Execution & Expansion

This brief covers the constructs bash uses to **group commands**, **run them in context**, and **capture their output**: `( )`, `{ }`, `$( )`, and `` ` ` ``.

---

## `( )` — Subshell

### What It Is
Parentheses group commands and run them in a **child process (subshell)**. The subshell inherits a copy of the parent's environment, but any changes made inside — variables, directory, options — are discarded when the subshell exits.

### Key Behavior
```bash
x=1
echo "Parent: x=$x, PID=$$"

(
  x=999
  cd /tmp
  echo "Subshell: x=$x, PID=$$"   # Different PID, x is 999
)

echo "Parent after: x=$x, dir=$(pwd)"  # x is still 1, dir unchanged
```

### Common Use Cases

**1. Isolate `cd` changes:**
```bash
# Safe way to work in another directory
(cd /some/other/dir && ./build.sh)
# Current directory is still wherever you started
```

**2. Error isolation with `||`:**
```bash
(
  set -e           # Exit on error — scoped to this subshell only
  risky_command
  another_command
) || echo "Subshell block failed — parent continues"
```

**3. Parallel background jobs:**
```bash
(process_chunk_a) &
(process_chunk_b) &
wait
echo "Both chunks done"
```

**4. Temporary environment changes:**
```bash
(
  export DEBUG=true
  export LOG_LEVEL=verbose
  ./run_test.sh
)
# DEBUG and LOG_LEVEL changes are gone in parent
```

### Exit Code
The exit code of a `( )` group is the exit code of its last command:
```bash
(true; false)
echo $?  # 1
(false; true)
echo $?  # 0
```

---

## `{ }` — Group Command (Brace Block)

### What It Is
Braces group commands to run in the **current shell** — no child process is created. Useful for applying redirections, piping output, or error handling to a block of commands without the overhead or isolation of a subshell.

### Syntax Rules — Critical
- Opening brace `{` must have a **space after it**
- Closing brace `}` must be on its own line **or preceded by a semicolon**

```bash
{ echo "first"; echo "second"; }    # ✓ Inline — needs semicolon before }
{
  echo "first"
  echo "second"
}                                    # ✓ Multi-line — } on its own line
{echo "first"}                       # ✗ Error — no space after {
```

### Key Difference from `( )`

| Feature | `( )` | `{ }` |
|---|---|---|
| Creates subshell | Yes | No |
| Variable changes visible in parent | No | Yes |
| Directory changes visible in parent | No | Yes |
| Performance | Slower (fork) | Faster (no fork) |

```bash
x=1

( x=10 )
echo "After subshell: x=$x"    # 1 — change lost

{ x=10; }
echo "After brace group: x=$x" # 10 — change kept
```

### Common Use Cases

**1. Redirect a block of output to a file:**
```bash
{
  echo "=== System Info ==="
  uname -a
  date
  uptime
} > system_report.txt
```

**2. Pipe a block of output:**
```bash
{
  echo "Header"
  cat data.csv
  echo "Footer"
} | gzip > bundle.csv.gz
```

**3. Error handling — run or die:**
```bash
{
  step_one &&
  step_two &&
  step_three
} || {
  echo "Something failed" >&2
  exit 1
}
```

**4. Function body (implicit brace block):**
```bash
my_function() {
  local result="$1"
  echo "Processing: $result"
}
# Function bodies ARE brace groups — they run in the current shell
```

---

## `$( )` — Command Substitution

### What It Is
`$( )` runs a command in a subshell and **replaces the expression with the command's stdout output** (trimming trailing newlines). This is the modern, preferred syntax.

### Basic Usage
```bash
today=$(date +%Y-%m-%d)
echo "Today is: $today"              # Today is: 2026-03-19

user=$(whoami)
echo "Running as: $user"

lines=$(wc -l < file.txt)
echo "File has $lines lines"
```

### Inline Embedding
```bash
echo "Uptime: $(uptime -p)"
echo "Home dir size: $(du -sh ~ | cut -f1)"
```

### Nesting
`$( )` nests cleanly, unlike backticks:
```bash
# Find the script's own directory
script_dir=$(dirname $(realpath "$0"))

# Read a config key from a file in a computed path
config_value=$(grep "^key=" $(find /etc -name "app.conf" -maxdepth 2))
```

### Capturing Multi-line Output
Trailing newlines are stripped; internal newlines are preserved if quoted:
```bash
# Unquoted — newlines collapse to spaces
files=$(ls /etc/*.conf)
echo $files       # All on one line

# Quoted — newlines preserved
echo "$files"     # Each on its own line
```

### In Conditions
```bash
if [ "$(id -u)" -eq 0 ]; then
  echo "Running as root"
fi

if [[ "$(systemctl is-active nginx)" == "active" ]]; then
  echo "nginx is running"
fi
```

### Assigning to Arrays
```bash
# Split command output into array elements
mapfile -t lines < <(grep "ERROR" app.log)
echo "Found ${#lines[@]} errors"

# Or via word-splitting (less safe)
words=( $(echo "one two three") )
```

---

## `` ` ` `` — Backtick Command Substitution

### What It Is
Backticks are the **legacy syntax** for command substitution, equivalent to `$( )`. They capture the stdout of a command, trimming trailing newlines.

```bash
today=`date +%Y-%m-%d`        # Equivalent to: today=$(date +%Y-%m-%d)
echo "Today: $today"
```

### Why `$( )` Is Preferred

**1. Nesting requires escaping backticks:**
```bash
# Backticks — escaping required, hard to read
result=`dirname \`realpath "$0"\``

# $() — readable
result=$(dirname $(realpath "$0"))
```

**2. Backslashes behave differently inside backticks:**
```bash
# Backticks modify backslash interpretation — can surprise you
echo `echo "a\nb"`    # May or may not print a newline
echo $(echo "a\nb")   # Consistent behavior
```

**3. Visual clarity — easier to spot open/close:**
```bash
msg=`echo "Time: "`date``    # Hard to parse visually
msg="Time: $(date)"           # Clear open and close
```

### When You Might See Backticks
Older scripts and POSIX `sh` scripts may still use backticks. They work identically in simple cases:
```bash
# These are equivalent
v1=`uname -s`
v2=$(uname -s)
```

**Rule of thumb:** Read backticks fluently; write `$( )`.

---

## Quick Comparison Table

| Construct | Creates Subshell | Returns Output | Use For |
|---|---|---|---|
| `( cmds )` | Yes | No (exit code only) | Isolation, parallel jobs |
| `{ cmds; }` | No | No (exit code only) | Grouping, shared redirect/pipe |
| `$(cmd)` | Yes | Yes (stdout) | Capture command output |
| `` `cmd` `` | Yes | Yes (stdout) | Same as `$()` — legacy only |

---

## Common Pitfalls

### Forgetting braces need a space and semicolon
```bash
{echo "hi"}     # ✗ bash: syntax error
{ echo "hi"; }  # ✓
```

### Unquoted command substitution loses newlines
```bash
result=$(printf "line1\nline2\nline3")
echo $result      # "line1 line2 line3" — newlines replaced by spaces
echo "$result"    # Preserves newlines — almost always what you want
```

### Assuming `( )` returns a value
```bash
# Wrong mental model
x=(echo "hello")    # This creates an ARRAY, not a subshell
x=$(echo "hello")   # ✓ This is command substitution
```
