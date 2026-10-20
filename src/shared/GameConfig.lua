--!strict
-- Konfigurasi pusat game. Semua angka gameplay yang bisa diubah ditaruh di sini.
-- Saat ini baru berisi nilai yang dibutuhkan sistem dialog. Phase 2+ akan MENAMBAH
-- key di modul ini (jangan membuat modul config kedua).

local GameConfig = {
	-- GDD
	StartingCoins = 100,
	TrustGateThreshold = 70,

	-- Survival ringan (Hunger/Thirsty). Pengurangan berjalan HANYA saat pemain
	-- bergerak (instruksi pemilik 2026-10-19; GDD asli: berbasis waktu 8 dtk / 6 dtk per poin).
	Survival = {
		MaxStat = 100, -- GDD
		StartHunger = 100,
		StartThirsty = 100,
		RespawnHunger = 50, -- GDD: setelah HP habis, Hunger/Thirsty = 50
		RespawnThirsty = 50,

		-- Detik yang dibutuhkan untuk kehilangan 1 poin (maks 100 poin).
		-- Hunger: 1.8 dtk/poin => bar penuh habis dalam 180 dtk (3 menit).
		-- Thirsty: 0.9 dtk/poin => bar penuh habis dalam 90 dtk (1 menit 30 dtk).
		HungerWalkSecondsPerPoint = 1.8,
		ThirstWalkSecondsPerPoint = 0.9,
		-- true: hanya berkurang saat pemain bergerak. false: berkurang terus (berbasis waktu).
		DrainOnlyWhileWalking = true,

		-- Deteksi "sedang berjalan": kecepatan horizontal nyata (stud/detik).
		MinWalkSpeed = 2,
		-- Perpindahan lebih cepat dari ini dianggap teleport/checkpoint, tidak dihitung.
		TeleportSpeedLimit = 150,
		TickInterval = 0.5,

		-- Saat Hunger DAN Thirsty sama-sama 0: kurangi HP sebesar
		-- StarvationDamage setiap StarvationDamageInterval detik.
		StarvationDamage = 2,
		StarvationDamageInterval = 2,

		-- Regen HP (GDD: +1 HP tiap 5 dtk jika Hunger > 60). HP TIDAK regen sendiri;
		-- regen hanya aktif saat Hunger di atas HungerAbove (pemain sudah makan).
		-- Set Enabled = false jika HP hanya boleh pulih lewat item penyembuh.
		HpRegen = {
			Enabled = true,
			HungerAbove = 60,
			Amount = 1,
			Interval = 5,
		},

		-- Warna bar HP (nilai HP absolut, MaxHealth 100): hijau > 50 > oranye > 25 > merah.
		HpOrangeAtOrBelow = 50,
		HpRedAtOrBelow = 25,
	},

	-- Shop (Phase 2 dasar). Item & harga di bawah adalah data awal untuk tes sistem.
	-- Harga/efek di bawah menurut instruksi pemilik (2026-10-20); Roti Gandum dan Ikan
	-- Goreng BUKAN item GDD, dan efek Air Mineral (+25) berbeda dari GDD (+35).
	-- hunger/thirsty = jumlah poin yang ditambah saat item dimakan/diminum.
	Items = {
		RotiGandum = {
			toolName = "RotiGandum", -- nama Tool di ServerStorage/Tools (harus sama persis)
			name = "Roti Gandum",
			category = "Makanan",
			price = 10,
			hunger = 15,
			description = "Roti gandum hangat, mengenyangkan.",
		},
		IkanGoreng = {
			toolName = "IkanGoreng", -- nama Tool di ServerStorage/Tools (harus sama persis)
			name = "Ikan Goreng",
			category = "Makanan",
			price = 15,
			hunger = 20,
			description = "Ikan segar hasil tangkapan nelayan, digoreng renyah.",
		},
		AirMineral = {
			toolName = "AirMineral", -- nama Tool di ServerStorage/Tools (harus sama persis)
			name = "Air Mineral",
			category = "Minuman",
			price = 5,
			thirsty = 25,
			description = "Air mineral botol yang menyegarkan.",
		},
	},

	Consumable = {
		Cooldown = 0.8, -- detik antar konsumsi per pemain (cegah klik beruntun)
		-- true: item tidak dipakai jika status yang dituju sudah penuh (tidak terbuang).
		BlockWhenFull = true,
	},

	Shop = {
		-- Folder di ServerStorage berisi Tool template. Tool di-Clone ke Backpack saat membeli.
		ToolsFolderName = "Tools",
		-- Jarak maksimum pemain ke NPC penjual saat membeli = MaxActivationDistance
		-- prompt + padding ini (stud). Dicek server pada setiap pembelian.
		ClosePadding = 8,
		DistanceCheckInterval = 0.25,
		BuyCooldown = 0.25, -- detik antar pembelian per pemain
		MaxStack = 20, -- maksimum jumlah satu jenis item di Backpack

		-- Penjual: key = id vendor. modelName = nama Model NPC yang SUDAH ADA di Workspace.
		Vendors = {
			Jokok = {
				modelName = "jokok",
				displayName = "Jokok",
				title = "Toko Jokok",
				prompt = { actionText = "Belanja", maxActivationDistance = 10 },
				itemIds = { "RotiGandum", "IkanGoreng", "AirMineral" },
			},
		},
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
