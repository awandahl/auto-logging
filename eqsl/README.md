# eQSL Upload Script

This bash script automates the process of uploading ADIF (Amateur Data Interchange Format) log entries to eQSL.cc. It's designed to work with WSJT-X log files and upload new entries since the last upload.

## Configuration Variables

```
EQSL_USERNAME="SM0HPL"
EQSL_PASSWORD="**********"
LOG_FILE="/home/aw/.local/share/WSJT-X/wsjtx_log.adi"
LOG_OUTPUT="/home/aw/logsync/eqsl/eqsl_output.log"
LAST_LINE_FILE="/home/aw/logsync/eqsl/eqsl_last_line.txt"
INCLUDE_COMMENTS=false
```
These variables set up the necessary configuration for the script:  
- eQSL.cc credentials (username and password)
- Path to the WSJT-X log file
- Path to the script's output log
- Path to a file that stores the last uploaded log entry
- Option to include comments in the upload
  
## Environment Setup

```
export HOME=/home/aw
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
exec 2>> /home/aw/logsync/eqsl/eqsl_error.log
set -x
```
The script sets up the environment variables and enables error logging.

## Log Message Function
```
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_OUTPUT"
}
```
This function writes timestamped messages to the log output file.

## URL Encode Function
```
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
```
This function URL-encodes strings for safe transmission over HTTP.

## Main Script Logic
Check for New Entries: 
```
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
```
The script compares the last line of the current log file with the stored last line from the previous run. If they're the same, it means there are no new entries to upload, and the script exits.

Extract New Log Entries: 
```

```
If there are new entries, the script extracts them from the log file, starting from the line after the last uploaded entry.

Prepare Temporary File: 
```

```
The script creates a temporary file with the new log entries, including ADIF header information.

Upload to eQSL: 
```

```
The script uses curl to upload the new log entries to eQSL.cc

Parse Response: 
```

```
The script parses the response from eQSL to determine the number of records added and duplicates found.

Handle Upload Result: Based on the parsed response, the script logs the result of the upload (success, duplicates, or errors).
Update Last Line File: 
```

```
After a successful upload, the script updates the last line file with the most recent log entry, preparing for the next run.

Cleanup: 
```

```
The temporary file is removed after the upload process.

## Notable Features
- The script can optionally include custom comments for each QSO.  
- It handles duplicate entries by reporting them separately.  
- The script uses URL encoding to ensure special characters are properly transmitted.  
   
## Usage
- Ensure the configuration variables are set correctly for your eQSL account and file paths.  
- Make the script executable: ```chmod +x eqsl_upload.sh```  
- Run the script: ```./eqsl_upload.sh```  
- The script can be run manually or set up as a cron job for automatic, periodic uploads.  

## Notes
- The script is designed to work with WSJT-X log files but can be adapted for other ADIF-formatted logs.  
- Ensure your eQSL credentials are kept secure, as they are stored in plain text in the script.  
- The script includes error logging to help with troubleshooting.  
