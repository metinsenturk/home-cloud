---
title: Bash Special Parameters
description: The built-in bash special variables $?, $#, $@, and $$ — what they contain, how to use them in scripts and functions, and common patterns for argument handling and error checking.
created: 2026-03-19
updated: 2026-03-19
tags:
  - bash
  - shell
  - special-variables
  - arguments
  - exit-codes
  - process-id
category: Bash
references:
  - https://www.gnu.org/software/bash/manual/bash.html#Special-Parameters
---

# Bash Special Parameters

Bash provides a set of read-only variables automatically set by the shell itself. This brief covers four of the most commonly used: `$?`, `$#`, `$@`, and `$$`.

---

## `$?` — Exit Status of Last Command

### What It Is
`$?` holds the **exit code** (return status) of the most recently executed foreground command, pipeline, or function. It is set after every command and immediately overwritten by the next one.

### Values
- `0` — Success
- `1-255` — Failure (the specific value depends on the command)

```bash
ls /tmp             # Command succeeds
echo $?             # 0

ls /nonexistent     # Command fails
echo $?             # 2 (standard "no such file" code)

grep "pattern" file.txt
echo $?             # 0 = found, 1 = not found, 2 = error
```

### Common Patterns

**If-check after a command:**
```bash
make build
if [ $? -ne 0 ]; then
  echo "Build failed" >&2
  exit 1
fi
```

**Preferred shorthand (when you don't need the code itself):**
```bash
if ! make build; then
  echo "Build failed" >&2
  exit 1
fi
```

**Storing the exit code for reuse:**
```bash
some_command
status=$?    # Capture immediately — the next command will overwrite $?

if [ $status -eq 0 ]; then
  echo "Success"
elif [ $status -eq 1 ]; then
  echo "General error"
else
  echo "Unexpected error: $status"
fi
```

**In functions:**
```bash
validate_input() {
  [[ -n "$1" ]] || return 1
  [[ "$1" =~ ^[0-9]+$ ]] || return 2
  return 0
}

validate_input "$user_input"
case $? in
  0) echo "Valid number" ;;
  1) echo "Input is empty" ;;
  2) echo "Not a number" ;;
esac
```

### Pitfall — `$?` Is Overwritten Immediately
```bash
grep "error" file.txt
echo "Search done"   # This resets $?
if [ $? -ne 0 ]; then   # ✗ Now checking exit code of echo, not grep!

# ✓ Capture it right away
grep "error" file.txt
grep_status=$?
echo "Search done"
if [ $grep_status -ne 0 ]; then
```

### Exit Codes for Pipelines
By default, `$?` reflects only the **last command** in a pipeline. To catch failures anywhere in a pipeline:
```bash
set -o pipefail          # Make whole pipeline fail if any command fails
cat file | grep "x" | sort
echo $?                  # Reflects failure if any step failed
```

---

## `$#` — Number of Arguments

### What It Is
`$#` contains the **count of positional parameters** passed to a script or function. Does not count `$0` (the script name itself).

```bash
# Script: args_demo.sh
#!/bin/bash
echo "Number of arguments: $#"
```

```bash
./args_demo.sh                     # $# = 0
./args_demo.sh hello               # $# = 1
./args_demo.sh one two three       # $# = 3
./args_demo.sh "a b" c             # $# = 2 (quoted string is one arg)
```

### Common Patterns

**Require a minimum number of arguments:**
```bash
#!/bin/bash

if [ $# -lt 2 ]; then
  echo "Usage: $0 <source> <destination>" >&2
  exit 1
fi

src="$1"
dst="$2"
```

**Accept a fixed number of arguments:**
```bash
if [ $# -ne 1 ]; then
  echo "Error: exactly one argument required" >&2
  exit 1
fi
```

**Inside a function:**
```bash
greet() {
  if [ $# -eq 0 ]; then
    echo "Hello, World!"
  else
    echo "Hello, $1!"
  fi
}

greet          # Hello, World!
greet Alice    # Hello, Alice!
```

**Loop a fixed number of times based on argument count:**
```bash
echo "Processing $# files..."
for (( i = 1; i <= $#; i++ )); do
  echo "File $i: ${!i}"     # Indirect variable expansion for positional params
done
```

---

## `$@` — All Positional Arguments

### What It Is
`$@` expands to **all positional parameters** as separate, individual strings. When quoted as `"$@"`, each argument is preserved exactly as-is — including arguments with spaces.

```bash
# Script: show_args.sh
#!/bin/bash
echo "Total: $#"
for arg in "$@"; do
  echo "  Arg: $arg"
done
```

```bash
./show_args.sh one "two three" four
# Total: 3
#   Arg: one
#   Arg: two three    ← preserved as one argument
#   Arg: four
```

### `"$@"` vs `"$*"` — The Critical Difference

| Expansion | Behavior |
|---|---|
| `"$@"` | Each argument is a separate word: `"arg1" "arg2" "arg3"` |
| `"$*"` | All arguments joined as one word: `"arg1 arg2 arg3"` |
| `$@` (unquoted) | Word-splitting applied — spaces in args break them up |
| `$*` (unquoted) | Same as unquoted `$@` |

```bash
print_args() {
  echo "Count: $#"
}

args=("hello" "world tour" "bye")

print_args "${args[@]}"    # Count: 3 — three args preserved
print_args "${args[*]}"    # Count: 1 — all joined into one string
print_args ${args[@]}      # Count: 4 — "world tour" split into two!
```

**Rule: Always use `"$@"` when forwarding arguments.**

### Forwarding Arguments to Another Command
```bash
#!/bin/bash
# Wrapper script — pass all args through unchanged
my_tool() {
  preprocess
  real_tool "$@"    # ✓ All original arguments preserved
  postprocess
}
```

### Shift and Argument Processing
```bash
#!/bin/bash

while [ $# -gt 0 ]; do
  case "$1" in
    --verbose) VERBOSE=true ;;
    --output)  OUTPUT="$2"; shift ;;   # Consume the next arg too
    --help)    show_help; exit 0 ;;
    -*)        echo "Unknown option: $1" >&2; exit 1 ;;
    *)         FILES+=("$1") ;;
  esac
  shift    # Move to next argument — $# decreases by 1
done

echo "Files to process: ${FILES[@]}"
```

### Storing Arguments in an Array
```bash
#!/bin/bash
original_args=("$@")    # Capture all args early
# ... do things that modify positional params (e.g., source a file) ...
# Restore
set -- "${original_args[@]}"
```

---

## `$$` — Current Process ID (PID)

### What It Is
`$$` holds the **PID of the current shell process**. In a script, this is the PID of the script itself. In an interactive shell, it is the PID of that shell session.

```bash
echo "My PID: $$"
```

### Unique Temporary Files
The most common use of `$$` is creating **unique, collision-free temp file names**:

```bash
tmpfile="/tmp/work_$$.tmp"
echo "Temp file: $tmpfile"

# Use it
some_command > "$tmpfile"
process "$tmpfile"

# Clean up
rm -f "$tmpfile"
```

### Trap-Based Cleanup Pattern
Combine `$$` with a `trap` to guarantee cleanup even if the script is interrupted:

```bash
#!/bin/bash

TMPFILE="/tmp/myapp_$$.tmp"
trap 'rm -f "$TMPFILE"' EXIT    # Runs on any exit (normal, error, signal)

# Script logic
generate_data > "$TMPFILE"
process_data < "$TMPFILE"
```

### `$$` in Subshells
`$$` in subshells still refers to the **parent** shell's PID (this is intentional):
```bash
echo "Shell PID: $$"
( echo "Subshell $$: same as parent" )

# To get the actual subshell PID, use $BASHPID instead
( echo "Actual subshell PID: $BASHPID" )
```

| Variable | Value |
|---|---|
| `$$` | PID of the original shell (does not change in subshells) |
| `$BASHPID` | PID of the actual current process (changes in subshells) |

### Lock Files
```bash
LOCKFILE="/var/run/myapp.lock"

if [ -f "$LOCKFILE" ]; then
  echo "Already running (PID $(cat $LOCKFILE))" >&2
  exit 1
fi

echo $$ > "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

# ... rest of script ...
```

---

## Special Parameters — Quick Reference

| Parameter | Name | Contains |
|---|---|---|
| `$?` | Exit Status | Exit code of last command (0 = success) |
| `$#` | Argument Count | Number of positional params (not counting `$0`) |
| `$@` | All Arguments | All positional params as separate words |
| `$$` | Process ID | PID of the current shell |

### Other Related Special Parameters (for completeness)

| Parameter | Contains |
|---|---|
| `$0` | Name/path of the script |
| `$1` ... `$9` | Individual positional parameters |
| `${10}` and beyond | Needs braces for double-digit indices |
| `$*` | All arguments as a single word (use `$@` instead) |
| `$!` | PID of most recent background process |
| `$-` | Current shell option flags |
| `$_` | Last argument of the previous command |
| `$BASHPID` | Actual PID of current shell (differs from `$$` in subshells) |
