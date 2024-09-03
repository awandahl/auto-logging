#!/bin/bash

# Set environment variables
export HOME=/home/aw
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Enable error logging by redirecting stderr to a log file
exec 2>> /home/aw/logsync/eqsl/eqsl_error.log
set -x

# Configuration variables for eQSL
EQSL_USERNAME="SM0HPL"  # Your eQSL.cc username
EQSL_PASSWORD="**********"  # Your eQSL.cc password
LOG_FILE="/home/aw/.local/share/WSJT-X/wsjtx_log.adi"  # Path to the main ADIF log file
LOG_OUTPUT="/home/aw/logsync/eqsl/eqsl_output.log"  # Path to the output log file
LAST_LINE_FILE="/home/aw/logsync/eqsl/eqsl_last_line.txt"  # File to store the last uploaded log line

# Boolean flag to include comments
INCLUDE_COMMENTS=false  # Set to true to include comments, false to exclude

# Function for logging messages to the output log file
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_OUTPUT"
}

# URL-encode function
urlencode() {
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c"
        esac
    done
}

# URL-encode the username and password
ENCODED_USERNAME=$(urlencode "$EQSL_USERNAME")
ENCODED_PASSWORD=$(urlencode "$EQSL_PASSWORD")

# Get the last line of the current log file to determine the most recent entry
CURRENT_LAST_LINE=$(tail -n 1 "$LOG_FILE")

# Check if the last uploaded line file exists and read its content
if [ -f "$LAST_LINE_FILE" ]; then
    STORED_LAST_LINE=$(cat "$LAST_LINE_FILE")
else
    # Initialize the last line file with the current last line if it doesn't exist
    echo "$CURRENT_LAST_LINE" > "$LAST_LINE_FILE"
    log_message "Initialized LAST_LINE_FILE with the current last line."
    echo "Initialized LAST_LINE_FILE with the current last line. No new logs to upload."
    exit 0
fi

# Compare the current last line with the stored last line to check for new entries
if [ "$CURRENT_LAST_LINE" == "$STORED_LAST_LINE" ]; then
    log_message "No changes in log file since last upload. Exiting."
    echo "No changes in log file since last upload. Nothing to do."
    exit 0
fi

log_message "Starting eQSL upload process"

# Escape special characters in the stored last line for safe use in sed
ESCAPED_STORED_LAST_LINE=$(echo "$STORED_LAST_LINE" | sed 's/[&/\]/\\&/g')

# Extract new lines from the log file since the last upload
NEW_LINES=$(sed -n "/$ESCAPED_STORED_LAST_LINE/,\$p" "$LOG_FILE" | tail -n +2)

# Write the new lines to a temporary file for processing
TEMP_FILE=$(mktemp)
echo "<ADIF_VERS:5>3.1.0
<PROGRAMID:6>wsjt-x
<PROGRAMVERSION:3>2.6
<EOH>" > "$TEMP_FILE"

# Add each new line, optionally including a QSLMSG field
while read -r line; do
    if [ "$INCLUDE_COMMENTS" = true ]; then
        echo "$line <QSLMSG:13>Custom Comment <eor>" >> "$TEMP_FILE"
    else
        echo "$line <eor>" >> "$TEMP_FILE"
    fi
done <<< "$NEW_LINES"

# Debug: Verify the contents of the temporary file
if [ -s "$TEMP_FILE" ]; then
    log_message "Temporary ADIF file created with the following contents:"
    cat "$TEMP_FILE" >> "$LOG_OUTPUT"
else
    log_message "Temporary ADIF file is empty or not created."
    echo "Temporary ADIF file is empty or not created."
    exit 1
fi

# Use curl to upload the new log entries to eQSL.cc and capture the response
RESPONSE=$(curl -s --data-urlencode "ADIFData=$(<"$TEMP_FILE")" \
     "https://www.eqsl.cc/qslcard/importADIF.cfm?EQSL_USER=$ENCODED_USERNAME&EQSL_PSWD=$ENCODED_PASSWORD")

# Parse the response to get the number of records added and duplicates
RECORDS_ADDED=$(echo "$RESPONSE" | grep -oP 'Result: \K\d+(?= out of \d+ records added)')
TOTAL_RECORDS=$(echo "$RESPONSE" | grep -oP 'Result: \d+ out of \K\d+(?= records added)')
DUPLICATES=$((TOTAL_RECORDS - RECORDS_ADDED))

# Check if any records were added successfully
if [ -z "$RECORDS_ADDED" ]; then
    RECORDS_ADDED=0
fi

if [ -z "$TOTAL_RECORDS" ]; then
    TOTAL_RECORDS=0
fi

if [ "$RECORDS_ADDED" -gt 0 ]; then
    log_message "$RECORDS_ADDED records uploaded successfully, $DUPLICATES duplicate(s) found"
    echo "$RECORDS_ADDED records uploaded successfully, $DUPLICATES duplicate(s) found"
    # Update the stored last line with the current last line after a successful upload
    echo "$CURRENT_LAST_LINE" > "$LAST_LINE_FILE"
elif [ "$DUPLICATES" -gt 0 ]; then
    log_message "No new records uploaded. $DUPLICATES duplicate(s) found"
    echo "No new records uploaded. $DUPLICATES duplicate(s) found"
else
    log_message "Error uploading log to eQSL.cc. Check $LOG_OUTPUT for details"
    echo "Error uploading log to eQSL.cc. Check $LOG_OUTPUT for details"
    echo "Server response: $RESPONSE" >> "$LOG_OUTPUT"
fi

# Clean up the temporary file
rm "$TEMP_FILE"

log_message "eQSL upload process completed"

