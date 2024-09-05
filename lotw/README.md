
# LoTW Upload Script

This bash script automates the process of uploading ADIF (Amateur Data Interchange Format) log entries to LoTW (Logbook of The World). It's designed to work with WSJT-X log files and upload new entries since the last upload.

## Configuration Variables
```
DEFAULT_CALLSIGN="SM0HPL"
LOG_FILE="/home/aw/.local/share/WSJT-X/wsjtx_log.adi"
STATION_LOCATION="Home"
LOG_OUTPUT="/home/aw/logsync/lotw/lotw_output.log"
LAST_LINE_FILE="/home/aw/logsync/lotw/lotw_last_line.txt"
```
These variables set up the necessary configuration for the script:
- Default callsign for LoTW uploads
- Path to the WSJT-X log file
- Station location for LoTW
- Path to the script's output log
- Path to a file that stores the last uploaded log entry
  
## Log Message Function
```
Log Message Function
bash
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_OUTPUT"
}
```
This function writes timestamped messages to the log output file, helping track the script's activities.

## Main Script Logic
### 1. Check for New Entries:
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

### 2. Extract New Log Entries:
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
The script writes the new log entries to a temporary file and makes a backup of the log file.

### 3. Upload to LoTW:
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
The script uses xvfb-run to run tqsl (the LoTW signing and upload tool) with the temporary file containing new entries,  
using xvfb-run to run tqsl in a virtual framebuffer, allowing it to run without a graphical environment.
After a successful upload, the script updates the last line file with the most recent log entry, preparing for the next run.
The temporary file is removed after the upload process.

## Usage
Ensure the configuration variables are set correctly for your LoTW account and file paths.  
Make sure tqsl is installed and configured with valid LoTW certificates.
Make the script executable: ```chmod +x lotw_upload.sh```
Run the script: ```./lotw_upload.sh```
The script can be run manually or set up as a cron job for automatic, periodic uploads.

