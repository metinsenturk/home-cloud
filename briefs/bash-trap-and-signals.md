---
title: Bash Trap Command & Signals
description: How bash uses signals and pseudo-signals with the trap builtin to run cleanup, handle interruption, and control shell lifecycle events safely.
created: 2026-03-19
updated: 2026-03-19
tags:
  - bash
  - shell
  - trap
  - signals
  - process-control
  - cleanup
category: Bash
references:
  - https://www.gnu.org/software/bash/manual/bash.html#Signals
  - https://www.gnu.org/software/bash/manual/bash.html#Bourne-Shell-Builtins
  - https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_14
---

# Bash Trap Command & Signals

This brief explains two related topics:

- **Signals**: asynchronous notifications sent to a process
- **`trap`**: the bash builtin used to run commands when a shell receives a signal or reaches certain shell events

---

## What Signals Are

A **signal** is a small message sent to a process by the kernel, terminal, or another process. Signals are commonly used to:

- interrupt a running command
- request termination
- notify a process of an event
- control job execution

Common ways signals are generated:

- Pressing `Ctrl+C` in a terminal sends `SIGINT`
- Pressing `Ctrl+\` sends `SIGQUIT`
- Running `kill -TERM <pid>` sends `SIGTERM`
- Running `kill -KILL <pid>` sends `SIGKILL`

Signals are identified by both a **name** and a **number**, but scripts should prefer the **name** because signal numbers vary across platforms.

```bash
kill -TERM 12345
kill -INT 12345
kill -HUP 12345
```

To list signal names in bash:

```bash
kill -l
trap -l
```

---

## Common Signals

| Signal | Meaning | Typical Source | Can `trap` catch it? |
|---|---|---|---|
| `SIGINT` | Interrupt | `Ctrl+C` | Yes |
| `SIGTERM` | Polite termination request | `kill`, service manager | Yes |
| `SIGHUP` | Hangup / terminal disconnect / reload semantics in some programs | terminal close, supervisor | Yes |
| `SIGQUIT` | Quit and often produce core dump | `Ctrl+\\` | Yes |
| `SIGUSR1` / `SIGUSR2` | User-defined application signals | other processes | Yes |
| `SIGKILL` | Immediate forced kill | `kill -KILL` | No |
| `SIGSTOP` | Uncatchable stop | kernel / `kill -STOP` | No |

### Signals You Cannot Trap

`SIGKILL` and `SIGSTOP` cannot be caught, ignored, or handled. If a process receives one of these, the kernel acts immediately.

That matters because `trap` is useful for **graceful shutdown**, but it is not a guarantee that cleanup will always run.

---

## What `trap` Does

`trap` tells the shell to run a command when one of these happens:

- the shell receives a signal such as `SIGINT` or `SIGTERM`
- the shell exits via the pseudo-signal `EXIT`
- certain bash-specific events occur, such as `ERR`, `DEBUG`, or `RETURN`

Basic form:

```bash
trap 'commands' SIGNAL
```

Example:

```bash
trap 'echo "Interrupted"; exit 130' INT
```

This tells bash: when `SIGINT` arrives, print a message and exit with status `130`.

---

## Basic Signal Traps

### Cleanup on Interrupt or Termination

```bash
#!/usr/bin/env bash

tmp_file=$(mktemp)

cleanup() {
  rm -f "$tmp_file"
}

trap cleanup INT TERM EXIT

echo "Working in $tmp_file"
sleep 60
```

If the script is interrupted with `Ctrl+C`, terminated with `SIGTERM`, or exits normally, `cleanup` runs and removes the temporary file.

### Why `EXIT` Is Usually Included

Trapping `INT` and `TERM` handles common shutdown paths, but not normal script completion. Adding `EXIT` gives one consistent place for cleanup regardless of whether the script:

- finishes successfully
- exits early with `exit`
- fails because of `set -e`

---

## `EXIT` Is Not a Real Signal

`EXIT` is a **shell pseudo-signal**, not a kernel signal. It means: run this trap when the shell is about to exit.

```bash
trap 'echo "Shell exiting with status $?"' EXIT
```

Useful for:

- removing temp files
- releasing lock directories
- stopping background child processes
- printing final diagnostics

### Preserve the Original Exit Status

If cleanup runs on `EXIT`, the script often needs to preserve the original status code:

```bash
cleanup() {
  local exit_code=$?
  rm -f "$tmp_file"
  exit "$exit_code"
}

trap cleanup EXIT
```

Without this pattern, cleanup logic can accidentally overwrite the real reason the script failed.

---

## Trapping `ERR`

`ERR` is another bash pseudo-signal. It fires when a command fails under bash's error rules.

```bash
#!/usr/bin/env bash
set -e

trap 'echo "Command failed at line $LINENO"' ERR

cp missing-file.txt /tmp/
echo "This line will not run"
```

### Important Notes About `ERR`

- `ERR` is bash-specific, not POSIX shell
- its behavior depends on shell context
- it does **not** trigger for every non-zero exit in every construct
- it is more predictable when used with `set -E` so functions and subshell contexts inherit the `ERR` trap

Example:

```bash
set -eE
trap 'echo "Failure in ${BASH_COMMAND} at line $LINENO"' ERR
```

Use `ERR` for diagnostics, but do not assume it is a perfect replacement for explicit error handling.

---

## Trapping `DEBUG` and `RETURN`

Bash also supports more specialized pseudo-signals:

- `DEBUG`: runs before every simple command
- `RETURN`: runs when a shell function or sourced file returns

Example:

```bash
trap 'echo "About to run: $BASH_COMMAND"' DEBUG
```

This is mainly useful for debugging and instrumentation. It is usually too noisy for normal scripts.

---

## Resetting and Ignoring Traps

Reset a trap to its default behavior:

```bash
trap - INT TERM
```

Ignore a signal:

```bash
trap '' INT
```

Be careful with ignored signals. Ignoring `SIGINT` or `SIGTERM` can make scripts difficult to stop and can break operational expectations.

---

## Recommended Cleanup Pattern

For most scripts, the safest pattern is:

```bash
#!/usr/bin/env bash
set -euo pipefail

tmp_dir=$(mktemp -d)
child_pid=""

cleanup() {
  local exit_code=$?

  if [[ -n "$child_pid" ]]; then
    kill "$child_pid" 2>/dev/null || true
    wait "$child_pid" 2>/dev/null || true
  fi

  rm -rf "$tmp_dir"
  exit "$exit_code"
}

trap cleanup EXIT INT TERM

long_running_command &
child_pid=$!

wait "$child_pid"
```

Why this works well:

- cleanup is centralized in one function
- `EXIT` covers both success and failure
- background processes are terminated explicitly
- temp resources are removed reliably
- the original exit status is preserved

---

## Trap Scope and Subshell Behavior

Trap behavior depends on where code runs.

### Subshells Get Their Own Context

```bash
trap 'echo parent EXIT' EXIT

(
  trap 'echo subshell EXIT' EXIT
  echo "inside subshell"
)
```

The subshell has its own trap state. Changes inside it do not automatically modify the parent's traps.

### Pipelines and Command Substitutions

Commands in pipelines or command substitutions may run in subshells, depending on shell behavior and options. That affects whether a trap executes where you expect.

If cleanup must happen in the parent shell, avoid assuming a trap set in a pipeline component will affect the whole script.

---

## Signal Handling vs Exit Codes

When a process exits because of a signal, shells often report a status code of `128 + signal_number`.

Common examples:

- `130` typically means terminated by `SIGINT`
- `143` typically means terminated by `SIGTERM`

That is why many scripts use:

```bash
trap 'exit 130' INT
trap 'exit 143' TERM
```

This preserves a conventional exit status that calling tools can interpret correctly.

---

## When to Use `trap`

Use `trap` when a script needs to:

- clean up temporary files or directories
- remove lock files
- stop background workers it started
- log interruption or failure details
- convert signals into controlled shutdown behavior

Do not use `trap` as a substitute for normal program logic. It is best for **lifecycle handling** and **cleanup**, not for ordinary branching.

---

## Common Mistakes

### 1. Forgetting `EXIT`

```bash
trap cleanup INT TERM
```

This misses normal successful completion.

### 2. Overwriting the Original Exit Status

```bash
cleanup() {
  rm -f "$tmp_file"
}

trap cleanup EXIT
```

If later commands in `cleanup` fail or succeed differently, the original status may be lost.

### 3. Assuming `SIGKILL` Cleanup Is Possible

No trap will run after `kill -KILL`.

### 4. Using Double Quotes When Late Expansion Is Intended

```bash
trap "echo $tmp_file" EXIT
```

This expands `$tmp_file` when the trap is defined, not when it runs. Usually single quotes are safer:

```bash
trap 'echo "$tmp_file"' EXIT
```

### 5. Ignoring Parent and Child Process Relationships

If a script starts background jobs, exiting the parent does not always cleanly stop every child. Explicit `kill` and `wait` logic is often needed inside cleanup.

---

## Practical Mental Model

Think of `trap` as a way to attach **shutdown hooks** and **event hooks** to the current shell.

- Real signals come from outside the shell or kernel
- Pseudo-signals such as `EXIT` and `ERR` come from bash itself
- `trap` does not make a script indestructible
- `trap` is most valuable for cleanup and controlled shutdown

---

## Minimal Example

```bash
#!/usr/bin/env bash
set -euo pipefail

tmp_file=$(mktemp)

cleanup() {
  local exit_code=$?
  rm -f "$tmp_file"
  exit "$exit_code"
}

trap cleanup EXIT INT TERM

echo "Temporary file: $tmp_file"
sleep 30
```

This is the core pattern most bash scripts need.