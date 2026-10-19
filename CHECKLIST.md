# CHECKLIST ISI PLACEHOLDER

Sebelum sesi pertama, pastikan sudah terisi:

- [ ] `{{GAME_TITLE}}`, `{{GITHUB_REPO_URL}}`
- [ ] Genre, jumlah pemain, perspektif, bahasa
- [ ] Core loop (satu baris panah)
- [ ] Game state global + player state
- [ ] Model progres: shared / individual / hybrid
- [ ] Daftar item
- [ ] Spesifikasi tiap fitur/quest/level + state machine-nya
- [ ] Daftar fase (Phase 4..N) sesuai urutan dependency
- [ ] Prioritas MVP (bintang 5 → 2)
- [ ] Daftar "di luar scope"
- [ ] `default.project.json` Rojo sudah ada dan bisa sync

## Catatan adaptasi untuk tipe game lain

- **Obby / Platformer:** progres = checkpoint + stage; server validasi checkpoint & kill-brick, hindari trust posisi client.
- **Tycoon:** state utama = ekonomi (currency, upgrade); server wajib pegang semua pembelian dan DataStore.
- **Simulator:** fokus ke data (DataStore, rebirth, pets); validasi semua gain di server.
- **Combat / RPG:** tambahkan service Damage/Health/Hitbox di server, client hanya kirim intent serang.
- **Round-based (PvP / survival):** tambahkan RoundService dengan state LOBBY → INTERMISSION → ROUND → RESULT.
