--!strict
-- Konfigurasi pusat game. Semua angka gameplay yang bisa diubah ditaruh di sini.
-- Saat ini baru berisi nilai yang dibutuhkan sistem dialog. Phase 2+ akan MENAMBAH
-- key di modul ini (jangan membuat modul config kedua).

local GameConfig = {
	-- GDD
	StartingCoins = 100,
	TrustGateThreshold = 70,

	-- Survival ringan (Hunger/Thirsty). Pengurangan berjalan HANYA saat pemain
	-- bergerak (instruksi pemilik 2026-10-19; GDD asli: berbasis waktu 8 dtk / 6 dtk).
	Survival = {
		MaxStat = 100, -- GDD
		StartHunger = 100,
		StartThirsty = 100,
		RespawnHunger = 50, -- GDD: setelah HP habis, Hunger/Thirsty = 50
		RespawnThirsty = 50,

		-- Detik BERJALAN yang dibutuhkan untuk kehilangan 1 poin.
		-- Thirsty harus lebih kecil dari Hunger agar Thirsty lebih cepat turun.
		HungerWalkSecondsPerPoint = 8,
		ThirstWalkSecondsPerPoint = 6,

		-- Deteksi "sedang berjalan": kecepatan horizontal nyata (stud/detik).
		MinWalkSpeed = 2,
		-- Perpindahan lebih cepat dari ini dianggap teleport/checkpoint, tidak dihitung.
		TeleportSpeedLimit = 150,
		TickInterval = 0.5,

		-- Saat Hunger DAN Thirsty sama-sama 0: kurangi HP sebesar
		-- StarvationDamage setiap StarvationDamageInterval detik.
		StarvationDamage = 2,
		StarvationDamageInterval = 2,
	},

	Dialogue = {
		-- Dialog tertutup otomatis jika pemain lebih jauh dari
		-- (MaxActivationDistance prompt + padding ini) dari NPC.
		CloseDistancePadding = 8,
		DistanceCheckInterval = 0.25,
		-- Kecepatan efek mengetik (huruf per detik) di sisi client.
		TypewriterCharsPerSecond = 45,
		-- Lama menahan tombol pada ProximityPrompt NPC dialog (detik). 0 = langsung.
		-- Server menyeragamkan nilai ini pada prompt NPC saat registrasi.
		PromptHoldDuration = 0,
		-- Client mengunci kamera saat prompt ditekan (sebelum balasan server datang).
		-- Jika server tidak membuka dialog dalam waktu ini, kunci dilepas lagi (detik).
		OpenTimeout = 2,

		-- Kamera saat dialog (sisi client).
		Camera = {
			Distance = 5, -- jarak kamera dari wajah NPC (stud)
			Height = 0.4, -- kamera sedikit di atas titik fokus
			SideAngle = 20, -- derajat geser ke samping agar karakter tidak menutupi NPC
			TweenTime = 0.4, -- durasi kamera pindah ke NPC
			ReturnTweenTime = 0.5, -- durasi kamera kembali ke pemain
			RevealTimeoutPadding = 0.5, -- detik tambahan sebelum dialog dipaksa muncul jika tween tidak selesai
		},
	},
}

return GameConfig
