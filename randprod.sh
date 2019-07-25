#!/bin/bash
set -Eeuo pipefail
source config
[ -f "$OUTPUT_FILENAME" ] || echo Time,Task > "$OUTPUT_FILENAME"
MAX_RANDOM=$((2**15))
THRESHOLD=$((MAX_RANDOM / SAMPLE_RATE))
while : ; do
    if [ "$RANDOM" -lt "$THRESHOLD" ]; then
        printf "%s,%s\n" \
            "$(date +"%Y-%m-%dT%H:%M:%S%:z")" \
            "$(zenity --title=randprod --timeout="$TIMEOUT" \
                      --height "$HEIGHT" --list --column "Task" \
                      "${TASKS[@]}" || echo Timeout)" \
                      >> "$OUTPUT_FILENAME"
        sleep "$MIN_ALERT_SPACING"
    fi
    sleep 1
done
