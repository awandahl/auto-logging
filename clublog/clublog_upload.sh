#!/bin/bash

# Configuration variables
CLUBLOG_EMAIL="anders@golonka.se"
CLUBLOG_PASSWORD="*****"
CLUBLOG_CALLSIGN="SM0HPL"
CLUBLOG_API_KEY="*****"
LOG_FILE="/home/aw/.local/share/WSJT-X/wsjtx_log.adi"
LOG_OUTPUT="/home/aw/logsync/clublog/clublog_output.log"
LAST_LINE_FILE="/home/aw/logsync/clublog/clublog_last_line.txt"

# Function for logging messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_OUTPUT"
}

# URL-encode function
urlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * )               printf -v o '%%%02x' "'$c"
        esac
        encoded+="${o}"
    done
    echo "${encoded}"
}

# Get the last line of the current log file
CURRENT_LAST_LINE=$(tail -n 1 "$LOG_FILE")

# Check if there are new entries
if [ -f "$LAST_LINE_FILE" ]; then
    STORED_LAST_LINE=$(cat "$LAST_LINE_FILE")
    if [ "$CURRENT_LAST_LINE" == "$STORED_LAST_LINE" ]; then
        log_message "No changes in log file since last upload. Exiting."
        echo "No changes in log file since last upload. Nothing to do."
        exit 0
    fi
else
    echo "$CURRENT_LAST_LINE" > "$LAST_LINE_FILE"
    log_message "Initialized LAST_LINE_FILE with the current last line."
    echo "Initialized LAST_LINE_FILE with the current last line. No new logs to upload."
    exit 0
fi

log_message "Starting Club Log upload process"

# Extract new lines from the log file
ESCAPED_STORED_LAST_LINE=$(echo "$STORED_LAST_LINE" | sed 's/[&/\]/\\&/g')
NEW_LINES=$(sed -n "/$ESCAPED_STORED_LAST_LINE/,\$p" "$LOG_FILE" | tail -n +2)

# Write the new lines to a temporary file for processing
TEMP_FILE=$(mktemp)
echo "$NEW_LINES" > "$TEMP_FILE"

# Debug: Echo the contents of TEMP_FILE
# echo "Contents of TEMP_FILE:"
# cat "$TEMP_FILE"

# Process each new line
while IFS= read -r line; do
    # URL-encode the ADIF record
    ENCODED_ADIF=$(urlencode "$line")
    
    # Use curl to upload the ADIF record to Club Log and capture the response
    RESPONSE=$(curl -s -X POST \
         -H "Content-Type: application/x-www-form-urlencoded" \
         -d "email=$CLUBLOG_EMAIL" \
         -d "password=$CLUBLOG_PASSWORD" \
         -d "callsign=$CLUBLOG_CALLSIGN" \
         -d "api=$CLUBLOG_API_KEY" \
         -d "adif=$ENCODED_ADIF" \
         https://clublog.org/realtime.php)

    # Check if the upload was successful
if [[ "$RESPONSE" == *"OK"* ]]; then
    log_message "Log entry successfully uploaded to Club Log: $line"
elif [[ "$RESPONSE" == *"Dupe"* ]]; then
    log_message "Duplicate entry detected by Club Log: $line"
else
    log_message "Error uploading log entry to Club Log: $line"
    log_message "Server response: $RESPONSE"
fi
done < "$TEMP_FILE"

# Update the stored last line with the current last line after all uploads
echo "$CURRENT_LAST_LINE" > "$LAST_LINE_FILE"

# Clean up the temporary file
rm "$TEMP_FILE"

log_message "Club Log upload process completed"
echo "Club Log upload process completed"
