
# LoTW (Logbook of The World) Upload Script

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
The script sets up the environment variables and enables error logging:



This function writes timestamped messages to the log output file, helping track the script's activities.
Main Script Logic
Check for New Entries: The script compares the last line of the current log file with the stored last line from the previous run. If they're the same, it means there are no new entries to upload, and the script exits.
Extract New Log Entries: If there are new entries, the script extracts them from the log file, starting from the line after the last uploaded entry.
Prepare Temporary File: The script writes the new log entries to a temporary file.
Backup Log File: The original log file is backed up before processing.
Upload to LoTW: The script uses xvfb-run to run tqsl (the LoTW signing and upload tool) with the temporary file containing new entries.
Handle Upload Result: The script checks if the upload was successful and logs the result accordingly.
Update Last Line File: After a successful upload, the script updates the last line file with the most recent log entry, preparing for the next run.
Cleanup: The temporary file is removed after the upload process.
Usage
Ensure the configuration variables are set correctly for your LoTW account and file paths.
Make sure tqsl is installed and configured with your LoTW credentials.
Make the script executable: chmod +x lotw_upload.sh
Run the script: ./lotw_upload.sh
The script can be run manually or set up as a cron job for automatic, periodic uploads.
Notes
The script uses xvfb-run to run tqsl in a virtual framebuffer, allowing it to run without a graphical environment.
It's designed to work with WSJT-X log files, but can be adapted for other ADIF-formatted logs.
Ensure your LoTW credentials are properly set up in tqsl for this script to work correctly.
