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

## DEC-005 — Source script ditaruh di `src/` bergaya Rojo, tanpa `default.project.json`
- Tanggal: 2026-10-19
- Konteks / masalah: Repo tidak punya Rojo; Pertanyaan Terbuka no. 2 belum dijawab. Script perlu tempat di repo agar bisa di-review.
- Keputusan: Taruh di `src/<Service>/...` dengan penamaan Rojo (`.server.lua`, `.client.lua`, `.lua`). Tidak menambah `default.project.json`; script disalin manual ke Studio sesuai hierarki di CURRENT_STATE.
- Alternatif yang ditolak: Menambah mapping Rojo tanpa persetujuan (CLAUDE.md bagian 5).
- Dampak: Jika pemilik memilih Rojo, mapping bisa ditambah tanpa mengubah isi file.

## DEC-006 — ProximityPrompt NPC dibuat runtime hanya jika model belum punya
- Tanggal: 2026-10-19
- Konteks / masalah: Model Bambang sudah ada; belum diketahui apakah punya ProximityPrompt.
- Keputusan: DialogueService memakai ProximityPrompt yang sudah ada di model; jika tidak ada, membuat satu objek logika nonvisual "DialoguePrompt" saat runtime di part jangkar model. Model tidak diubah di file.
- Alternatif yang ditolak: Menambah prompt manual di Studio (tidak terdokumentasi di repo).
- Dampak: Jika model punya prompt lain untuk fungsi berbeda, dialog akan ikut terpicu; perlu dicek saat uji.

## DEC-007 — Flag dialog sementara di memori; GameConfig dibuat minimal
- Tanggal: 2026-10-19
- Konteks / masalah: SaveService (Phase 8) dan config Phase 2 belum ada.
- Keputusan: Flag dialog (mis. `Bambang.IntroDone`) disimpan di memori server per pemain dan hilang saat keluar. `GameConfig` hanya berisi key yang dipakai dialog; Phase 2+ menambah key ke modul yang sama.
- Alternatif yang ditolak: DataStore sekarang (di luar scope tugas); modul config terpisah (risiko dua sumber kebenaran).
- Dampak: Dialog intro Bambang diulang setiap pemain bergabung ulang sampai Phase 8.

