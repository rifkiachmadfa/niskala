# CURRENT STATE

Last updated: 2026-10-19
Current phase: PHASE 0 (Audit), belum lulus gate
Branch: main

## Working systems
- (none) Repo belum berisi kode game.

## Incomplete systems
- Dialog NPC (sebagian Phase 3): `src/ServerScriptService/Dialogue/*`, `src/StarterPlayer/StarterPlayerScripts/Dialogue/DialogueClient.client.lua`, `src/ReplicatedStorage/Shared/GameConfig.lua`. Status: kode ditulis, sintaks lolos, BELUM diuji di Studio. Belum ada: TrustService, GateController, Kepala Desa, flag dialog belum disimpan (Phase 8).
  - Struktur Studio: ReplicatedStorage/Shared/GameConfig; ServerScriptService/Dialogue/{DialogueBootstrap (Script), DialogueService, DialogueTypes, NPCRegistry, Data/Bambang}; StarterPlayer/StarterPlayerScripts/Dialogue/DialogueClient (LocalScript). Remote dibuat runtime: ReplicatedStorage/DialogueRemotes/{Open,Close,Finish}.
  - Tambah NPC baru: buat `Data/<NPC>` mengikuti `Data/Bambang`, lalu daftarkan di `NPCRegistry`.
- Semua sistem gameplay belum dimulai.
- Placeholder template (`CLAUDE.md`, `.ai/*`) sudah diisi dengan data game (perubahan belum di-commit).

## Known bugs
- lihat BUGS.md

## Current task
- Phase 0: mendapatkan struktur Workspace dan GDD asli untuk melengkapi peta integrasi.

## Next task
- Setelah Workspace dipetakan dan Phase 0 lulus → PHASE 1 (karakter, navigasi, interaksi).

## Dependencies / blockers
- BLOCKER: struktur Workspace aktual tidak tersedia (tidak ada `.rbxl`/Rojo di repo).
- BLOCKER: `default.project.json` belum ada, sehingga belum jelas script dikelola di mana.
- GDD asli (`GDD KEL D ROBLLOX.docx`) belum ada di repo.
- Pertanyaan terbuka: lihat `GAME_CONTEXT.md` bagian 17.

## Peta integrasi (diisi saat audit)
| Komponen | Status |
|---|---|
| Workspace | Belum terverifikasi |
| Script/Modul | Belum ada |
| Remote | Belum ada |
| UI | Belum terverifikasi |
| Data/Save | Belum ada |

## Update 2026-10-20
- Shop Jokok: kode ditulis (src/server/Shop, src/server/Economy, src/client/Shop), sintaks lolos, BELUM diuji di Studio. Butuh: Model NPC bernama sesuai `GameConfig.Shop.Vendors.Jokok.modelName` ("Jokok", belum diverifikasi).
- Catatan: info "BLOCKER default.project.json belum ada" di atas sudah usang; file kini ada (src/server -> ServerScriptService.Server, src/client -> StarterPlayerScripts.Client, src/shared -> ReplicatedStorage.Shared).
