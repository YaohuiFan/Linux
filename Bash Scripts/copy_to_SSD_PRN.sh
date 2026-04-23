#!/bin/bash

# Script to copy NEW camera captures to SSD for PRN
# Runs manually or every 2 days via cron

SOURCE_DIR="/nssams/run/capture"
DEST_BASE="/media/nssams/4TB.02"

# Create dated subfolder: run_YYYYMMDD
RUN_FOLDER="run-$(date '+%Y%m%d')"
DEST_DIR="$DEST_BASE/$RUN_FOLDER/capture"       
MARKER_FILE="/nssams/run/logs/backup/last_copy_to_ssd_PRN.marker"
LOG_FILE="/nssams/run/logs/backup/copy_to_ssd_PRN.log"
# Create directories if they don't exist
mkdir -p "$(dirname "$MARKER_FILE")"
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$DEST_DIR"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "=== Starting copy to SSD-4TB.02 ==="
log_message "Target folder: $RUN_FOLDER"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    log_message "ERROR: Source directory $SOURCE_DIR does not exist"
    exit 1
fi

# Check if destination is mounted
if [ ! -d "$DEST_DIR" ]; then
    log_message "ERROR: Destination directory $DEST_DIR not accessible (SSD-4TB.02 not mounted?)"
    exit 1
fi

# Find files newer than marker file, or all files if marker doesn't exist
if [ -f "$MARKER_FILE" ]; then
    log_message "Finding files newer than last sync …"
    FILE_COUNT=$(find "$SOURCE_DIR" -type f -newer "$MARKER_FILE" | wc -l)

    if [ "$FILE_COUNT" -eq 0 ]; then
        log_message "No new files to copy"
        exit 0
    fi

    log_message "Found $FILE_COUNT new files to copy"

    # Copy new files while preserving directory structure
    # Use cd to make paths relative for rsync --files-from
    (cd "$SOURCE_DIR" && find . -type f -newer "$MARKER_FILE" -print0) | \
        rsync -av --files-from=- --from0 "$SOURCE_DIR/" "$DEST_DIR/" 2>&1 | tee -a "$LOG_FILE"
else
    log_message "First run - copying all files …"
    rsync -av "$SOURCE_DIR/" "$DEST_DIR/" 2>&1 | tee -a "$LOG_FILE"
fi

RSYNC_EXIT=$?

if [ $RSYNC_EXIT -eq 0 ]; then
    # Update marker file
    touch "$MARKER_FILE"
    log_message "Copy captured files completed successfully"

    # Calculate space used
    SPACE_USED=$(du -sh "$DEST_DIR" 2>/dev/null | cut -f1)
    log_message "SSD-4TB.02 total space used: $SPACE_USED"
else
    log_message "ERROR: rsync failed with exit code $RSYNC_EXIT"
    exit 1
fi

# copy data & log files ...
DEST_ROOT="$DEST_BASE/$RUN_FOLDER"
if ! rsync -aLv /nssams/config/ "$DEST_ROOT/config/"; then
    log_message "ERROR: Failed to copy config directory"
    exit 1
fi
if ! rsync -aLv /nssams/dashboard/ "$DEST_ROOT/dashboard/"; then
    log_message "ERROR: Failed to copy dashboard directory"
    exit 1
fi
if ! rsync -aLV /nssams/run/logs/ "$DEST_ROOT/logs/"; then
    log_message "ERROR: Failed to copy logs directory"
    exit 1
fi
if ! rsync -aLv /nssams/run/data/ "$DEST_ROOT/data/"; then
    log_message "ERROR: Failed to copy data directory"
    exit 1
fi
if ! rsync -aLv /nssams/scripts/ "$DEST_ROOT/scripts/"; then
    log_message "ERROR: Failed to copy scripts directory"
    exit 1
fi
if ! rsync -aLv /nssams/src/ "$DEST_ROOT/src/"; then
    log_message "ERROR: Failed to copy src directory"
    exit 1
fi

# Calculate space used
SPACE_USED=$(du -sh "$DEST_ROOT" 2>/dev/null | cut -f1)
log_message "SSD-4TB.02 total space used: $SPACE_USED"

log_message "=== Copy to SSD-4TB.02 finished ==="
