# DECISIONS

## DEC-001 — Progres per pemain, tanpa co-op
- Tanggal: 2026-10-19
- Konteks / masalah: Template bawaan multiplayer-first (shared/individual/hybrid). Project Instructions menyatakan co-op di luar scope v1.0.
- Keputusan: Model progres INDIVIDUAL. Semua state penting disimpan per pemain di server. Tidak ada state global bersama.
- Alternatif yang ditolak: Shared/hybrid (butuh co-op, di luar scope); mengasumsikan satu pemain per server (rapuh, tidak aman bila server berisi banyak pemain).
- Dampak: Objek dunia yang bersifat per-pemain (item quest, jejak kaki, gerbang) perlu strategi presentasi; ditunda sampai Workspace dipetakan (Pertanyaan Terbuka no. 6).

## DEC-002 — Hirarki sumber kebenaran
- Tanggal: 2026-10-19
- Konteks / masalah: Template menaruh Studio di atas Git di atas GDD. Project Instructions menaruh instruksi pemilik dan GDD di atas.
- Keputusan: Pakai hirarki Project Instructions (lihat `CLAUDE.md` bagian 2). Konflik repo vs Studio tetap dihentikan dan ditanyakan.
- Alternatif yang ditolak: Hirarki template.
- Dampak: Tidak ada pada kode; hanya aturan kerja.

## DEC-003 — Phase 0–9 menggantikan phase generik template
- Tanggal: 2026-10-19
- Konteks / masalah: Template memakai Foundation/Progression/Interaction/Feature. GDD memakai Phase 0–9.
- Keputusan: Ikuti Phase 0–9 GDD dengan gate Definition of Done.
- Alternatif yang ditolak: Struktur phase template.
- Dampak: `TASKS.md` dan `CURRENT_STATE.md` mengikuti penomoran GDD.

## DEC-004 — Format respons Status/Analisis/Implementasi/Pengujian/Gate
- Tanggal: 2026-10-19
- Konteks / masalah: Template memakai PLAN/CURRENT STATE/CHANGES/IMPLEMENTATION/TEST/RESULT/NEXT.
- Keputusan: Pakai format A–E dari Project Instructions. Prompt `PROMPTS.md` C3 disesuaikan.
- Alternatif yang ditolak: Format template.
- Dampak: Hanya dokumentasi.
