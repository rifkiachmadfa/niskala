--!strict
-- Konfigurasi pusat game. Semua angka gameplay yang bisa diubah ditaruh di sini.
-- Saat ini baru berisi nilai yang dibutuhkan sistem dialog. Phase 2+ akan MENAMBAH
-- key di modul ini (jangan membuat modul config kedua).

local GameConfig = {
	-- GDD
	StartingCoins = 100,
	TrustGateThreshold = 70,

	Dialogue = {
		-- Dialog tertutup otomatis jika pemain lebih jauh dari
		-- (MaxActivationDistance prompt + padding ini) dari NPC.
		CloseDistancePadding = 8,
		DistanceCheckInterval = 0.25,
		-- Kecepatan efek mengetik (huruf per detik) di sisi client.
		TypewriterCharsPerSecond = 45,
	},
}

return GameConfig
