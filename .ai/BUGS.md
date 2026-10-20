# BUGS

## Open
### BUG-001 — Judul
- Severity: Low / Medium / High / Blocker
- Sistem terdampak:
- Reproduksi:
  1.
- Expected:
- Actual:
- Investigasi / root cause:
- Status:

## Resolved
### BUG-001 — HP regen sendiri tanpa makan/minum
- Severity: Medium
- Sistem terdampak: Survival (PlayerStats)
- Root cause: script bawaan Roblox "Health" di karakter meregen ~1% MaxHealth/detik. Tidak ada kode repo yang menambah HP.
- Fix: PlayerStats menghapus script "Health" tiap karakter spawn + pagar HealthChanged yang membatalkan kenaikan HP tak resmi; regen resmi hanya lewat GameConfig.Survival.HpRegen (Hunger > 60).
- Status: kode ditulis, BELUM diuji di Studio.
