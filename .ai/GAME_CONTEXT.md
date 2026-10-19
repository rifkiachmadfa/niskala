# GAME CONTEXT — MC Cari Harta Karun di Candi

Sumber: GDD KEL D ROBLLOX.docx v1.0 (Oktober 2026) + Project Instructions.
Catatan: file ini meringkas aturan yang ditulis di Project Instructions. Bila GDD asli berbeda, GDD asli menang dan file ini harus diperbaiki.

Legenda verifikasi: **[GDD]** = dari spesifikasi. **[USULAN]** = usulan teknis, belum ada di proyek. **[BELUM TERVERIFIKASI]** = butuh pengecekan Workspace/Studio.

## 1. Ringkasan
- Judul: MC Cari Harta Karun di Candi
- Genre: eksplorasi ringan, santai, quest-driven, survival ringan
- Platform: Roblox, PC dan Mobile
- Jumlah pemain: pengalaman solo; co-op di luar scope (lihat DEC-001)
- Perspektif: third person, kontrol/kamera bawaan Roblox
- Bahasa in-game: Indonesia
- Pengalaman inti: eksplorasi, kepercayaan, penemuan
- Game ini BUKAN: combat, tycoon, simulator, game kompetitif, atau game multiplayer co-op

## 2. Core Loop
Spawn di Pelabuhan → bicara NPC Pantai → ke Desa → Kepala Desa → terima & selesaikan quest → dapat Koin + Kepercayaan → Kepercayaan ≥ 70 → Gerbang Candi terbuka → Obby → Memory Game → kumpulkan 5 Relik → Altar → Ruang Harta → Peti (500 Koin) → Easter Egg: Wajah Developer.
Selama bermain: kelola Hunger/Thirsty, belanja di shop, beli kosmetik.

## 3. Pillars
1. Eksplorasi santai tanpa tekanan waktu.
2. Kepercayaan warga sebagai kunci kemajuan (bukan dibeli, bukan dibypass).
3. Penemuan: relik, rahasia, Easter Egg.

## 4. Area Dunia [BELUM TERVERIFIKASI nama objeknya]
Pelabuhan, Pantai, Desa, Sawah, Hutan, Gerbang Candi, interior Candi (lobby obby, ruang memory game, ruang relik, altar, ruang harta). Semua sudah dibangun. Nama objek aktual harus dipetakan di Phase 0.

## 5. Game State (global)
Tidak ada state global bersama. Progres bersifat per pemain (lihat bagian 6).
Alur progres per pemain: `Start → VillageAccess → QuestsInProgress → GateOpen → TempleInside → TreasureClaimed`.
Owner: `QuestService` + `TrustService` (alur sampai gerbang), `TempleService` (di dalam Candi). [USULAN]

## 6. Progression Model: INDIVIDUAL
- Per pemain: koin, inventori, kosmetik, quest, kepercayaan, status gerbang, relik, Easter Egg.
- Shared: tidak ada di v1.0.
- Konsekuensi teknis: objek dunia yang berubah (jejak kaki, item, gerbang) harus dipresentasikan per pemain bila lebih dari satu pemain berada di server. Cara paling aman belum diputuskan (lihat bagian 17, Pertanyaan Terbuka).

## 7. Status Pemain [GDD]
| Status | Maks | Perubahan |
|---|---:|---|
| HP | 100 | Regen +1 / 5 dtk jika Hunger > 60. Hunger 0 → −2 HP / 5 dtk |
| Hunger | 100 | −1 / 8 dtk |
| Thirsty | 100 | −1 / 6 dtk. Thirsty 0 → kecepatan jalan 60% |

- Koin awal: 100.
- HP habis → respawn di Pelabuhan, Hunger dan Thirsty diatur ke 50; progres quest TIDAK hilang.
- Nilai status tidak boleh melewati maksimum atau negatif; koin tidak boleh negatif.
- Jatuh dari obby hanya kembali ke checkpoint, TIDAK mengurangi HP.

## 8. Item
| Item | Harga | Efek | Catatan |
|---|---:|---|---|
| Nasi Bungkus | 15 | Hunger +40 | |
| Pisang Goreng | 8 | Hunger +20 | |
| Air Mineral | 5 | Thirsty +35 | |
| Es Kelapa Muda | 12 | Thirsty +50 | |
| Teh Manis Hangat | 8 | Thirsty +30, Hunger +10 | |
| Peta Pulau | 120 | Akses peta/minimap | Implementasi disepakati kemudian |
| Senter Kecil | 80 | Menerangi area gelap | Pakai kemampuan visual yang tersedia |
| Kamera Foto | 100 | Opsional | |
| Item Misteri | 150 | Efek lucu / referensi developer | Efek persisnya menurut GDD |
| Item quest (kayu, barang hilang, padi, bibit) | – | – | Tidak boleh dibuang atau dijual |

## 9. Kosmetik [GDD]
| Item | Slot | Harga |
|---|---|---:|
| Topi Caping | Kepala | 50 |
| Kacamata Hitam | Wajah | 60 |
| Kaos Batik | Badan | 80 |
| Syal Merah | Leher | 70 |
| Sepatu Petualang | Kaki | 90 |
| Wajah Developer | Wajah | Tidak dijual (Easter Egg) |

Aturan: kepemilikan terpisah dari status terpasang; unequip tidak menghapus kepemilikan; tidak bisa memasang yang belum dimiliki; Wajah Developer tidak boleh diberikan lewat shop/remote/reset UI. Pakai aset kosmetik yang sudah ada.

## 10. Kepercayaan Warga [GDD]
- Rentang 0–100. Bertambah HANYA saat quest selesai (bukan lewat dialog biasa).
- Ambang masuk Candi: 70. Pada 69 gerbang tertutup, pada 70 terbuka.
- Total maksimum dari 4 quest: 20 + 25 + 25 + 30 = 100.
- Dua quest maksimum = 55 (< 70), jadi minimal tiga quest diperlukan. Kombinasi tiga quest termurah (Kayu + Barang Hilang + Bertani) = 70 persis.

## 11. Quest

### State umum
`NotStarted → Active → ReadyToTurnIn → Completed`. Setiap quest punya ID, progres, target, pemberi, hadiah koin, hadiah kepercayaan. Hanya bisa selesai sekali. Satu representasi state untuk semua quest.

| Quest | Target | Pemberi/Penerima | Koin | Kepercayaan |
|---|---|---|---:|---:|
| Kayu | 6 kayu | Tukang Kayu | 80 | 20 |
| Barang Hilang | Cincin, Sendal, Gunting Kuku | (menurut GDD) | 100 | 25 |
| Bertani | 5 padi | Petani | 100 | 25 |
| Hewan Hilang | 1 hewan ditemukan | (menurut GDD) | 120 | 30 |

### Quest Kayu
- 18 titik spawn tersedia; tiap quest diterima, server memilih 6 titik BERBEDA secara acak.
- Kayu dihitung hanya saat berhasil diambil. Diserahkan ke Tukang Kayu.

### Quest Barang Hilang
- Tiga titik spawn, penempatan tiga barang diacak. Barang hanya bisa diambil saat quest Active. Ketiganya diserahkan sesuai mekanik quest.

### Quest Bertani
- Petak sawah punya state `Ripe`, `Empty`, `Planted`. Panen petak matang → padi, petak jadi `Empty`. Petak kosong bisa ditanam ulang dengan bibit. Serahkan ke Petani. Cegah panen berulang pada petak kosong dan tanam ulang yang menggandakan progres.

### Quest Hewan Hilang
- Jejak kaki hanya terlihat saat quest Active, dari Desa menuju Hutan, hilang setelah quest selesai.
- Hewan: anak kambing atau ayam, menurut aset yang tersedia [BELUM DIPUTUSKAN].
- Ditemukan lewat interaksi; penyelesaian paling sederhana (hewan mengikuti pemain atau pindah ke kandang).

Aturan umum: pakai titik spawn dan objek yang ada; jangan buat titik spawn fisik baru; pengacakan tidak boleh memilih titik sama dua kali; item tidak bisa diklaim berulang; penyerahan memvalidasi state dan jumlah; penyelesaian memicu TrustService tepat satu kali; progres tahan respawn.

## 12. Candi [GDD]
- **Lobby/Obby:** pakai platform, tangga, jembatan, checkpoint yang ada. Jatuh → checkpoint.
- **Memory Game:** papan 4×3 (12 batu relief), 6 pasang simbol: matahari, bulan, teratai, naga, gunung, ombak. Cocok → tetap terbuka. Tidak cocok → tutup setelah 1 detik. Tanpa batas waktu dan tanpa penalti. Susunan diacak saat reset. Selesai → pintu ruang berikutnya terbuka + 50 Koin (sekali).
- **5 Relik:** Arca Kecil, Kendi Emas, Koin Kuno, Daun Lontar, Permata Merah. Posisi tetap sesuai penempatan yang ada; satu relik boleh lebih tersembunyi. UI menampilkan progres. Tidak ada salinan/hadiah ganda.
- **Altar:** butuh kelima relik, menolak jika belum lengkap → membuka Ruang Harta.
- **Peti:** 500 Koin, idempoten (klaim sekali).
- **Easter Egg:** memberi Wajah Developer (kosmetik yang dimiliki), notifikasi penemuan. Lokasi/mekanik pemicu: [BELUM DIKETAHUI, tanyakan ke pemilik proyek].

## 13. Interaksi
Satu sistem ProximityPrompt + validasi server. Server memeriksa: pemain valid, jarak, state quest, state objek (AVAILABLE/IN_PROGRESS/CONSUMED), cooldown. [USULAN: tabel objek ↔ prompt diisi setelah audit Phase 0]

## 14. UI [GDD]
Status bar HP/Hunger/Thirsty, tampilan Koin, quest tracker, quest log + bar Kepercayaan Warga, dialog NPC (lanjut/lewati), shop, notifikasi quest dan Easter Egg, prompt interaksi, nama area, progres relik, kontrol PC dan mobile. Periksa UI yang ada sebelum membuat baru.

## 15. Workspace, Tag, Attribute, Remote
- Workspace: **[BELUM TERVERIFIKASI]**. Diisi setelah Phase 0 dari Explorer/Rojo/`.rbxl`. Jangan memakai nama contoh GDD sebagai fakta.
- Tag dan Attribute: **[USULAN]**, bukan fakta proyek. Contoh konvensi bila objek belum bertanda: Tag `WoodSpawn`, `LostItemSpawn`, `RicePlot`, `Relic`, `Checkpoint`; Attribute `State`, `QuestId`. Hanya dipasang setelah disetujui, atau gunakan pemetaan di config.
- Remote: kontrak diisi per fitur saat dikerjakan. Prinsip: client kirim intent, server validasi dan putuskan.

## 16. Phase dan Definition of Done

**PHASE 0 — Audit, pemetaan, perencanaan integrasi**
Tugas: audit proyek; petakan objek tiap area; identifikasi objek interaktif dan sistem lama; tentukan arsitektur dan lokasi config; catat yang belum ada; urutan implementasi.
DoD: [ ] struktur dipetakan sejauh akses [ ] objek utama teridentifikasi/dicatat belum terverifikasi [ ] sistem lama yang dipertahankan diketahui [ ] rencana integrasi tersedia [ ] tidak ada aset dunia diubah/digandakan.

**PHASE 1 — Karakter, navigasi, interaksi**
Pertahankan controller Roblox; interaksi E + sentuh; prompt kontekstual; notifikasi nama area; interaksi penting divalidasi server.
DoD: [ ] bisa bergerak di jalur dunia [ ] interaksi berfungsi di objek uji [ ] prompt tidak muncul di jarak tidak wajar [ ] nama area tampil benar [ ] tidak ada konflik kontrol/interaksi ganda [ ] aset visual utuh.

**PHASE 2 — Survival, koin, inventori, shop dasar**
PlayerStats, koin, inventori, pembelian makanan/minuman, HUD, respawn. Semua angka dari config.
DoD: [ ] Hunger/Thirsty turun sesuai config [ ] Hunger 0 kurangi HP sesuai interval [ ] Thirsty 0 perlambat dan pulih saat terisi [ ] regen HP sesuai syarat [ ] pembelian benar [ ] koin tidak negatif [ ] respawn jalan, progres quest terjaga.

**PHASE 3 — NPC, dialog, kepercayaan, gerbang**
Dialog berbasis data (sebelum quest / aktif / selesai), TrustService, GateController, pesan penolakan. Jika memakai invisible wall yang ada, pertahankan objeknya, ubah hanya state yang perlu. Cegah bypass lewat celah. Tombol debug hanya untuk uji.
DoD: [ ] dialog sesuai kondisi [ ] bisa lanjut/lewati [ ] penjaga menolak di bawah ambang [ ] 69 tutup, 70 buka [ ] state berlaku di server [ ] tidak bisa dibypass sederhana.

**PHASE 4 — Quest Kayu dan Barang Hilang**
DoD: [ ] tepat 6 dari 18 titik [ ] progres benar [ ] tiga penempatan acak [ ] item tak bisa diambil sebelum quest aktif [ ] keduanya bisa diserahkan dan selesai [ ] hadiah sesuai [ ] tanpa hadiah ganda [ ] konsisten setelah respawn.

**PHASE 5 — Quest Bertani dan Hewan Hilang**
DoD: [ ] siklus panen-tanam ulang-serah lengkap [ ] lima padi bisa dipenuhi [ ] jejak hanya muncul saat quest hewan aktif [ ] hewan ditemukan, quest selesai [ ] total maksimum 100 kepercayaan [ ] dua quest tidak membuka gerbang [ ] ambang tetap 70 [ ] progres tahan respawn.

**PHASE 6 — Candi**
DoD: [ ] obby dan checkpoint [ ] memory game selesai dan reset [ ] semua relik terkumpul [ ] altar menolak jika belum lengkap [ ] ruang harta terbuka [ ] peti sekali klaim [ ] tak bisa spam remote hadiah [ ] jatuh tidak kurangi HP.

**PHASE 7 — Shop lengkap, kosmetik, Easter Egg**
DoD: [ ] kosmetik tersedia bisa dibeli dan dipasang [ ] unequip tidak hapus kepemilikan [ ] Peta dan Senter jalan [ ] Item Misteri sesuai efek [ ] Wajah Developer hanya lewat Easter Egg [ ] kosmetik konsisten setelah respawn.

**PHASE 8 — Save, polish UI, audio**
Data: koin, inventori, kosmetik dimiliki dan terpasang, state/progres quest, kepercayaan, status gerbang, relik, Easter Egg. DataStore di server; `pcall` + logging; hindari tulis terlalu sering; simpan saat milestone dan `PlayerRemoving`/`BindToClose`; jangan timpa data valid dengan default saat gagal load; pertimbangkan versioning data.
DoD: [ ] simpan dan muat ulang [ ] gagal DataStore tidak hapus data valid [ ] tak ada duplikasi quest/hadiah saat load [ ] kosmetik, relik, Easter Egg konsisten [ ] UI tidak saling menutupi [ ] input PC dan mobile [ ] audio terpicu tepat [ ] lingkungan visual tak berubah.

**PHASE 9 — Testing, balancing, rilis**
Uji 15 langkah end-to-end (spawn → makan/minum → NPC Pantai → Desa → quest → gerbang → obby → memory → relik → altar → peti → Wajah Developer → kosmetik/item → keluar-masuk). Balancing hanya lewat config. Ide baru → backlog v1.1.
DoD: [ ] alur lengkap tanpa blocker [ ] checklist wajib teruji [ ] bug kritis dan eksploit ditangani [ ] hasil uji terdokumentasi [ ] checkpoint rilis [ ] siap publish sesuai keputusan pemilik.

Checklist wajib Phase 9: Hunger 0 kurangi HP; Thirsty 0 perlambat; konsumsi sesuai config; pembelian ditolak jika koin kurang; koin tak negatif; 6 dari 18 titik kayu tanpa duplikat; 3 barang hilang muncul saat quest aktif; jejak hanya saat quest hewan; gerbang 69 tutup / 70 buka; quest tanpa hadiah ganda; memory game selesai dan reset; 5 relik wajib; peti tak berulang; save/load; respawn tak hapus progres; remote tak bisa dieksploitasi; tak ada error runtime kritis; Workspace utuh.

## 17. Pertanyaan Terbuka (butuh jawaban pemilik proyek)
1. Struktur Workspace aktual (nama objek tiap area, NPC, titik spawn, petak sawah, gerbang, checkpoint, altar, peti).
2. Apakah Rojo dipakai? Di mana source script berada?
3. Hewan Hilang: anak kambing atau ayam?
4. Barang Hilang dan Hewan Hilang: siapa NPC pemberi/penerimanya?
5. Pemicu dan lokasi Easter Egg Wajah Developer, serta efek persis Item Misteri.
6. Jika lebih dari satu pemain berada di server: apakah objek quest (kayu, barang, jejak) cukup dibuat terlihat per pemain di sisi client, atau server dibatasi satu pemain?
7. Apakah aset kosmetik dan audio sudah ada di proyek?

## 18. Di luar scope v1.0 (JANGAN dibangun)
Multiplayer co-op, siklus siang-malam, cuaca, musim tanam sungguhan, quest tambahan, achievement, leaderboard waktu tercepat, kosmetik musiman.
