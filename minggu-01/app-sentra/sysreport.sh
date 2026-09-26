#!/usr/bin/env bash
# sysreport.sh - Laporan kesehatan sistem ringkas untuk kebutuhan operasional

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME

VERSION="1.0.0"
readonly VERSION

THRESHOLD_DISK=80
FORMAT="text"

log() {
    printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" >&2
}

die() {
    log "GALAT: $*"
    exit 1
}

usage() {
cat <<USAGE
$SCRIPT_NAME v$VERSION - laporan kesehatan sistem

Penggunaan: $SCRIPT_NAME [OPSI]

  -d N    Ambang peringatan pemakaian disk dalam persen (default: 80)
  -j      Keluarkan hasil dalam format JSON
  -h      Tampilkan bantuan ini

Exit code:
  0 = sehat
  2 = melewati ambang
  1 = galat penggunaan
USAGE
}

disk_usage_pct() {
    df -P / | awk 'NR==2 { gsub("%","",$5); print $5 }'
}

mem_used_pct() {
    free | awk '/^Mem:/ { printf "%.0f", $3/$2*100 }'
}

proc_count() {
    ps -e --no-headers | wc -l
}

main() {

    while getopts ":d:jh" opt; do
        case "$opt" in
            d)
                THRESHOLD_DISK="$OPTARG"
                ;;
            j)
                FORMAT="json"
                ;;
            h)
                usage
                exit 0
                ;;
            \?)
                usage >&2
                die "opsi tidak dikenal: -$OPTARG"
                ;;
            :)
                die "opsi -$OPTARG membutuhkan argumen"
                ;;
        esac
    done

    [[ "$THRESHOLD_DISK" =~ ^[0-9]+$ ]] || die "ambang disk harus berupa angka"

    local disk mem procs status

    disk="$(disk_usage_pct)"
    mem="$(mem_used_pct)"
    procs="$(proc_count)"

    status="OK"

    (( disk >= THRESHOLD_DISK )) && status="PERINGATAN"

    if [[ "$FORMAT" == "json" ]]; then
        printf '{"host":"%s","disk_pct":%s,"mem_pct":%s,"proc":%s,"status":"%s"}\n' \
            "$(hostname)" "$disk" "$mem" "$procs" "$status"
    else
        printf '%-20s : %s\n' 'Host' "$(hostname)"
        printf '%-20s : %s%%\n' 'Pemakaian disk' "$disk"
        printf '%-20s : %s%%\n' 'Pemakaian memori' "$mem"
        printf '%-20s : %s\n' 'Jumlah proses' "$procs"
        printf '%-20s : %s\n' 'Status' "$status"
    fi

    [[ "$status" == "OK" ]] || return 2
}

main "$@"
