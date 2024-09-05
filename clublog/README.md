

# Club Log ADIF Upload Script

This script automates the process of uploading ADIF (Amateur Data Interchange Format) log entries to Club Log. It's designed to work with WSJT-X log files and upload new entries since the last upload.

## Configuration Variables

```bash
CLUBLOG_EMAIL="anders@golonka.se"
CLUBLOG_PASSWORD="*****"
CLUBLOG_CALLSIGN="SM0HPL"
CLUBLOG_API_KEY="*****"
LOG_FILE="/home/aw/.local/share/WSJT-X/wsjtx_log.adi"
LOG_OUTPUT="/home/aw/logsync/clublog/clublog_output.log"
LAST_LINE_FILE="/home/aw/logsync/clublog/clublog_last_line.txt"
````

These variables set up the necessary configuration for the script:  
Club Log credentials (email, password, callsign, API key)  
Path to the WSJT-X log file  
Path to the script's output log  
Path to a file that stores the last uploaded log entry  
Utility Functions  
Log Message Function

````
bash
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_OUTPUT"
}
````
This function writes timestamped messages to the log output file, helping track the script's activities.

## URL Encode Function
````
bash
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
````
This function URL-encodes strings, which is necessary for sending data via HTTP, especially when the data contains special characters.

## Main Script Logic

### 1. Check for New Entries
````
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
````
The script compares the last line of the current log file with the stored last line from the previous run. If they're the same, it means there are no new entries to upload, and the script exits.

### 2. Extract New Log Entries
````
# Extract new lines from the log file
ESCAPED_STORED_LAST_LINE=$(echo "$STORED_LAST_LINE" | sed 's/[&/\]/\\&/g')
NEW_LINES=$(sed -n "/$ESCAPED_STORED_LAST_LINE/,\$p" "$LOG_FILE" | tail -n +2)

# Write the new lines to a temporary file for processing
TEMP_FILE=$(mktemp)
echo "$NEW_LINES" > "$TEMP_FILE"

# Debug: Echo the contents of TEMP_FILE
# echo "Contents of TEMP_FILE:"
# cat "$TEMP_FILE"
````
If there are new entries, the script extracts them from the log file, starting from the line after the last uploaded entry.

### 3. Process Each New Entry
````
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
````
The script processes each new log entry individually:  
URL-encodes the ADIF record  
Uploads the record to Club Log using curl  
Checks the response from Club Log  

### 4. Handle Club Log Responses
````
if [[ "$RESPONSE" == *"OK"* ]]; then
    log_message "Log entry successfully uploaded to Club Log: $line"
elif [[ "$RESPONSE" == *"Dupe"* ]]; then
    log_message "Duplicate entry detected by Club Log: $line"
else
    log_message "Error uploading log entry to Club Log: $line"
    log_message "Server response: $RESPONSE"
fi
done < "$TEMP_FILE"
````
The script interprets the response from Club Log:  
If the response contains "OK", it logs a successful upload  
If the response contains "Dupe", it logs that the entry was a duplicate  
For any other response, it logs an error  

### 5. Update Last Line File
````
echo "$CURRENT_LAST_LINE" > "$LAST_LINE_FILE"

# Clean up the temporary file
rm "$TEMP_FILE"
log_message "Club Log upload process completed"
echo "Club Log upload process completed"
````
After processing all new entries, the script updates the last line file with the most recent log entry, preparing for the next run.

## Usage
Ensure the configuration variables are set correctly for your Club Log account and file paths.  
Make the script executable: ````chmod +x clublog_upload.sh````  
Run the script: ````./clublog_upload.sh````  
The script can be run manually or set up as a cron job for automatic, periodic uploads.  

## Notes
The script uses the Club Log real-time API (https://clublog.org/realtime.php) for uploads.
It's designed to work with WSJT-X log files, but can be adapted for other ADIF-formatted logs.
Ensure your Club Log credentials are kept secure, as they are stored in plain text in the script.


