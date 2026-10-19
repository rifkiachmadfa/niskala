# GAME CONTEXT — {{GAME_TITLE}}

## 1. Ringkasan
- Judul:
- Genre:
- Jumlah pemain:
- Perspektif:
- Bahasa in-game:
- Pengalaman inti (3 kata kunci):
- Game ini BUKAN:

## 2. Core Loop
(tulis alur dari awal sampai akhir)
A → B → C → ...

## 3. Pillars (maks 4)
1.
2.
3.

## 4. Game State (global)
STATE_1 → STATE_2 → ... → GAME_COMPLETE
Owner service: 

## 5. Player State
| State | Arti | Boleh interaksi? | Boleh bergerak? |
|-------|------|------------------|-----------------|

## 6. Progression Model
- Shared (party/team): 
- Individual (per player): 
- Contoh: 

## 7. Items
| Item | Asal | Dipakai untuk | Individual/Shared | Bisa diduplikasi? |
|------|------|---------------|-------------------|-------------------|

## 8. Feature / Quest / Level Specs
(satu blok per fitur)

### FITUR 01 — {{NAMA}}
- Tipe gameplay:
- State machine:
  LOCKED → ACTIVE → ... → COMPLETE
- Aturan utama:
- Spawn/randomisasi (server):
- Kondisi gagal & konsekuensi:
- Kondisi sukses & reward:
- Edge case multiplayer:

### FITUR 02 — ...

## 9. Interaksi
| Prompt | Objek | Validasi server |
|--------|-------|-----------------|

## 10. UI
- Elemen wajib:
- Posisi:
- Sumber data: server state

## 11. Workspace Structure (target)
Workspace
├── ...

## 12. Tags & Attributes
| Nama | Tipe (Tag/Attribute) | Dipakai di |
|------|----------------------|------------|

## 13. Remotes (kontrak)
| Remote | Arah | Payload | Validasi |
|--------|------|---------|----------|

## 14. Ending / Win / Lose
- Kondisi menang:
- Kondisi kalah (jika ada):
- Sekuens ending:

## 15. Di luar scope (JANGAN dibangun)
-
