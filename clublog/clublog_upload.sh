#!/bin/bash

# Set environment variables
export HOME=/home/aw
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Enable error logging by redirecting stderr to a log file
exec 2>> /home/aw/logsync/clublog/clublog_error.log
set -x

# Configuration variables for Club Log
CLUBLOG_EMAIL="anders@golonka.se"  # Your Club Log email
CLUBLOG_PASSWORD="your_password"  # Your Club Log password or application password
CLUBLOG_CALLSIGN="SM0HPL"  # Your callsign
CLUBLOG_API_KEY="your_api_key"  # Your Club Log API key
LOG_FILE="/home/aw/.local/share/WSJT-X/wsjtx_log.adi"  # Path to the main ADIF log file
LOG_OUTPUT="/home/aw/logsync/clublog/clublog_output.log"  # Path to the output log file
LAST_LINE_FILE="/home/aw/logsync/clublog/clublog_last_line.txt"  # File to store the last uploaded log line

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

# URL-encode the email and password
ENCODED_EMAIL=$(urlencode "$CLUBLOG_EMAIL")
ENCODED_PASSWORD=$(urlencode "$CLUBLOG_PASSWORD")

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

log_message "Starting Club Log upload process"

# Escape special characters in the stored last line for safe use in sed
ESCAPED_STORED_LAST_LINE=$(echo "$STORED_LAST_LINE" | sed 's/[&/\]/\\&/g')

# Extract new lines from the log file since the last upload
NEW_LINES=$(sed -n "/$ESCAPED_STORED_LAST_LINE/,\$p" "$LOG_FILE" | tail -n +2)

# Write the new lines to a temporary file for processing
TEMP_FILE=$(mktemp)
echo "$NEW_LINES" > "$TEMP_FILE"

# Debug: Verify the contents of the temporary file
if [ -s "$TEMP_FILE" ]; then
    log_message "Temporary ADIF file created with the following contents:"
    cat "$TEMP_FILE" >> "$LOG_OUTPUT"
else
    log_message "Temporary ADIF file is empty or not created."
    echo "Temporary ADIF file is empty or not created."
    exit 1
fi

# Use curl to upload the new log entries to Club Log and capture the response
RESPONSE=$(curl -s -X POST \
     -F "email=$ENCODED_EMAIL" \
     -F "password=$ENCODED_PASSWORD" \
     -F "callsign=$CLUBLOG_CALLSIGN" \
     -F "api=$CLUBLOG_API_KEY" \
     -F "file=@$TEMP_FILE" \
     https://clublog.org/putlogs.php)

# Check if the upload was successful
if [[ "$RESPONSE" == *"HTTP/1.1 200 OK"* ]]; then
    log_message "Log successfully uploaded to Club Log"
    echo "Log successfully uploaded to Club Log"
    # Update the stored last line with the current last line after a successful upload
    echo "$CURRENT_LAST_LINE" > "$LAST_LINE_FILE"
else
    log_message "Error uploading log to Club Log. Check $LOG_OUTPUT for details"
    echo "Error uploading log to Club Log. Check $LOG_OUTPUT for details"
    echo "Server response: $RESPONSE" >> "$LOG_OUTPUT"
fi

# Clean up the temporary file
rm "$TEMP_FILE"

log_message "Club Log upload process completed"

