#!/usr/bin/env bash

LOG_FILE="${LOG_FILE:-/tmp/sentra-deploy.log}"

_ts() {
    date '+%Y-%m-%dT%H:%M:%S%z'
}

log_info() {
    printf '%s [INFO ] %s\n' "$(_ts)" "$*" | tee -a "$LOG_FILE" >&2
}

log_warn() {
    printf '%s [WARN ] %s\n' "$(_ts)" "$*" | tee -a "$LOG_FILE" >&2
}

log_error() {
    printf '%s [ERROR] %s\n' "$(_ts)" "$*" | tee -a "$LOG_FILE" >&2
}

die() {
    log_error "$*"
    exit 1
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "perkakas wajib tidak ditemukan: $1"
}

port_is_free() {
    ! ss -ltn "sport = :$1" 2>/dev/null | grep -q LISTEN
}
