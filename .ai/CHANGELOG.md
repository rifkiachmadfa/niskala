# CHANGELOG

## 2026-10-19 (b) — NPC Dialogue System + dialog Bambang
- Perubahan: Menambah sistem dialog NPC modular (server + client) dan data dialog NPC Bambang (pemandu: aturan game + arahan ke Desa).
- Sistem terdampak: baru (dialog). Tidak menyentuh aset Workspace.
- File/skrip: src/ReplicatedStorage/Shared/GameConfig.lua, src/ServerScriptService/Dialogue/{DialogueBootstrap.server,DialogueService,DialogueTypes,NPCRegistry}.lua, src/ServerScriptService/Dialogue/Data/Bambang.lua, src/StarterPlayer/StarterPlayerScripts/Dialogue/DialogueClient.client.lua
- Hasil test: sintaks seluruh file lolos `luau-compile`; logika substitusi placeholder diuji dengan Luau CLI. BELUM diuji di Roblox Studio.

## 2026-10-19
- Perubahan: Mengisi `CLAUDE.md` dan `.ai/*` dengan data game MC Cari Harta Karun di Candi; menyesuaikan `README.md`, `CHECKLIST.md`, `PROMPTS.md`.
- Sistem terdampak: dokumentasi saja. Tidak ada kode gameplay, tidak ada aset Workspace.
- File/skrip: CLAUDE.md, README.md, CHECKLIST.md, PROMPTS.md, .ai/GAME_CONTEXT.md, .ai/CURRENT_STATE.md, .ai/TASKS.md, .ai/DECISIONS.md, .ai/CHANGELOG.md
- Hasil test: tidak berlaku (dokumen). Patch diverifikasi dengan `git apply --check` pada clone bersih.

## 2026-10-19 (c) — Hunger/Thirsty berbasis durasi berjalan + HUD
- Perubahan: PlayerStats (server) menyimpan Hunger/Thirsty per pemain, mengurangi hanya saat berjalan, Thirsty lebih cepat; HP berkurang berkala jika keduanya 0; reset ke 50 setelah mati. HUD dua bar (client) membaca Attribute pemain.
- Sistem terdampak: baru (survival). `GameConfig` ditambah tabel `Survival`.
- File: src/shared/GameConfig.lua, src/server/Stats/{PlayerStats,SurvivalLogic}.lua, src/server/Stats/StatsBootstrap.server.lua, src/client/Stats/StatsHud.client.lua
- Hasil test: sintaks 5 file lolos luau-compile; logika murni (SurvivalLogic) lulus 15 tes di Luau CLI. BELUM diuji di Roblox Studio (deteksi jalan, HUD, kematian/respawn).
