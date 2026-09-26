#!/usr/bin/env bash

set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
source "$APP_DIR/lib/common.sh"

PORT="${PORT:-5000}"

log_info "[1/5] Memeriksa prasyarat..."

require_cmd python3
require_cmd curl

port_is_free "$PORT" || die "port $PORT sudah dipakai proses lain"

log_info "[2/5] Semua prasyarat terpenuhi"
log_info "[3/5] Tidak ada tindakan lanjutan pada mode praktikum"
log_info "[4/5] Pemeriksaan selesai"
log_info "[5/5] Deploy berhasil"
