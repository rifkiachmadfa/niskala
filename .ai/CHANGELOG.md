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
