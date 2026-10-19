# PROMPTS — Prompt siap pakai

## C1. Sesi pertama (project baru)

```
Baca CLAUDE.md dan seluruh isi .ai/.
Jalankan PHASE 0: audit repository + inspeksi Studio (jika MCP tersedia).
Ingat: map dan aset sudah ada; jangan dibuat ulang atau digandakan.
Jangan coding dulu. Laporkan:
1. Current phase
2. Current implementation
3. Working systems
4. Broken systems
5. Missing dependencies
6. Rekomendasi langkah berikutnya
```

## C2. Sesi lanjutan (handoff)

```
Mulai sesi baru. Jangan langsung coding.
Pull repo terbaru, baca CLAUDE.md + .ai/CURRENT_STATE.md + TASKS.md + BUGS.md,
inspeksi Studio jika tersedia, lalu laporkan 8 poin handoff (phase, implementasi,
sistem yang jalan, sistem rusak, task saat ini, arsitektur penting, perubahan terbaru,
rekomendasi berikutnya). Tunggu persetujuan saya sebelum implementasi.
```

## C3. Memberi task

```
TASK: {{deskripsi singkat}}
Phase: {{nomor}}
Acceptance criteria:
- ...
Ikuti format Status → Analisis → Implementasi → Pengujian → Gate Phase.
Update .ai/ setelah selesai. Jangan commit sebelum saya setujui.
```

## C4. Melaporkan bug

```
BUG: {{gejala}}
Reproduksi: {{langkah}}
Output/error: {{paste}}
Ikuti Bug Fixing Protocol. Cari root cause, usulkan perbaikan terkecil, jangan rewrite.
```

