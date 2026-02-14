#!/bin/bash

# AWK Usage Test Script
# This script demonstrates various AWK capabilities with practical examples

set -e  # Exit on error

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function to print section headers
print_section() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

# Helper function to print commands
print_command() {
    echo -e "${GREEN}Command:${NC} $1"
    echo -e "${GREEN}Output:${NC}"
}

# Create sample data files
create_sample_data() {
    # Sample CSV file
    cat > /tmp/sample.csv << 'EOF'
Name,Age,Salary,Department
John,28,50000,Engineering
Jane,32,65000,Marketing
Bob,45,75000,Engineering
Alice,29,55000,Sales
Charlie,38,68000,Marketing
Diana,41,72000,Engineering
EOF

    # Sample log file
    cat > /tmp/sample.log << 'EOF'
2026-02-14 10:23:45 INFO Server started successfully
2026-02-14 10:24:12 ERROR Connection timeout - database unreachable
2026-02-14 10:24:30 WARN High memory usage detected: 85%
2026-02-14 10:25:01 INFO User logged in: john@example.com
2026-02-14 10:25:15 ERROR Failed to process payment: insufficient funds
2026-02-14 10:26:00 INFO Backup completed successfully
2026-02-14 10:27:30 ERROR API rate limit exceeded
EOF

    # Sample space-delimited data
    cat > /tmp/sample.txt << 'EOF'
Product001 Apple 150 Fruits
Product002 Laptop 850 Electronics
Product003 Banana 80 Fruits
Product004 Mouse 25 Electronics
Product005 Orange 120 Fruits
Product006 Keyboard 65 Electronics
EOF

    # Sample numbers file
    cat > /tmp/numbers.txt << 'EOF'
15
42
8
73
29
51
12
EOF

    echo -e "${GREEN}✓ Sample data files created${NC}\n"
}

# Test 1: Basic field printing
test_basic_fields() {
    print_section "1. Basic Field Printing"
    
    print_command "awk '{print \$1, \$3}' /tmp/sample.txt"
    awk '{print $1, $3}' /tmp/sample.txt
    
    echo
    print_command "awk '{print \"Product:\", \$2, \"| Price:\", \$3}' /tmp/sample.txt"
    awk '{print "Product:", $2, "| Price:", $3}' /tmp/sample.txt
}

# Test 2: Field separator
test_field_separator() {
    print_section "2. Custom Field Separator (CSV)"
    
    print_command "awk -F',' '{print \$1, \$3}' /tmp/sample.csv"
    awk -F',' '{print $1, $3}' /tmp/sample.csv
    
    echo
    print_command "awk -F',' 'NR>1 {print \$1, \"earns\", \$3}' /tmp/sample.csv"
    awk -F',' 'NR>1 {print $1, "earns", $3}' /tmp/sample.csv
}

# Test 3: Pattern matching
test_pattern_matching() {
    print_section "3. Pattern Matching"
    
    print_command "awk '/ERROR/ {print}' /tmp/sample.log"
    awk '/ERROR/ {print}' /tmp/sample.log
    
    echo
    print_command "awk '/ERROR|WARN/ {print \$3, \$4, \$5, \$6, \$7}' /tmp/sample.log"
    awk '/ERROR|WARN/ {print $3, $4, $5, $6, $7}' /tmp/sample.log
    
    echo
    print_command "awk '/Fruits/ {print \$1, \$2, \$3}' /tmp/sample.txt"
    awk '/Fruits/ {print $1, $2, $3}' /tmp/sample.txt
}

# Test 4: Conditional processing
test_conditionals() {
    print_section "4. Conditional Processing"
    
    print_command "awk '\$3 > 100 {print \$2, \"costs\", \$3}' /tmp/sample.txt"
    awk '$3 > 100 {print $2, "costs", $3}' /tmp/sample.txt
    
    echo
    print_command "awk -F',' '\$3 > 60000 {print \$1, \"in\", \$4, \"earns\", \$3}' /tmp/sample.csv"
    awk -F',' '$3 > 60000 {print $1, "in", $4, "earns", $3}' /tmp/sample.csv
    
    echo
    print_command "awk '{if (\$3 > 100) print \"HIGH:\", \$2, \$3; else print \"LOW:\", \$2, \$3}' /tmp/sample.txt"
    awk '{if ($3 > 100) print "HIGH:", $2, $3; else print "LOW:", $2, $3}' /tmp/sample.txt
}

# Test 5: Calculations and aggregations
test_calculations() {
    print_section "5. Calculations and Aggregations"
    
    print_command "awk '{sum += \$1} END {print \"Sum:\", sum}' /tmp/numbers.txt"
    awk '{sum += $1} END {print "Sum:", sum}' /tmp/numbers.txt
    
    echo
    print_command "awk '{sum += \$1; count++} END {print \"Average:\", sum/count}' /tmp/numbers.txt"
    awk '{sum += $1; count++} END {print "Average:", sum/count}' /tmp/numbers.txt
    
    echo
    print_command "awk 'BEGIN {max=0} {\$1>max ? max=\$1 : max=max} END {print \"Max:\", max}' /tmp/numbers.txt"
    awk 'BEGIN {max=0} {$1>max ? max=$1 : max=max} END {print "Max:", max}' /tmp/numbers.txt
    
    echo
    print_command "awk -F',' 'NR>1 {sum+=\$3} END {print \"Total Salary:\", sum}' /tmp/sample.csv"
    awk -F',' 'NR>1 {sum+=$3} END {print "Total Salary:", sum}' /tmp/sample.csv
}

# Test 6: BEGIN and END blocks
test_begin_end() {
    print_section "6. BEGIN and END Blocks"
    
    print_command "awk 'BEGIN {print \"NAME\tPRICE\"} {print \$2, \$3}' /tmp/sample.txt"
    awk 'BEGIN {print "NAME\tPRICE"} {print $2, $3}' /tmp/sample.txt
    
    echo
    print_command "awk 'BEGIN {count=0} /ERROR/ {count++} END {print \"Total errors:\", count}' /tmp/sample.log"
    awk 'BEGIN {count=0} /ERROR/ {count++} END {print "Total errors:", count}' /tmp/sample.log
}

# Test 7: String functions
test_string_functions() {
    print_section "7. String Functions"
    
    print_command "awk '{print \$2, \"length:\", length(\$2)}' /tmp/sample.txt"
    awk '{print $2, "length:", length($2)}' /tmp/sample.txt
    
    echo
    print_command "awk '{print toupper(\$2)}' /tmp/sample.txt"
    awk '{print toupper($2)}' /tmp/sample.txt
    
    echo
    print_command "awk '{print substr(\$1, 1, 7)}' /tmp/sample.txt"
    awk '{print substr($1, 1, 7)}' /tmp/sample.txt
    
    echo
    print_command "echo 'hello world' | awk '{gsub(/world/, \"AWK\"); print}'"
    echo 'hello world' | awk '{gsub(/world/, "AWK"); print}'
}

# Test 8: Formatted output
test_formatted_output() {
    print_section "8. Formatted Output with printf"
    
    print_command "awk '{printf \"%-15s %5d\n\", \$2, \$3}' /tmp/sample.txt"
    awk '{printf "%-15s %5d\n", $2, $3}' /tmp/sample.txt
    
    echo
    print_command "awk -F',' 'NR>1 {printf \"%-10s Age: %2d Salary: \$%d\n\", \$1, \$2, \$3}' /tmp/sample.csv"
    awk -F',' 'NR>1 {printf "%-10s Age: %2d Salary: $%d\n", $1, $2, $3}' /tmp/sample.csv
}

# Test 9: Arrays and counting
test_arrays() {
    print_section "9. Arrays and Counting"
    
    print_command "awk '{count[\$4]++} END {for (cat in count) print cat, count[cat]}' /tmp/sample.txt"
    awk '{count[$4]++} END {for (cat in count) print cat, count[cat]}' /tmp/sample.txt
    
    echo
    print_command "awk -F',' 'NR>1 {count[\$4]++} END {for (dept in count) print dept, count[dept]}' /tmp/sample.csv"
    awk -F',' 'NR>1 {count[$4]++} END {for (dept in count) print dept, count[dept]}' /tmp/sample.csv
    
    echo
    print_command "awk '{count[\$3]++} END {for (lvl in count) print lvl, \"appeared\", count[lvl], \"times\"}' /tmp/sample.log"
    awk '{count[$3]++} END {for (lvl in count) print lvl, "appeared", count[lvl], "times"}' /tmp/sample.log
}

# Test 10: Advanced patterns
test_advanced() {
    print_section "10. Advanced Patterns"
    
    print_command "awk '!seen[\$2]++' /tmp/sample.txt  # Remove duplicates based on column 2"
    awk '!seen[$2]++' /tmp/sample.txt
    
    echo
    print_command "awk 'NR>1 && NR<4' /tmp/sample.txt  # Print lines 2-3"
    awk 'NR>1 && NR<4' /tmp/sample.txt
    
    echo
    print_command "awk '{print NF, \"fields -\", \$0}' /tmp/sample.txt  # Count fields per line"
    awk '{print NF, "fields -", $0}' /tmp/sample.txt
    
    echo
    print_command "awk -F',' 'NR>1 {total+=\$3; print \$1, \$3, \"(Running total: \"total\")\"}' /tmp/sample.csv"
    awk -F',' 'NR>1 {total+=$3; print $1, $3, "(Running total: "total")"}' /tmp/sample.csv
}

# Test 11: Real-world examples
test_real_world() {
    print_section "11. Real-World Examples"
    
    echo -e "${GREEN}CSV to TSV conversion:${NC}"
    print_command "awk -F',' 'BEGIN {OFS=\"\t\"} {print \$1, \$2, \$3}' /tmp/sample.csv | head -3"
    awk -F',' 'BEGIN {OFS="\t"} {print $1, $2, $3}' /tmp/sample.csv | head -3
    
    echo
    echo -e "${GREEN}Calculate department average salary:${NC}"
    print_command "awk -F',' 'NR>1 {sum[\$4]+=\$3; cnt[\$4]++} END {for (d in sum) printf \"%s: %.2f\n\", d, sum[d]/cnt[d]}' /tmp/sample.csv"
    awk -F',' 'NR>1 {sum[$4]+=$3; cnt[$4]++} END {for (d in sum) printf "%s: %.2f\n", d, sum[d]/cnt[d]}' /tmp/sample.csv
    
    echo
    echo -e "${GREEN}Filter and reformat log errors:${NC}"
    print_command "awk '/ERROR/ {print \$1, \$2, \"-\", substr(\$0, index(\$0,\$4))}' /tmp/sample.log"
    awk '/ERROR/ {print $1, $2, "-", substr($0, index($0,$4))}' /tmp/sample.log
    
    echo
    echo -e "${GREEN}Add line numbers to output:${NC}"
    print_command "awk '{printf \"%3d: %s\n\", NR, \$0}' /tmp/sample.txt"
    awk '{printf "%3d: %s\n", NR, $0}' /tmp/sample.txt
}

# Cleanup function
cleanup() {
    print_section "Cleanup"
    rm -f /tmp/sample.csv /tmp/sample.log /tmp/sample.txt /tmp/numbers.txt
    echo -e "${GREEN}✓ Temporary files removed${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║         AWK Usage Test Script - Runnable Examples         ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    create_sample_data
    test_basic_fields
    test_field_separator
    test_pattern_matching
    test_conditionals
    test_calculations
    test_begin_end
    test_string_functions
    test_formatted_output
    test_arrays
    test_advanced
    test_real_world
    cleanup
    
    print_section "All Tests Completed Successfully!"
    echo -e "${GREEN}Review the output above to understand AWK capabilities.${NC}"
    echo -e "${GREEN}Modify this script to experiment with your own data!${NC}\n"
}

# Run main function
main
