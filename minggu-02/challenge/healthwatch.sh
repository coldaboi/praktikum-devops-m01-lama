#!/usr/bin/env bash

set -euo pipefail

INTERVAL=5
URL="http://127.0.0.1:5000/health"
LOG_FILE="healthwatch.log"

TOTAL_CHECKS=0
INCIDENTS=0
DOWNTIME_SECONDS=0
HAS_INCIDENT=0

CURRENT_STATUS="UNKNOWN"
INCIDENT_START=0

usage() {
    cat <<EOF
Usage: $0 [--interval N] [--url URL]

Options:
  --interval N   Interval pemeriksaan dalam detik (default: 5)
  --url URL      Endpoint health (default: http://127.0.0.1:5000/health)
  -h, --help     Tampilkan bantuan
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --interval)
                shift
                [[ $# -gt 0 ]] || {
                    echo "Error: nilai interval tidak ada"
                    exit 1
                }
                INTERVAL="$1"
                ;;
            --url)
                shift
                [[ $# -gt 0 ]] || {
                    echo "Error: nilai URL tidak ada"
                    exit 1
                }
                URL="$1"
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Argumen tidak dikenal: $1"
                exit 1
                ;;
        esac
        shift
    done
}

validate_args() {

    [[ "$INTERVAL" =~ ^[0-9]+$ ]] || {
        echo "Interval harus berupa angka"
        exit 1
    }

    (( INTERVAL > 0 )) || {
        echo "Interval harus lebih besar dari 0"
        exit 1
    }

    [[ "$URL" =~ ^https?:// ]] || {
        echo "URL harus diawali http:// atau https://"
        exit 1
    }
}

print_summary() {

    local total_runtime
    local availability

    total_runtime=$(( TOTAL_CHECKS * INTERVAL ))

    if (( total_runtime == 0 )); then
        availability="100.00"
    else
        availability=$(
            awk \
            -v down="$DOWNTIME_SECONDS" \
            -v total="$total_runtime" \
            'BEGIN {
                printf "%.2f", ((total-down)/total)*100
            }'
        )
    fi

    echo
    echo "========== SESSION SUMMARY =========="
    echo "Jumlah pemeriksaan : $TOTAL_CHECKS"
    echo "Jumlah insiden     : $INCIDENTS"
    echo "Total downtime     : ${DOWNTIME_SECONDS} detik"
    echo "Availability       : ${availability}%"
    echo "====================================="

    if (( HAS_INCIDENT == 1 )); then
        exit 2
    fi

    exit 0
}

trap print_summary SIGINT

parse_args "$@"
validate_args

echo "Monitoring: $URL"
echo "Interval  : ${INTERVAL}s"
echo "Log file  : $LOG_FILE"

while true; do

    TIMESTAMP=$(date --iso-8601=seconds)

    CURL_RESULT=$(
        curl \
        -o /dev/null \
        -s \
        -w '%{time_total}' \
        "$URL" 2>/dev/null || echo "0"
    )

    STATUS="DOWN"

    if [[ "$CURL_RESULT" != "0" ]]; then
        STATUS="UP"
    fi

    RESPONSE_MS=$(
        awk \
        -v t="$CURL_RESULT" \
        'BEGIN {
            printf "%.0f", t*1000
        }'
    )

    printf '%s status=%s response_ms=%s\n' \
        "$TIMESTAMP" \
        "$STATUS" \
        "$RESPONSE_MS" \
        >> "$LOG_FILE"

    echo "$TIMESTAMP status=$STATUS response_ms=$RESPONSE_MS"

    (( TOTAL_CHECKS += 1 ))

    if [[ "$CURRENT_STATUS" == "UNKNOWN" ]]; then

        CURRENT_STATUS="$STATUS"

        if [[ "$STATUS" == "DOWN" ]]; then
            INCIDENT_START=$(date +%s)
            (( INCIDENTS += 1 ))
            HAS_INCIDENT=1
            echo "INSIDEN DIMULAI: $TIMESTAMP"
        fi

        sleep "$INTERVAL"
        continue
    fi

    if [[ "$CURRENT_STATUS" == "UP" && "$STATUS" == "DOWN" ]]; then

        INCIDENT_START=$(date +%s)

        (( INCIDENTS += 1 ))
        HAS_INCIDENT=1

        echo "INSIDEN DIMULAI: $TIMESTAMP"
    fi

    if [[ "$CURRENT_STATUS" == "DOWN" && "$STATUS" == "UP" ]]; then

        INCIDENT_END=$(date +%s)

        MTTR=$(( INCIDENT_END - INCIDENT_START ))

        DOWNTIME_SECONDS=$(( DOWNTIME_SECONDS + MTTR ))

        echo "LAYANAN PULIH: $TIMESTAMP"
        echo "MTTR: ${MTTR} detik"
    fi

    CURRENT_STATUS="$STATUS"

    sleep "$INTERVAL"

done
