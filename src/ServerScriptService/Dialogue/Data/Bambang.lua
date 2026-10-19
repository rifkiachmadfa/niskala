--!strict
-- Data dialog NPC Bambang (pemandu di Pantai).
-- Hanya DATA. Logika ada di DialogueService.
-- Placeholder {Key} diganti dari GameConfig, mis. {StartingCoins}, {TrustGateThreshold}.

local Types = require(script.Parent.Parent.DialogueTypes)

local Bambang: Types.NPCDefinition = {
	id = "Bambang",
	displayName = "Bambang",
	modelName = "Bambang",
	prompt = {
		actionText = "Bicara",
		maxActivationDistance = 10,
	},

	conversations = {
		Intro = {
			lines = {
				{ text = "Wah, ada tamu baru! Selamat datang di pulau kami. Namaku Bambang, aku yang biasa menyambut pendatang di pantai ini." },
				{ text = "Sebelum kamu jalan-jalan, aku jelaskan dulu aturan mainnya ya. Tenang, tidak ribet kok." },
				{ text = "Pertama, jaga badanmu. Ada tiga hal yang perlu kamu perhatikan: Nyawa (HP), Lapar (Hunger), dan Haus (Thirsty)." },
				{ text = "Lapar dan haus akan turun pelan-pelan seiring waktu. Kalau lapar habis, HP-mu berkurang terus. Kalau haus habis, jalanmu jadi lambat." },
				{ text = "Tenang, kamu bisa membeli makanan dan minuman di toko. Modal awalmu {StartingCoins} Koin, pakai dengan bijak ya." },
				{ text = "Kalau HP-mu habis, kamu akan bangun lagi di Pelabuhan dengan lapar dan haus yang sudah terisi lagi. Kemajuan tugasmu tidak akan hilang." },
				{ text = "Kedua, soal warga desa. Mereka belum mengenalmu, jadi belum tentu percaya. Bantulah mereka lewat berbagai tugas, nanti kamu dapat Koin dan kepercayaan warga." },
				{ text = "Ingat, kepercayaan tidak bisa dibeli dan tidak naik hanya karena ngobrol. Satu-satunya cara adalah menyelesaikan tugas dari warga." },
				{ text = "Nah, di pulau ini ada sebuah Candi tua. Katanya ada harta karun tersimpan di dalamnya. Penjaganya baru mengizinkan masuk kalau kepercayaan warga sudah mencapai {TrustGateThreshold}." },
				{ text = "Kalau mau bicara dengan seseorang atau mengambil sesuatu, dekati lalu tekan E. Di HP, ketuk tombol yang muncul di layar." },
				{ text = "Sekarang, ayo menuju Desa. Ikuti jalan dari pantai ini, nanti kamu akan bertemu Kepala Desa. Dialah yang akan memberimu tugas pertama." },
				{ text = "Semangat ya! Kalau lupa aturannya, temui aku lagi kapan saja." },
			},
			setFlags = {
				["Bambang.IntroDone"] = true,
			},
		},

		Reminder = {
			lines = {
				{ text = "Eh, kamu lagi! Jangan lupa: jaga lapar dan hausmu, bantu warga supaya mereka percaya, dan Candi baru terbuka kalau kepercayaan warga mencapai {TrustGateThreshold}." },
				{ text = "Desa ada di ujung jalan dari pantai ini. Temui Kepala Desa kalau belum. Semoga beruntung!" },
			},
		},
	},

	selectConversation = function(ctx)
		if ctx.hasFlag("Bambang.IntroDone") then
			return "Reminder"
		end
		return "Intro"
	end,
}

return Bambang
