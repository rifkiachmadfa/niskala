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

## 2026-10-19 (d) — Tuning 6:30 dan HUD kiri atas
- Perubahan: Laju Hunger 3.9 dtk/poin dan Thirsty 2.6 dtk/poin (kosong pada 6:30 / 4:20 berjalan). HUD dipindah ke kiri atas, ditambah bar HP, angka dihapus.
- File: src/shared/GameConfig.lua, src/client/Stats/StatsHud.client.lua, .ai/DECISIONS.md
- Hasil test: sintaks lolos; simulasi logika 390 dtk lulus. BELUM diuji di Studio.

## 2026-10-19 (e) — Laju 3:00/1:30, HP bar tengah bawah berwarna
- Perubahan: Hunger 1.8 dtk/poin, Thirsty 0.9 dtk/poin; opsi DrainOnlyWhileWalking; HUD Hunger/Thirsty kiri atas tanpa angka, HP bar tengah bawah (hijau/oranye<=50/merah<=25).
- File: src/shared/GameConfig.lua, src/server/Stats/PlayerStats.lua, src/client/Stats/StatsHud.client.lua, .ai/DECISIONS.md
- Hasil test: sintaks lolos, simulasi laju lulus. BELUM diuji di Studio.

## 2026-10-20 — Shop NPC Jokok (GUI) + CurrencyService dummy
- Perubahan: Shop NPC berbasis GUI. Pembelian memotong koin (dummy) dan memberi Tool ke Backpack (satu Tool per jenis, Attribute Quantity). Validasi server: sesi toko, jarak, vendor/item, harga, saldo, cooldown, batas stack.
- Sistem terdampak: baru (shop, economy). `GameConfig` ditambah `Items` dan `Shop`.
- File: src/shared/GameConfig.lua, src/server/Economy/CurrencyService.lua, src/server/Shop/{ShopService,ShopBootstrap.server}.lua, src/client/Shop/ShopClient.client.lua
- Hasil test: sintaks 5 file lolos luau-compile; logika validasi saldo lulus tes Luau CLI. BELUM diuji di Roblox Studio (model Jokok, prompt, GUI, Backpack).

## 2026-10-20 (b) — Shop memakai Tool dari ServerStorage/Tools
- Perubahan: Pembelian meng-Clone Tool template dari ServerStorage/Tools (nama per item di `GameConfig.Items.<id>.toolName`) ke Backpack, menggantikan Tool buatan runtime. Template dicek sebelum koin dipotong; peringatan Output saat startup jika Tool tidak ada.
- File: src/server/Shop/ShopService.lua, src/shared/GameConfig.lua
- Hasil test: sintaks lolos luau-compile. BELUM diuji di Roblox Studio.

## 2026-10-20 (c) — Jumlah item tampil di Backpack
- Perubahan: Nama Tool klon di Backpack menampilkan jumlah ("Ikan Goreng x2"), diperbarui setiap pembelian. Attribute `Quantity` tetap sumber kebenaran; identitas item lewat Attribute `ItemId`.
- File: src/server/Shop/ShopService.lua
- Hasil test: sintaks lolos luau-compile. BELUM diuji di Roblox Studio.
