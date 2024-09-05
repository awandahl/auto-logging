

# LOTW ADIF Upload Script

This script automates the process of uploading ADIF (Amateur Data Interchange Format) log entries to LOTW (Logbook of the World). It's designed to work with WSJT-X log files and upload new entries since the last upload.

## Configuration Variables

```
DEFAULT_CALLSIGN="SM0HPL"
LOG_FILE="/home/aw/.local/share/WSJT-X/wsjtx_log.adi"
STATION_LOCATION="Home"
LOG_OUTPUT="/home/aw/logsync/lotw/lotw_output.log"
LAST_LINE_FILE="/home/aw/logsync/lotw/lotw_last_line.txt"
```

These variables set up the necessary configuration for the script:  
- LoTW details (callsign, station location)  
- Path to the WSJT-X log file  
- Path to the script's output log  
- Path to a file that stores the last uploaded log entry  
   
## Log Message Function
```
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_OUTPUT"
}
```
This function writes timestamped messages to the log output file, helping track the script's activities.

## URL Encode Function
```
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
```
This function URL-encodes strings, which is necessary for sending data via HTTP, especially when the data contains special characters.

## Main Script Logic

### 1. Check for New Entries
```
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
```
The script compares the last line of the current log file with the stored last line from the previous run. If they're the same, it means there are no new entries to upload, and the script exits.

### 2. Extract New Log Entries
```
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
```
If there are new entries, the script extracts them from the log file, starting from the line after the last uploaded entry.

### 3. Process Each New Entry
```
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
```
The script processes each new log entry individually:  
- URL-encodes the ADIF record  
- Uploads the record to Club Log using curl  
- Checks the response from Club Log  

### 4. Handle Club Log Responses
```
if [[ "$RESPONSE" == *"OK"* ]]; then
    log_message "Log entry successfully uploaded to Club Log: $line"
elif [[ "$RESPONSE" == *"Dupe"* ]]; then
    log_message "Duplicate entry detected by Club Log: $line"
else
    log_message "Error uploading log entry to Club Log: $line"
    log_message "Server response: $RESPONSE"
fi
done < "$TEMP_FILE"
```
The script interprets the response from Club Log:  
- If the response contains "OK", it logs a successful upload  
- If the response contains "Dupe", it logs that the entry was a duplicate  
- For any other response, it logs an error  

### 5. Update Last Line File
```
echo "$CURRENT_LAST_LINE" > "$LAST_LINE_FILE"

# Clean up the temporary file
rm "$TEMP_FILE"
log_message "Club Log upload process completed"
echo "Club Log upload process completed"
```
After processing all new entries, the script updates the last line file with the most recent log entry, preparing for the next run.

## Usage
Ensure the configuration variables are set correctly for your Club Log account and file paths.  
Make the script executable: ```chmod +x clublog_upload.sh```  
Run the script: ```./clublog_upload.sh```  
The script can be run manually or set up as a cron job for automatic, periodic uploads.  

## Notes
The script uses the Club Log real-time API (https://clublog.org/realtime.php) for uploads.  
It's designed to work with WSJT-X log files, but can be adapted for other ADIF-formatted logs.  
Ensure your Club Log credentials are kept secure, as they are stored in plain text in the script.  


