#!/bin/bash

# Script to move camera captures to SSD-4TB.04 for backup
# Runs weekly via cron - archives and frees up local space
# Only moves files that are already backed up to SSD-A (safe window)

SOURCE_DIR="/nssams/run/capture"
DEST_DIR="/media/nssams/4TB.04/camera_backup"
SSD_A_MARKER="/var/log/camera_sync/last_copy_to_ssd_a.marker"
MARKER_FILE="/var/log/camera_sync/last_move_to_ssd_b.marker"
LOG_FILE="/var/log/camera_sync/move_to_ssd_b.log"
TEMP_FILE_LIST="/tmp/camera_files_to_move_$$.txt"

# Create directories if they don't exist
mkdir -p "$(dirname '$MARKER_FILE')"
mkdir -p "$(dirname '$LOG_FILE')"
mkdir -p "$DEST_DIR"

# Function to log messages

log_message() {
echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Cleanup temp file on exit

cleanup() {
rm -f "$TEMP_FILE_LIST"
}
trap cleanup EXIT

log_message "=== Starting weekly move to SSD-B ==="

# Check if source directory exists

if [ ! -d "$SOURCE_DIR" ]; then
log_message "ERROR: Source directory $SOURCE_DIR does not exist"
exit 1
fi

# Check if destination is mounted

if [ ! -d "$DEST_DIR" ]; then
log_message "ERROR: Destination directory $DEST_DIR not accessible (SSD-B not mounted?)"
exit 1
fi

# Check if SSD-A marker exists (ensures files were copied to SSD-A)

if [ ! -f "$SSD_A_MARKER" ]; then
log_message "WARNING: SSD-A marker not found. No files have been copied to SSD-A yet."
log_message "Skipping move to avoid data loss. Run copy_to_ssd_a.sh first."
exit 0
fi

# Create snapshot timestamp BEFORE we start (to avoid moving files created during execution)

SNAPSHOT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
touch -d "$SNAPSHOT_TIME" /tmp/snapshot_marker_$$
log_message "Snapshot time: $SNAPSHOT_TIME"

# Create dated backup directory

BACKUP_SUBDIR="backup_$(date '+%Y-%m-%d')"
FULL_DEST="$DEST_DIR/$BACKUP_SUBDIR"
mkdir -p "$FULL_DEST"

# Find files that are:

# 1. Older than the snapshot time (not being actively created)

# 2. Older than or equal to the SSD-A marker (already backed up to SSD-A)

log_message "Finding files safe to move (already on SSD-A and before snapshot)…"

find "$SOURCE_DIR" -type f ! -newer "$SSD_A_MARKER" ! -newer /tmp/snapshot_marker_$$ > "$TEMP_FILE_LIST"

TOTAL_FILES=$(wc -l < "$TEMP_FILE_LIST")
log_message "Found $TOTAL_FILES files safe to move"

if [ "$TOTAL_FILES" -eq 0 ]; then
log_message "No files to move (all files either too new or not yet on SSD-A)"
rm -f /tmp/snapshot_marker_$$
exit 0
fi

# Show age range of files to be moved

OLDEST_FILE=$(find "$SOURCE_DIR" -type f ! -newer "$SSD_A_MARKER" ! -newer /tmp/snapshot_marker_$$ -printf '%T+ %p\n' 2>/dev/null | sort | head -1 | cut -d' ' -f1)
NEWEST_FILE=$(find "$SOURCE_DIR" -type f ! -newer "$SSD_A_MARKER" ! -newer /tmp/snapshot_marker_$$ -printf '%T+ %p\n' 2>/dev/null | sort | tail -1 | cut -d' ' -f1)
log_message "File age range: $OLDEST_FILE to $NEWEST_FILE"

# Calculate space before

SPACE_BEFORE=$(du -sh "$SOURCE_DIR" 2>/dev/null | cut -f1)
log_message "Source directory size before move: $SPACE_BEFORE"

# Move files to backup (rsync then delete source)

log_message "Moving files to $FULL_DEST…"
rsync -av –files-from="$TEMP_FILE_LIST" –remove-source-files / "$FULL_DEST/" 2>&1 | tee -a "$LOG_FILE"

RSYNC_EXIT=$?

# Clean up snapshot marker

rm -f /tmp/snapshot_marker_$$

if [ $RSYNC_EXIT -eq 0 ]; then
# Remove empty directories from source
find "$SOURCE_DIR" -type d -empty -delete 2>/dev/null

```
# Update marker file
touch "$MARKER_FILE"

# Verify move
REMAINING_FILES=$(find "$SOURCE_DIR" -type f | wc -l)
MOVED_FILES=$TOTAL_FILES
log_message "Move completed - moved $MOVED_FILES files, $REMAINING_FILES files remaining in source"

# Calculate freed space
SPACE_AFTER=$(du -sh "$SOURCE_DIR" 2>/dev/null | cut -f1)
log_message "Source directory size after move: $SPACE_AFTER (was: $SPACE_BEFORE)"

# Calculate backup size
BACKUP_SIZE=$(du -sh "$FULL_DEST" 2>/dev/null | cut -f1)
log_message "Backup size: $BACKUP_SIZE"

# Calculate total SSD-B usage
TOTAL_BACKUP_SIZE=$(du -sh "$DEST_DIR" 2>/dev/null | cut -f1)
log_message "SSD-B total space used: $TOTAL_BACKUP_SIZE"

log_message "Weekly backup completed successfully"
log_message "Safe window strategy: Only moved files already on SSD-A and captured before script started"
```

else
log_message "ERROR: rsync failed with exit code $RSYNC_EXIT"
log_message "Files NOT deleted from source for safety"
exit 1
fi

log_message "=== Weekly move to SSD-B finished ==="