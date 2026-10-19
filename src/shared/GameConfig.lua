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

		-- Kamera saat dialog (sisi client).
		Camera = {
			Distance = 5, -- jarak kamera dari wajah NPC (stud)
			Height = 0.4, -- kamera sedikit di atas titik fokus
			SideAngle = 30, -- derajat geser ke samping agar karakter tidak menutupi NPC
			TweenTime = 0.6, -- durasi kamera pindah ke NPC
			ReturnTweenTime = 0.5, -- durasi kamera kembali ke pemain
		},
	},
}

return GameConfig
