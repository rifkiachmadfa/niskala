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


## DEC-008 — Hunger/Thirsty berkurang berdasarkan durasi BERJALAN (menyimpang dari GDD)
- Tanggal: 2026-10-19
- Konteks / masalah: GDD v1.0 menetapkan Hunger -1/8 dtk dan Thirsty -1/6 dtk berbasis waktu. Pemilik proyek meminta pengurangan hanya saat pemain berjalan, Thirsty lebih cepat dari Hunger, dan HP berkurang cepat jika keduanya kosong.
- Keputusan: Instruksi terbaru pemilik menang (CLAUDE.md bagian 2). Angka GDD (8 dan 6 detik) dipakai sebagai "detik berjalan per poin". Deteksi jalan di server dari perpindahan horizontal HumanoidRootPart. HP berkurang saat Hunger DAN Thirsty = 0 (GDD: cukup Hunger = 0). Damage 2 HP / 2 dtk (nilai baru, bisa diubah di `GameConfig.Survival`).
- Alternatif yang ditolak: Berbasis waktu murni (sesuai GDD, bukan permintaan); membaca `Humanoid.MoveDirection` (lebih mudah dimanipulasi client).
- Dampak: GDD perlu diselaraskan oleh pemilik. Efek lambat Thirsty 0 (60%), regen HP, dan respawn di Pelabuhan BELUM dikerjakan (bagian Phase 2 lain).

## DEC-009 — Durasi kosong Hunger/Thirsty 6:30; HUD kiri atas tanpa angka
- Tanggal: 2026-10-19
- Konteks / masalah: Pemilik meminta bar kosong dalam 6 menit 30 detik dan Thirsty turun lebih signifikan dari Hunger. Permintaan tidak merinci apakah 6:30 itu waktu berjalan dan apakah kedua bar kosong bersamaan.
- Keputusan: 6:30 = detik BERJALAN (konsisten dengan DEC-008). Hunger kosong pada 390 dtk (3.9 dtk/poin), Thirsty pada 260 dtk (2.6 dtk/poin, 1.5x lebih cepat). Keadaan "keduanya kosong" (HP mulai turun) tercapai pada 6:30. Menggantikan angka 8 dan 6 dari DEC-008.
- Alternatif yang ditolak: Kedua bar kosong tepat pada 6:30 dengan laju sama (bertentangan dengan "thirst lebih cepat").
- Dampak: Angka di `GameConfig.Survival`. HUD: bar LAPAR, HAUS, HP di kiri atas tanpa nominal.

## DEC-010 — Konsep baru: bar habis 3:00 (Hunger) dan 1:30 (Thirsty); HP bar tengah bawah
- Tanggal: 2026-10-19
- Konteks / masalah: Pemilik mengubah konsep: "hunger berkurang 1 selama 3 menit, thirst 1 menit 30 detik". Frasa ini ambigu (1 poin dari 100? atau 1 bar penuh?).
- Keputusan: Dibaca sebagai 1 bar penuh habis dalam 3:00 (Hunger) dan 1:30 (Thirsty): 1.8 dan 0.9 dtk/poin. Menggantikan DEC-009. Tambah `DrainOnlyWhileWalking` (default true) agar mode berbasis waktu bisa dipilih tanpa ubah kode. HP bar tengah bawah: hijau, oranye saat HP <= 50, merah saat HP <= 25 (nilai di config).
- Alternatif yang ditolak: 1 poin per 3 menit (bar penuh habis 5 jam, tidak masuk akal untuk gameplay).
- Dampak: Menyimpang jauh dari GDD (8 dtk/6 dtk per poin); GDD perlu diselaraskan. Starvation (kedua bar 0) dimulai pada 3:00.

## DEC-011 — CurrencyService dummy (memori) sebagai pemilik tunggal koin
- Tanggal: 2026-10-20
- Keputusan: Saldo Koin di `CurrencyService` (memori, mulai dari `GameConfig.StartingCoins`), dicerminkan ke Attribute `Coins`. API Get/Add/Spend dipertahankan saat Save (Phase 8) ditambah.
- Dampak: Saldo reset saat pemain keluar. Roti Gandum dan Ikan Goreng bukan item GDD (harga placeholder); Backpack Roblox kosong saat respawn sampai InventoryService/Save ada.

## DEC-012 — Tool item di-Clone dari ServerStorage/Tools, bukan dibuat runtime
- Tanggal: 2026-10-20
- Keputusan: ShopService memakai Tool buatan pemilik sebagai template (Clone ke Backpack). Satu Tool per jenis item; jumlah di Attribute `Quantity`; `CanBeDropped` dipaksa false pada klon agar stack tidak rusak. Template tidak pernah diubah.
- Alternatif yang ditolak: Membuat Tool runtime (mengabaikan aset pemilik).
- Dampak: Nama Tool di ServerStorage harus sama persis dengan `toolName` di config. ToolTip klon ditimpa menjadi "<Nama> x<jumlah>".

## DEC-013 — Jumlah item ditampilkan lewat Tool.Name; identitas lewat Attribute ItemId
- Tanggal: 2026-10-20
- Keputusan: `Tool.Name` klon diubah menjadi "<Nama> x<jumlah>" agar jumlah terlihat di slot Backpack bawaan. Logika (cari item, konsumsi) memakai Attribute `ItemId` dan `Quantity`, bukan Name.
- Alternatif yang ditolak: UI Backpack kustom (di luar permintaan; redesign UI butuh persetujuan).
- Dampak: Script di dalam Tool yang membaca `script.Parent.Name` akan melihat nama berformat. Jika Tool punya TextureId (ikon), slot menampilkan ikon dan teks jumlah terlihat saat hover/di daftar backpack.

## DEC-014 — InventoryService pemilik inventori Tool; konsumsi lewat Tool.Activated di server
- Tanggal: 2026-10-20
- Keputusan: `InventoryService` memiliki Give/ConsumeOne/GetQuantity (Attribute `ItemId` + `Quantity`). `ShopService` dan `ConsumableService` memakainya. Konsumsi dipicu `Tool.Activated` di server tanpa Remote. Efek dari `GameConfig.Items`. `Consumable.BlockWhenFull = true`: item tidak terpakai jika status yang dituju sudah penuh.
- Alternatif yang ditolak: Remote konsumsi dari client (permukaan eksploit lebih besar); logika jumlah di dua modul (duplikasi).
- Dampak: Efek angka (+20/+15/+25) menyimpang dari GDD untuk Air Mineral (+35); GDD perlu diselaraskan. Tidak ada notifikasi saat konsumsi diblokir karena status penuh. Tool tanpa Handle/aksi klik tetap memicu Activated saat dipegang.

## DEC-015 — Klon Tool dipaksa usable; aset tidak diubah
- Tanggal: 2026-10-20
- Keputusan: Perbaikan hanya pada klon runtime (Enabled=true; RequiresHandle=false bila tanpa Handle valid) plus peringatan Output yang menunjuk masalah aset. Aset di ServerStorage tidak diubah (aturan Workspace/aset).
- Dampak: Tool tanpa Handle bisa dipakai tetapi tetap tidak tampil di tangan; itu hanya bisa diperbaiki di aset (Studio).
