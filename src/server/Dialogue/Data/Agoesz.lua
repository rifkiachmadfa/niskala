--!strict
-- Data dialog NPC Agoesz (pemberi quest di Desa).
-- Hanya DATA + pemanggilan QuestService; logika quest ada di QuestService/WoodQuest.
-- Quest Padi dan Quest Bantu Warga menyusul sebagai tugas terpisah.

local Types = require(script.Parent.Parent.DialogueTypes)
local QuestService = require(script.Parent.Parent.Parent.Quest.QuestService)

local WOOD = "Wood"

local Agoesz: Types.NPCDefinition = {
	id = "Agoesz",
	displayName = "Agoesz",
	modelName = "Agoesz",
	focusPartName = "Head",
	prompt = {
		actionText = "Bicara",
		maxActivationDistance = 10,
	},

	conversations = {
		WoodOffer = {
			lines = {
				{ text = "Oh, pendatang baru ya? Aku Agoesz. Kebetulan sekali, aku sedang butuh bantuan." },
				{ text = "Desa kami kekurangan kayu. Bisa tolong carikan {Quests.Wood.target} potong kayu di hutan?" },
				{ text = "Kayunya tersebar di beberapa tempat di hutan, jadi cari baik-baik. Dekati lalu tekan E untuk mengambilnya." },
				{ text = "Kalau sudah terkumpul semua, antarkan ke aku di sini. Aku beri {Quests.Wood.rewardCoins} Koin, dan warga akan lebih percaya padamu." },
			},
			onFinish = function(ctx)
				QuestService.Start(ctx.player, WOOD)
			end,
		},

		WoodActive = {
			lines = {
				{ text = "Kayunya belum cukup, ya? Aku butuh {Quests.Wood.target} potong. Cari di sekitar hutan, tekan E untuk mengambilnya." },
			},
		},

		WoodTurnIn = {
			lines = {
				{ text = "Wah, kayunya sudah terkumpul semua! Terima kasih banyak, ini sangat membantu desa." },
				{ text = "Ini upahmu: {Quests.Wood.rewardCoins} Koin. Warga juga mulai mempercayaimu." },
			},
			onFinish = function(ctx)
				QuestService.TurnIn(ctx.player, WOOD)
			end,
		},

		Unavailable = {
			lines = {
				{ text = "Halo! Hari ini aku belum butuh bantuan apa-apa. Mampir lagi nanti ya." },
			},
		},

		AfterWood = {
			lines = {
				{ text = "Terima kasih lagi untuk kayunya! Kalau ada tugas lain, nanti kukabari." },
			},
		},
	},

	selectConversation = function(ctx)
		local state = QuestService.GetState(ctx.player, WOOD)
		if state == "Active" then
			return "WoodActive"
		elseif state == "ReadyToTurnIn" then
			return "WoodTurnIn"
		elseif state == "Completed" then
			return "AfterWood"
		end
		if not QuestService.IsAvailable(WOOD) then
			return "Unavailable"
		end
		return "WoodOffer"
	end,
}

return Agoesz
