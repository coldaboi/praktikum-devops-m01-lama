#!/usr/bin/env bash
# setup.sh - Otomasi penyiapan & verifikasi aplikasi (The First Way: Flow)

set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$APP_DIR/.venv"
PORT="${PORT:-5000}"

echo "[1/5] Memeriksa prasyarat..."

command -v python3 >/dev/null || {
    echo "GAGAL: python3 tidak ditemukan."
    exit 1
}

python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3,10) else 1)' \
    || {
        echo "GAGAL: dibutuhkan Python 3.10 atau lebih baru."
        exit 1
    }

echo "[2/5] Menyiapkan virtual environment..."

[ -d "$VENV_DIR" ] || python3 -m venv "$VENV_DIR"

# shellcheck source=/dev/null
source "$VENV_DIR/bin/activate"

echo "[3/5] Memasang dependensi terkunci..."

pip install --quiet --upgrade pip
pip install --quiet -r "$APP_DIR/requirements.txt"

echo "[4/5] Menjalankan aplikasi pada port $PORT..."

PORT="$PORT" python3 "$APP_DIR/src/app.py" &

APP_PID=$!

trap 'kill "$APP_PID" 2>/dev/null || true' EXIT

sleep 3

echo "[5/5] Melakukan smoke test..."

if curl -fsS "http://127.0.0.1:$PORT/health" >/dev/null; then
    echo "SUKSES: aplikasi berjalan dan lulus health check (PID $APP_PID)."
else
    echo "GAGAL: aplikasi tidak merespons health check."
    exit 1
fi

echo "Tekan Ctrl+C untuk menghentikan aplikasi."

wait "$APP_PID"
