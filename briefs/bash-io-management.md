---
title: Bash Input/Output (I/O) Management
description: How bash redirects data using <, >, >>, <<, and process substitution <( ) and >( ) — covering file I/O, here-docs, pipe alternatives, and fd manipulation.
created: 2026-03-19
updated: 2026-03-19
tags:
  - bash
  - shell
  - redirection
  - io
  - here-doc
  - process-substitution
  - file-descriptors
category: Bash
references:
  - https://www.gnu.org/software/bash/manual/bash.html#Redirections
  - https://www.gnu.org/software/bash/manual/bash.html#Process-Substitution
---

# Bash Input/Output (I/O) Management

This brief covers the operators bash uses to move data: `<`, `>`, `>>`, `<<`, and process substitution `<( )` / `>( )`.

---

## Background: File Descriptors

Every bash process has three standard file descriptors (FDs) open by default:

| FD | Name | Default Target |
|---|---|---|
| `0` | stdin | Keyboard |
| `1` | stdout | Terminal |
| `2` | stderr | Terminal |

Redirection operators attach these FDs to files, commands, or other FDs.

---

## `<` — Input Redirection

### What It Does
Connects a file to **stdin (FD 0)** of a command, so the command reads from the file instead of the keyboard.

```bash
# Instead of cat reading from keyboard:
sort < names.txt

# Passing a file to a command that reads stdin:
wc -l < report.csv

# Read a file into a variable via a loop
while read line; do
  echo "Line: $line"
done < data.txt
```

### FD Syntax
`<` is shorthand for `0<` (redirect FD 0):
```bash
sort 0< names.txt    # Explicit — same as: sort < names.txt
```

---

## `>` — Output Redirection (Overwrite)

### What It Does
Connects **stdout (FD 1)** to a file, creating or **overwriting** it.

```bash
echo "Hello" > output.txt          # Creates or overwrites output.txt
ls -la > directory_listing.txt
date > timestamp.txt
```

### Redirecting stderr

```bash
command 2> errors.txt              # Redirect stderr to file
command > out.txt 2> err.txt       # stdout and stderr to separate files
command > out.txt 2>&1             # Merge stderr into stdout, both to file
command &> out.txt                 # Shorthand — same as > out.txt 2>&1
```

### Discarding Output
```bash
command > /dev/null                # Discard stdout
command 2> /dev/null               # Discard stderr
command &> /dev/null               # Discard all output
```

### Create an Empty File
```bash
> newfile.txt                      # Truncates or creates file with no content
```

### Protecting Against Accidental Overwrites
```bash
set -o noclobber                   # Prevent > from overwriting existing files
echo "data" > existing.txt         # Error: cannot overwrite existing file
echo "data" >| existing.txt        # Force overwrite even with noclobber set
```

---

## `>>` — Output Redirection (Append)

### What It Does
Like `>`, but **appends** to the file instead of overwriting. If the file doesn't exist, it is created.

```bash
echo "First entry" > log.txt       # Creates log.txt
echo "Second entry" >> log.txt     # Appends — log.txt now has 2 lines
echo "Third entry" >> log.txt      # Appends again

# Common logging pattern
log() {
  echo "[$(date +%T)] $*" >> app.log
}

log "Server started"
log "Processing request"
```

### Appending stderr
```bash
command >> out.txt 2>> err.txt     # Append stdout and stderr to separate files
command >> combined.txt 2>&1       # Append both streams to same file
```

---

## `<<` — Here-Document (Here-Doc)

### What It Is
A here-doc feeds a **multi-line block of text** directly to a command's stdin, without needing a separate file. The block is terminated by a delimiter word you choose.

### Syntax
```bash
command << DELIMITER
  line one
  line two
  line three
DELIMITER
```

The delimiter (`DELIMITER`, `EOF`, `END`, `TEXT` — any word works) must appear at the **start of a line** with no leading whitespace to close the block.

### Basic Example
```bash
cat << EOF
This text goes to cat's stdin.
It can span multiple lines.
Variables like $HOME are expanded.
EOF
```

### Variable Expansion
By default, variables and command substitutions are expanded:
```bash
name="Alice"
cat << EOF
Hello, $name!
Today is $(date +%A).
Your home is $HOME.
EOF
```

**To suppress expansion**, quote the delimiter:
```bash
cat << 'EOF'
No expansion: $HOME is literally $HOME
$(date) is not evaluated
EOF
```

### `<<-` — Strip Leading Tabs
The `<<-` variant strips leading **tab** characters (not spaces) from lines, allowing indented here-docs in scripts:
```bash
generate_config() {
	cat <<- EOF
		[server]
		host = localhost
		port = 8080
	EOF
}
# Output has no leading tabs
```

### Practical Here-Doc Uses

**Writing a config file:**
```bash
cat > /etc/app/config.ini << EOF
[database]
host = ${DB_HOST}
port = ${DB_PORT}
name = ${DB_NAME}
EOF
```

**Multi-line SQL query:**
```bash
psql -U postgres << SQL
  SELECT id, name, email
  FROM users
  WHERE active = true
  ORDER BY name;
SQL
```

**Passing multi-line input to SSH:**
```bash
ssh user@host << 'REMOTE'
  cd /app
  git pull
  systemctl restart myapp
REMOTE
```

---

## `<( )` and `>( )` — Process Substitution

### What It Is
Process substitution makes the **output of a command (or input to a command) behave like a temporary file**. Bash creates a named pipe (or `/dev/fd/N`) and provides the path. This lets you use commands that require file arguments with streaming data.

### `<( )` — Command Output as a File
```bash
# diff normally requires two file arguments
diff file1.txt file2.txt

# Process substitution lets you diff command outputs directly
diff <(sort file1.txt) <(sort file2.txt)
diff <(ls dir1/) <(ls dir2/)
diff <(ssh server1 "ls /app") <(ssh server2 "ls /app")
```

**Compare a file with a transformed version:**
```bash
diff file.txt <(tr '[:upper:]' '[:lower:]' < file.txt)
```

### `>( )` — Command as a File Target
```bash
# Tee to multiple destinations including commands
tee >(gzip > output.gz) >(wc -l) > output.txt

# Split pipeline output to two processors at once
some_command | tee >(grep ERROR > errors.log) >(grep WARN > warnings.log) > /dev/null
```

### Solving the Pipeline Variable Loss Problem
A key use case: pipelines create subshells, so variable changes inside a pipe's `while` loop are lost. Process substitution avoids this:

```bash
counter=0

# ❌ BAD: while runs in subshell — counter lost after loop
cat file.txt | while read line; do
  ((counter++))
done
echo "Count: $counter"   # 0 — lost!

# ✓ GOOD: while runs in current shell
while read line; do
  ((counter++))
done < <(cat file.txt)
echo "Count: $counter"   # Correct!
```

### Process Substitution vs Pipes

| Aspect | Pipe `\|` | Process Substitution `<( )` |
|---|---|---|
| Creates subshell | Yes (both sides) | Yes (substituted command only) |
| Main command in subshell | Yes | No |
| Multi-input support | No (linear) | Yes (multiple `<()` at once) |
| Variable changes persist | No | Yes (main command in current shell) |



## Combining Redirections

### stdout + stderr to same file
```bash
command > output.txt 2>&1    # Order matters: > sets stdout first, then 2>&1 copies
command &> output.txt         # Shorthand (bash 4+)
```

### Redirect a brace block
```bash
{
  echo "Report header"
  query_database
  echo "Report footer"
} > report.txt 2> errors.txt
```

### Redirect to multiple destinations with `tee`
```bash
command | tee output.txt             # stdout to both terminal and file
command | tee -a output.txt          # Append mode
command 2>&1 | tee combined.log      # Both streams to terminal and log
```

### Swap stdout and stderr
```bash
command 3>&1 1>&2 2>&3    # Temporarily use FD 3 to perform the swap
```

---

## Quick Reference

| Operator | Direction | Behavior |
|---|---|---|
| `< file` | file → stdin | Feed file as input |
| `> file` | stdout → file | Create or overwrite |
| `>> file` | stdout → file | Create or append |
| `2> file` | stderr → file | Redirect errors |
| `&> file` | stdout+stderr → file | Redirect all output |
| `2>&1` | stderr → stdout | Merge streams |
| `<< WORD` | inline text → stdin | Here-doc (with expansion) |
| `<< 'WORD'` | inline text → stdin | Here-doc (no expansion) |
| `<<- WORD` | inline text → stdin | Here-doc (strip tabs) |
| `< <(cmd)` | cmd output → stdin | Process sub as input |
| `>(cmd)` | stdout → cmd input | Process sub as output |
