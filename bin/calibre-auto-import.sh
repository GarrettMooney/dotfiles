#!/bin/bash
# Auto-import new PDFs/EPUBs from ~/books into Calibre library
LIBRARY="$HOME/calibre-library"
WATCH_DIR="$HOME/books"
LOG="$HOME/.local/share/calibre-auto-import.log"

mkdir -p "$(dirname "$LOG")"

for f in "$WATCH_DIR"/*.pdf "$WATCH_DIR"/*.epub "$WATCH_DIR"/*.mobi "$WATCH_DIR"/*.azw3; do
    [ -f "$f" ] || continue
    if /opt/homebrew/bin/calibredb add "$f" --library-path "$LIBRARY" 2>&1 | tee -a "$LOG" | grep -q "Added book ids"; then
        echo "$(date): Imported $(basename "$f")" >> "$LOG"
    fi
done
