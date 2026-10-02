# Sentra Digital Batam - Layanan Contoh Devops

Artefak praktikum mata kuliah DevOps, Politeknik Negeri Batam.

## Prasyarat
- Linux atau WSL2, Python 3.10 ke atas, Bash 5

## Menjalankan
```bash
./setup.sh
```

## Skrip yang tersedia
|     Berkas    |                           Fungsi                             |
|---------------|--------------------------------------------------------------|
|   setup.sh    | Menyiapkan venv, memasang dependensi, menjalankan smoke test |
| lib/common.sh | Fungsi logging dan validasi bersama                          ||
| sysreport.sh  | Laporan kesehatan sistem (exit 0 sehat, 2 melewati ambang)   |
