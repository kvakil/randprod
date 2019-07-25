#!/bin/bash
echo "Day,Time"
source config

SECONDS_PER_HOUR=3600.0
EXPECTED_RATE=$((SAMPLE_RATE + MIN_ALERT_SPACING))

sqlite3 << EOF
.mode csv
.import "$OUTPUT_FILENAME" log
SELECT Day, "$EXPECTED_RATE" * COUNT() / "$SECONDS_PER_HOUR" FROM
(SELECT *, date(Time, 'localtime') as Day FROM log)
WHERE Task <> 'Timeout'
GROUP BY Day;
EOF
