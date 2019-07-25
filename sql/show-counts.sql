#!/bin/bash
echo "Task,Time"
source config

SECONDS_PER_HOUR=3600.0
EXPECTED_RATE=$((SAMPLE_RATE + MIN_ALERT_SPACING))

sqlite3 << EOF
.mode csv
.import "$OUTPUT_FILENAME" log
SELECT Task, Count(Task) FROM log GROUP BY Task;
EOF
