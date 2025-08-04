#!/bin/bash

# Define output and log files
LOG_FILE="sys_log.txt"
OUTPUT_FILE="top10_critical.txt"

# Check if the log file exists > warning if not
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' not found!" 
    exit 1
fi

# filter, count, and sort key words
grep -ioE 'error|critical|fatal' "$LOG_FILE" | \
tr '[:upper:]' '[:lower:]' | \
sort | \
uniq -c | \
sort -nr | \
head -n 10 | \
tee "$OUTPUT_FILE"

echo "Results saved to $OUTPUT_FILE"
