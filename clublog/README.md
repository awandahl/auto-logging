

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

##Log Message Function
````
bash
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_OUTPUT"
}
````
This function writes timestamped messages to the log output file, helping track the script's activities.

URL Encode Function
````
bash
urlencode() {
    # ... (function body)
}
````
This function URL-encodes strings, which is necessary for sending data via HTTP, especially when the data contains special characters.

Main Script Logic
1. Check for New Entries
The script compares the last line of the current log file with the stored last line from the previous run. If they're the same, it means there are no new entries to upload, and the script exits.
2. Extract New Log Entries
If there are new entries, the script extracts them from the log file, starting from the line after the last uploaded entry.
3. Process Each New Entry
The script processes each new log entry individually:
URL-encodes the ADIF record
Uploads the record to Club Log using curl
Checks the response from Club Log
4. Handle Club Log Responses
The script interprets the response from Club Log:
If the response contains "OK", it logs a successful upload
If the response contains "Dupe", it logs that the entry was a duplicate
For any other response, it logs an error
5. Update Last Line File
After processing all new entries, the script updates the last line file with the most recent log entry, preparing for the next run.
Usage
Ensure the configuration variables are set correctly for your Club Log account and file paths.
Make the script executable: chmod +x script_name.sh
Run the script: ./script_name.sh
The script can be run manually or set up as a cron job for automatic, periodic uploads.
Notes
The script uses the Club Log real-time API (https://clublog.org/realtime.php) for uploads.
It's designed to work with WSJT-X log files, but can be adapted for other ADIF-formatted logs.
Ensure your Club Log credentials are kept secure, as they are stored in plain text in the script.
text

