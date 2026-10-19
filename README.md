# Roblox AI Starter Kit

Template reusable untuk project Roblox dengan AI (Claude Code / Studio MCP / Rojo).

## Isi
- `CLAUDE.md`  : master prompt (isi semua {{PLACEHOLDER}}). Salin/biarkan di root repo. Bisa di-copy juga sebagai `AGENTS.md`.
- `.ai/`       : project memory (GAME_CONTEXT, CURRENT_STATE, TASKS, BUGS, DECISIONS, CHANGELOG)
- `PROMPTS.md` : prompt pembuka sesi, handoff, task, bug
- `CHECKLIST.md` : checklist placeholder + catatan adaptasi tipe game

## Cara pakai
1. Buat repo Git baru + setup Rojo (`default.project.json`).
2. Salin `CLAUDE.md` dan folder `.ai/` ke root repo.
3. Isi placeholder di `CLAUDE.md` dan lengkapi `.ai/GAME_CONTEXT.md`.
4. Mulai sesi AI dengan prompt C1 di `PROMPTS.md` (audit Phase 0, jangan coding dulu).
