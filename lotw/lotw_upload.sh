#!/bin/bash

# Set environment variables
export HOME=/home/aw
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Enable error logging
exec 2>> /home/aw/logsync/lotw/lotw_error.log
set -x

DEFAULT_CALLSIGN="SM0HPL"
LOG_FILE="/home/aw/.local/share/WSJT-X/wsjtx_log.adi"
STATION_LOCATION="Home"
LOG_OUTPUT="/home/aw/logsync/lotw/lotw_output.log"
LAST_LINE_FILE="/home/aw/logsync/lotw/lotw_last_line.txt"

# Function for logging
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_OUTPUT"
}

# Get the last line of the current log file
CURRENT_LAST_LINE=$(tail -n 1 "$LOG_FILE")

# Check if the last line file exists and read it
if [ -f "$LAST_LINE_FILE" ]; then
    STORED_LAST_LINE=$(cat "$LAST_LINE_FILE")
else
    # If the file doesn't exist, create it and initialize with the current last line
    echo "$CURRENT_LAST_LINE" > "$LAST_LINE_FILE"
    log_message "Initialized LAST_LINE_FILE with the current last line."
    echo "Initialized LAST_LINE_FILE with the current last line. No new logs to upload."
    exit 0
fi

# Compare the current last line with the stored last line
if [ "$CURRENT_LAST_LINE" == "$STORED_LAST_LINE" ]; then
    log_message "No changes in log file since last upload. Exiting."
    echo "No changes in log file since last upload. Nothing to do."
    exit 0
fi

log_message "Starting LoTW upload process"

# Escape special characters in STORED_LAST_LINE for use in sed
ESCAPED_STORED_LAST_LINE=$(echo "$STORED_LAST_LINE" | sed 's/[&/\]/\\&/g')

# Find new lines in the log file since the last upload
NEW_LINES=$(sed -n "/$ESCAPED_STORED_LAST_LINE/,\$p" "$LOG_FILE" | tail -n +2)

# Write new lines to a temporary file
TEMP_FILE=$(mktemp)
echo "$NEW_LINES" > "$TEMP_FILE"

# Backup the log file
/bin/cp "$LOG_FILE" "${LOG_FILE}.bak"

# Use xvfb-run to run tqsl with the temporary file
/usr/bin/xvfb-run -a /usr/local/bin/tqsl -x -u -d -a compliant -c "$DEFAULT_CALLSIGN" -l "$STATION_LOCATION" "$TEMP_FILE" 2>> "$LOG_OUTPUT"

if [ $? -eq 0 ]; then
    log_message "Log successfully signed and uploaded"
    echo "Log successfully signed and uploaded"
    # Update the stored last line with the current last line
    echo "$CURRENT_LAST_LINE" > "$LAST_LINE_FILE"
else
    log_message "Error signing or uploading log. Check $LOG_OUTPUT for details"
    echo "Error signing or uploading log. Check $LOG_OUTPUT for details"
fi

# Clean up the temporary file
rm "$TEMP_FILE"

log_message "LoTW upload process completed"

