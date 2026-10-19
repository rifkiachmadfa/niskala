--!strict
-- Daftar semua NPC yang memakai sistem dialog.
-- Untuk menambah NPC baru:
--   1. Buat ModuleScript data di folder Data (salin pola Data/Bambang).
--   2. Tambahkan require-nya ke daftar di bawah.
-- Tidak perlu mengubah DialogueService atau script client.

local Types = require(script.Parent.DialogueTypes)

local registry: { Types.NPCDefinition } = {
	require(script.Parent.Data.Bambang),
}

return registry
