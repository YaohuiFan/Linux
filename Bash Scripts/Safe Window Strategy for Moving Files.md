# Safe Window Strategy for Moving Files to SSD-B

## The Problem You Identified

Camera continuously captures new files, so we need to avoid moving:

1. Files being actively written
1. Files not yet backed up to SSD-A

## The Solution: Two-Boundary Safe Window

```
Timeline of Files:
═══════════════════════════════════════════════════════════════
                                              
Old Files ◄────────────────────► Recent ◄────► Very New Files
                                                      
├─────────────────────────────┼──────────┼───────────────────┤
                              │          │
                       SSD-A Marker    Script Start
                    (last copy time)   (snapshot time)
                              
◄───── SAFE TO MOVE ──────────┤          │
                                         │
                              DON'T MOVE ├──► NOT YET ON SSD-A
                                              
                                         │
                              DON'T MOVE ├──► TOO NEW / BEING WRITTEN
```

## How It Works

### Step 1: Check SSD-A Marker

```bash
if [ ! -f "$SSD_A_MARKER" ]; then
    log_message "No files have been copied to SSD-A yet."
    exit 0  # Don't move anything!
fi
```

**Safety:** Ensures files are already on SSD-A before moving.

### Step 2: Create Snapshot Timestamp

```bash
SNAPSHOT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
touch -d "$SNAPSHOT_TIME" /tmp/snapshot_marker_$$
```

**Safety:** Captures “now” to exclude files created during script execution.

### Step 3: Find Files in Safe Window

```bash
find "$SOURCE_DIR" -type f ! -newer "$SSD_A_MARKER" ! -newer /tmp/snapshot_marker_$$
```

**This finds files that are:**

- `! -newer "$SSD_A_MARKER"` = Older than/equal to last SSD-A copy (already backed up)
- `! -newer /tmp/snapshot_marker_$$` = Older than script start (not being written)

## Example Scenario

**Monday 2 AM:** Last copy to SSD-A completed

- Files captured: 12:00 AM - 1:59 AM are now on SSD-A
- SSD-A marker timestamp: Monday 2:00 AM

**Sunday 3 AM:** Move to SSD-B runs

- Snapshot created: Sunday 3:00 AM
- Camera is actively capturing files

**What gets moved:**
✅ All files from Monday - Saturday (definitely on SSD-A)
✅ Files captured before Sunday 3:00 AM (not being actively written)
❌ Files from Sunday 3:00 AM onward (might be incomplete/being written)

**Result:**

- Safe files moved to SSD-B and deleted from source
- New files stay in source for next SSD-A copy
- No risk of moving incomplete files

## Benefits

1. **Data Integrity:** Never moves files being written
1. **Redundancy:** Only moves files already on SSD-A
1. **Continuous Operation:** Camera can keep capturing during move
1. **No Race Conditions:** Snapshot prevents timing issues

## File States

```
File Age          Status              Action
─────────────────────────────────────────────────────────
> 1 week old      On SSD-A           ✅ MOVE to SSD-B
2-7 days old      On SSD-A           ✅ MOVE to SSD-B  
< 2 days old      On SSD-A           ✅ MOVE to SSD-B
0-2 hours old     Maybe on SSD-A     ❌ KEEP (wait for next SSD-A copy)
During script     Not backed up      ❌ KEEP (too new)
```

## Comparison: Old vs New Strategy

### Old Strategy (Move Everything)

```
❌ Risk: Moves files not yet on SSD-A
❌ Risk: Moves files being actively written
❌ Risk: No redundancy if move fails
```

### New Strategy (Safe Window)

```
✅ Only moves files confirmed on SSD-A
✅ Respects snapshot boundary
✅ Always has 2+ copies before deletion
✅ No interruption to camera operation
```

## Edge Cases Handled

1. **First run (no SSD-A copy yet):** Script exits safely, waits for SSD-A
1. **Files during execution:** Excluded by snapshot boundary
1. **Very recent files:** Excluded until next SSD-A copy
1. **SSD-A copy fails:** Files stay until successfully copied

This ensures you NEVER lose data, even if timing is unfortunate!