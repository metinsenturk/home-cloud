---
title: Bash Subshells
description: Understanding bash subshells, how they work, process isolation, and information sharing between parent and child shells
created: 2026-03-19
updated: 2026-03-19
tags:
  - bash
  - shell
  - subshells
  - processes
  - environment-variables
category: Bash
author: Development Reference
references:
  - https://www.gnu.org/software/bash/manual/bash.html#Subshells
---

# Bash Subshells

## What is a Subshell?

A subshell is a child shell process that is spawned from the main (parent) shell. When a subshell is created, it inherits a copy of the parent shell's environment, but runs as a separate process with its own process ID (PID). This process isolation is key to understanding subshell behavior.

## Creating Subshells

### Explicit Subshells (Parentheses)
The most common way to create a subshell is using parentheses:

```bash
# Main shell
echo "Parent PID: $$"

# Create a subshell explicitly
(
  echo "Subshell PID: $$"
  x=10
)

echo "After subshell, x=$x"  # x is empty in parent
```

**Output:**
```
Parent PID: 12345
Subshell PID: 12346
After subshell, x=
```

### Implicit Subshells

Subshells are also created implicitly in these scenarios:

```bash
# Command pipelines (both sides are subshells in some bash modes)
cat file.txt | grep "pattern"

# Background jobs
command &

# Command substitution
result=$(echo "hello")
result=`echo "hello"`

# Process substitution
diff <(sort file1.txt) <(sort file2.txt)
```

## Process Isolation: Separate PID

The fundamental characteristic of subshells is that they run as separate processes:

```bash
#!/bin/bash

echo "=== Process Isolation ==="
main_pid=$$
echo "Main shell PID: $main_pid"

# Subshell via parentheses
(
  sub_pid=$$
  echo "Subshell PID: $sub_pid"
  
  if [ $sub_pid -eq $main_pid ]; then
    echo "ERROR: Same PID (not a subshell)"
  else
    echo "✓ Subshell has different PID"
  fi
)

# Subshell via command substitution
$(
  sub_pid=$$
  echo "Command substitution subshell PID: $sub_pid"
)

# Regular brace block (NOT a subshell)
{
  echo "Brace block PID: $$"  # Same as parent
}
```

## Variable Sharing Between Parent and Child

### Variables Are Copied, Not Shared

When a subshell is created, it inherits a **copy** of the parent's environment. Changes in the subshell do **not** affect the parent:

```bash
#!/bin/bash

x=5
echo "Parent: x=$x"

# Subshell modifies x
(
  x=10
  echo "Subshell: x=$x"  # 10
)

echo "Parent after subshell: x=$x"  # Still 5 (unchanged)
```

### Parent Cannot See Child's Variables

The parent shell cannot access variables created in a subshell:

```bash
#!/bin/bash

(
  child_var="I'm in the subshell"
)

echo "From parent: $child_var"  # Empty (undefined)
```

### Exporting Variables

Use `export` to make variables available to subshells:

```bash
#!/bin/bash

x=5
export y=10

(
  echo "In subshell: x=$x"      # Empty (not exported)
  echo "In subshell: y=$y"      # 10 (exported)
  
  x=100  # Modify local copy
  y=200  # Modify local copy
)

echo "Parent: x=$x"  # 5 (unchanged)
echo "Parent: y=$y"  # 10 (unchanged, even though exported)
```

**Key Point:** `export` makes a variable available to the subshell, but modifications in the subshell still don't affect the parent because the subshell gets its own copy.

## Practical Examples

### Temporary Directory Changes

```bash
#!/bin/bash

echo "Original directory: $(pwd)"

# Subshell keeps cd isolated
(
  cd /tmp
  echo "Inside subshell: $(pwd)"
  # Create temporary files here
)

echo "Back in parent: $(pwd)"  # Still in original directory
```

**Use Case:** Safe directory operations without affecting the main script state.

### Pipeline Context

```bash
#!/bin/bash

data="apple banana cherry"

# Each pipeline segment that modifies variables needs care
echo "$data" | while read item; do
  counter=$((counter + 1))
  echo "Item: $item, Count: $counter"
done

echo "After pipe: counter=$counter"  # Empty! Lost in subshell
```

**Why?** The `while` loop runs in a subshell (created by the pipe), so `counter` changes don't propagate.

**Solution - Use process substitution instead:**

```bash
while read item; do
  counter=$((counter + 1))
  echo "Item: $item, Count: $counter"
done < <(echo "$data")

echo "After redirection: counter=$counter"  # Works!
```

### Running Commands in Parallel

```bash
#!/bin/bash

# These run in subshells
long_task1 &
long_task2 &

# Wait for both to complete
wait

echo "All tasks done"
```

### Safe Script Execution

```bash
#!/bin/bash

# Isolate potentially dangerous operations
(
  set -e  # Exit on error
  set -u  # Exit on undefined variables
  
  # Run commands that might fail
  ./risky_script.sh
) || echo "Subshell failed, but parent continues"

echo "Parent script continues"
```

## Common Pitfalls

### Losing Variable State in Pipelines

```bash
# ❌ WRONG: counter lost
cat file.txt | while read line; do
  ((counter++))
done
echo $counter  # Empty

# ✓ RIGHT: Use process substitution
while read line; do
  ((counter++))
done < <(cat file.txt)
echo $counter  # Works!
```

### Modifying Arrays in Subshells

```bash
# ❌ WRONG: myarray modifications lost
(
  myarray=(1 2 3)
  myarray+=(4)
)
echo "${myarray[@]}"  # Empty

# ✓ RIGHT: Do it in parent shell
myarray=(1 2 3)
myarray+=(4)
echo "${myarray[@]}"  # 1 2 3 4
```

### Exit Status vs. Subshell Success

```bash
# ❌ WRONG: Only checks if subshell launched, not contents
(
  false  # Fails inside subshell
) && echo "Success"  # Still prints!

# ✓ RIGHT: Check explicitly
(
  false
)
if [ $? -eq 0 ]; then
  echo "Success"
else
  echo "Failed"
fi
```

## When to Use Subshells

✓ **Good Use Cases:**
- Isolate directory changes (`cd` in subshell)
- Run commands in specific environments without affecting parent
- Parallel execution with `&`
- Error handling with `|| fallback`
- Sandboxing potentially risky operations
- Creating a separate shell context with different options

✗ **Avoid When:**
- You need to modify parent shell state
- You need to return values (use functions instead)
- Performance matters in a loop (overhead of process creation)

## Related Concepts

- **Functions:** Like subshells but share the same shell environment (only their local variables are isolated)
- **Brace Blocks `{}`:** Run in the same shell, excellent for grouping commands without subshell overhead
- **Source/Dot `. script.sh`:** Runs script in current shell, not a subshell
- **Exec:** Replaces current shell, not a new process
