#!/usr/bin/env bash
set -euo pipefail 
OUT="${1:-app.log}"
IPS=(10.10.0.11 10.10.0.12 10.10.0.13 172.16.4.7 192.168.5.20)
PATHS=(/ /health /api/orders /api/users /static/app.js) 
CODES=(200 200 200 200 201 301 404 404 500 502)
: > "$OUT"
for _ in $(seq 1 500); do
   ts=$(date -d "-$((RANDOM % 1440)) minutes" '+%d/%b/%Y:%H:%M:%S +0700') 
   ip=${IPS[$((RANDOM % ${#IPS[@]}))]}
   p=${PATHS[$((RANDOM % ${#PATHS[@]}))]}
   c=${CODES[$((RANDOM % ${#CODES[@]}))]} 
   ms=$((RANDOM % 1200 + 5))
   echo "$ip - - [$ts] \"GET $p HTTP/1.1\" $c $ms" >> "$OUT" 
done
echo "Dibuat: $OUT ($(wc -l < "$OUT") baris)" 
