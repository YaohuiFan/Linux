#!/bin/bash

# Script to copy new camera captures to SSD for PRN

# Runs manually or every 2 days via cron

SOURCE_DIR=”/nssams/run/capture”
DEST_BASE=”/media/nssams/4TB.02”

# Create dated subfolder: run_YYYYMMDD

RUN_FOLDER=“run_$(date ‘+%Y%m%d’)”
DEST_DIR=”$DEST_BASE/$RUN_FOLDER”
MARKER_FILE=”/var/log/camera_sync/last_copy_to_ssd_a.marker”
LOG_FILE=”/var/log/camera_sync/copy_to_ssd_a.log”

# Create directories if they don’t exist

mkdir -p “$(dirname “$MARKER_FILE”)”
mkdir -p “$(dirname “$LOG_FILE”)”
mkdir -p “$DEST_DIR”

# Function to log messages

log_message() {
echo “[$(date ‘+%Y-%m-%d %H:%M:%S’)] $1” | tee -a “$LOG_FILE”
}

log_message “=== Starting copy to SSD-A ===”
log_message “Target folder: $RUN_FOLDER”

# Check if source directory exists

if [ ! -d “$SOURCE_DIR” ]; then
log_message “ERROR: Source directory $SOURCE_DIR does not exist”
exit 1
fi

# Check if destination is mounted

if [ ! -d “$DEST_DIR” ]; then
log_message “ERROR: Destination directory $DEST_DIR not accessible (SSD-A not mounted?)”
exit 1
fi

# Find files newer than marker file, or all files if marker doesn’t exist

if [ -f “$MARKER_FILE” ]; then
log_message “Finding files newer than last sync…”
FILE_COUNT=$(find “$SOURCE_DIR” -type f -newer “$MARKER_FILE” | wc -l)

```
if [ "$FILE_COUNT" -eq 0 ]; then
    log_message "No new files to copy"
    exit 0
fi

log_message "Found $FILE_COUNT new files to copy"

# Copy new files while preserving directory structure
# Use cd to make paths relative for rsync --files-from
(cd "$SOURCE_DIR" && find . -type f -newer "$MARKER_FILE" -print0) | \
    rsync -av --files-from=- --from0 "$SOURCE_DIR/" "$DEST_DIR/" 2>&1 | tee -a "$LOG_FILE"
```

else
log_message “First run - copying all files…”
rsync -av “$SOURCE_DIR/” “$DEST_DIR/” 2>&1 | tee -a “$LOG_FILE”
fi

RSYNC_EXIT=$?

if [ $RSYNC_EXIT -eq 0 ]; then
# Update marker file
touch “$MARKER_FILE”
log_message “Copy completed successfully”

```
# Calculate space used
SPACE_USED=$(du -sh "$DEST_DIR" 2>/dev/null | cut -f1)
log_message "SSD-A total space used: $SPACE_USED"
```

else
log_message “ERROR: rsync failed with exit code $RSYNC_EXIT”
exit 1
fi

log_message “=== Copy to SSD-A finished ===”