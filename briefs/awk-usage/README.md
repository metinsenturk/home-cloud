---
title: AWK Usage in Bash
description: Comprehensive guide to using AWK for text processing and data manipulation
created: 2026-02-14
updated: 2026-02-14
tags:
  - bash
  - awk
  - text-processing
  - scripting
  - unix
category: Shell Scripting
references:
  - https://www.gnu.org/software/gawk/manual/gawk.html
---

# AWK Usage in Bash

AWK is a powerful text-processing language designed for pattern scanning and processing. It's particularly useful for working with structured text data like CSV files, logs, and tabular data.

## Basic Syntax

```bash
awk 'pattern { action }' filename
```

- **pattern**: Condition that must be met (optional)
- **action**: Commands to execute when pattern matches
- If no pattern is specified, action applies to all lines
- If no action is specified, matching lines are printed

## Built-in Variables

| Variable | Description |
|----------|-------------|
| `$0` | Entire current line |
| `$1, $2, ...` | First, second, etc. field in current line |
| `NF` | Number of fields in current line |
| `NR` | Current line number (record number) |
| `FS` | Field separator (default: whitespace) |
| `OFS` | Output field separator (default: space) |
| `RS` | Record separator (default: newline) |
| `ORS` | Output record separator (default: newline) |
| `FILENAME` | Name of current input file |

## Common Use Cases

### 1. Print Specific Columns

```bash
# Print first column
awk '{print $1}' file.txt

# Print multiple columns
awk '{print $1, $3}' file.txt

# Print with custom separator
awk '{print $1 "," $3}' file.txt
```

### 2. Field Separator

```bash
# CSV file (comma separator)
awk -F',' '{print $1, $3}' file.csv

# Colon separator (like /etc/passwd)
awk -F':' '{print $1, $7}' /etc/passwd

# Multiple separators
awk -F'[,:]' '{print $1}' file.txt
```

### 3. Pattern Matching

```bash
# Lines containing "error"
awk '/error/ {print}' logfile.txt

# Lines starting with "GET"
awk '/^GET/ {print $0}' access.log

# Lines NOT matching pattern
awk '!/success/ {print}' file.txt

# Multiple patterns
awk '/error|warning/ {print}' logfile.txt
```

### 4. Conditional Processing

```bash
# Print if field 3 is greater than 100
awk '$3 > 100 {print $0}' data.txt

# Multiple conditions
awk '$1 == "error" && $3 > 50 {print}' file.txt

# Using if-else
awk '{if ($3 > 100) print "High:", $0; else print "Low:", $0}' data.txt
```

### 5. Calculations and Aggregations

```bash
# Sum of column 3
awk '{sum += $3} END {print sum}' data.txt

# Average
awk '{sum += $3; count++} END {print sum/count}' data.txt

# Count lines
awk 'END {print NR}' file.txt

# Max value
awk 'BEGIN {max=0} {if ($1>max) max=$1} END {print max}' numbers.txt
```

### 6. BEGIN and END Blocks

```bash
# BEGIN: Execute before processing any input
awk 'BEGIN {print "Starting processing..."} {print $0} END {print "Done!"}' file.txt

# Print header and footer
awk 'BEGIN {print "Name\tScore"} {print $1, $2} END {print "Total records:", NR}' data.txt

# Set custom separator
awk 'BEGIN {FS=","; OFS="\t"} {print $1, $2}' file.csv
```

### 7. String Functions

```bash
# Length of field
awk '{print length($1)}' file.txt

# Substring
awk '{print substr($1, 1, 3)}' file.txt

# To uppercase
awk '{print toupper($1)}' file.txt

# To lowercase
awk '{print tolower($1)}' file.txt

# String replacement
awk '{gsub(/old/, "new"); print}' file.txt
```

### 8. Formatting Output

```bash
# printf for formatted output
awk '{printf "%-10s %5.2f\n", $1, $2}' data.txt

# Align columns
awk '{printf "%15s %10s\n", $1, $2}' file.txt
```

### 9. Working with Multiple Files

```bash
# Print filename with each line
awk '{print FILENAME, $0}' file1.txt file2.txt

# Different action per file
awk 'FNR==1 {print "Starting", FILENAME} {print $0}' file1.txt file2.txt
```

### 10. Arrays and Loops

```bash
# Count occurrences
awk '{count[$1]++} END {for (word in count) print word, count[word]}' file.txt

# Store and process data
awk '{arr[NR]=$1} END {for (i=1; i<=NR; i++) print arr[i]}' file.txt
```

## Advanced Examples

### Parse Apache/Nginx Logs

```bash
# Extract IP addresses and count requests
awk '{print $1}' access.log | sort | uniq -c | sort -rn

# Count HTTP status codes
awk '{print $9}' access.log | sort | uniq -c

# Average response time (if logged)
awk '{sum+=$11; count++} END {print sum/count}' access.log
```

### CSV Processing

```bash
# Convert CSV to TSV
awk -F',' 'BEGIN {OFS="\t"} {print $1, $2, $3}' file.csv

# Filter CSV rows
awk -F',' '$3 > 1000 {print $1, $3}' sales.csv

# Add calculated column
awk -F',' 'BEGIN {OFS=","} {print $0, $2*$3}' file.csv
```

### Data Validation

```bash
# Check for required number of fields
awk -F',' 'NF != 5 {print "Invalid line", NR, $0}' data.csv

# Validate numeric values
awk '$2 !~ /^[0-9]+$/ {print "Invalid number at line", NR}' data.txt
```

## Common Patterns

### Remove Duplicates (Keeping First)

```bash
awk '!seen[$0]++' file.txt
```

### Print Lines Between Patterns

```bash
awk '/START/,/END/ {print}' file.txt
```

### Calculate Percentage

```bash
awk '{print $1, ($2/$3)*100 "%"}' data.txt
```

### Join Fields

```bash
awk '{for(i=2;i<=NF;i++) printf "%s ", $i; print ""}' file.txt
```

## Tips and Best Practices

1. **Quote your AWK script** to prevent shell interpretation
2. **Use `-v` for passing variables**: `awk -v var=value '{print var, $1}' file.txt`
3. **Test with small data** first before processing large files
4. **Combine with other tools**: `grep pattern file | awk '{print $1}'`
5. **Use meaningful variable names** in complex scripts
6. **Comment your complex AWK scripts** using `#`

## Common Pitfalls

- ⚠️ **Field numbers start at 1**, not 0 ($0 is the entire line)
- ⚠️ **Default field separator** is any whitespace, not just space
- ⚠️ **String comparison** vs numeric: `"10" < "9"` is true (lexicographic)
- ⚠️ **Uninitialized variables** default to 0 or empty string
- ⚠️ **Regular expressions** need to be enclosed in `/pattern/`

## Testing

See `test-awk.sh` in this directory for runnable examples demonstrating these concepts.

## When to Use AWK vs Other Tools

- **AWK**: Structured text, field-based processing, calculations
- **sed**: Simple text replacements, line-based editing
- **grep**: Finding patterns, filtering lines
- **cut**: Extracting columns from fixed-format data
- **Python/Perl**: Complex logic, multiple files, data structures

AWK excels at one-liners for tabular data and log analysis.
