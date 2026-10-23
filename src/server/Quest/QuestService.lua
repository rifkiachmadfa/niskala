--!strict
-- QuestService: pemilik tunggal STATE quest per pemain (server = sumber kebenaran).
--
-- State: NotStarted -> Active -> ReadyToTurnIn -> Completed (hanya sekali).
-- Modul ini tidak tahu apa pun tentang objek Workspace; logika spesifik quest
-- (mis. titik kayu) ada di modul terpisah yang memakai API ini.
--
-- Hadiah (Koin + Kepercayaan) hanya diberikan di TurnIn, tepat satu kali.
-- STATUS: state hanya di memori server (belum disimpan -> Phase 8). State melekat pada
-- Player, bukan karakter, jadi respawn tidak menghapus progres.
-- Cermin ke Attribute Player: "Quest_<id>_State" dan "Quest_<id>_Progress".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyService = require(script.Parent.Parent.Economy.CurrencyService)
local TrustService = require(script.Parent.Parent.Trust.TrustService)

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 5)
assert(sharedFolder, "[Quest] ReplicatedStorage.Shared tidak ditemukan.")
local configModule = sharedFolder:WaitForChild("GameConfig", 5)
assert(configModule, "[Quest] ReplicatedStorage.Shared.GameConfig tidak ditemukan.")
local GameConfig = require(configModule :: ModuleScript) :: any

export type State = "NotStarted" | "Active" | "ReadyToTurnIn" | "Completed"

type QuestData = { state: State, progress: number }
type Listener = (player: Player, questId: string, state: State, progress: number) -> ()

local QuestService = {}

local dataByPlayer: { [Player]: { [string]: QuestData } } = {}
local listeners: { Listener } = {}
local unavailable: { [string]: boolean } = {}

local function getDef(questId: string): any?
	local def = GameConfig.Quests[questId]
	if not def then
		warn(("[Quest] Quest '%s' tidak ada di GameConfig.Quests"):format(questId))
	end
	return def
end

local function getData(player: Player, questId: string): QuestData?
	local quests = dataByPlayer[player]
	if not quests then
		return nil
	end
	local data = quests[questId]
	if not data then
		data = { state = "NotStarted", progress = 0 }
		quests[questId] = data
	end
	return data
end

local function publish(player: Player, questId: string, data: QuestData)
	player:SetAttribute(("Quest_%s_State"):format(questId), data.state)
	player:SetAttribute(("Quest_%s_Progress"):format(questId), data.progress)
end

local function notify(player: Player, questId: string, data: QuestData)
	publish(player, questId, data)
	for _, listener in listeners do
		local ok, err = pcall(listener, player, questId, data.state, data.progress)
		if not ok then
			warn(("[Quest] Listener error (%s): %s"):format(questId, tostring(err)))
		end
	end
end

function QuestService.GetState(player: Player, questId: string): State
	local data = getData(player, questId)
	return if data then data.state else "NotStarted"
end

function QuestService.GetProgress(player: Player, questId: string): number
	local data = getData(player, questId)
	return if data then data.progress else 0
end

-- Dipanggil modul quest saat state/progres berubah. Listener berjalan di server.
function QuestService.Subscribe(listener: Listener)
	table.insert(listeners, listener)
end

-- Modul quest menandai quest tidak bisa dijalankan (mis. objek Workspace tidak ditemukan)
-- agar pemain tidak terjebak di quest yang mustahil diselesaikan.
function QuestService.SetAvailable(questId: string, available: boolean)
	unavailable[questId] = if available then nil else true
end

function QuestService.IsAvailable(questId: string): boolean
	return unavailable[questId] ~= true
end

-- NotStarted -> Active. Gagal jika quest sudah pernah dimulai/selesai.
function QuestService.Start(player: Player, questId: string): boolean
	if not getDef(questId) or unavailable[questId] then
		return false
	end
	local data = getData(player, questId)
	if not data or data.state ~= "NotStarted" then
		return false
	end
	data.state = "Active"
	data.progress = 0
	notify(player, questId, data)
	return true
end

-- Menambah progres quest yang sedang Active. Mengembalikan progres baru, atau nil jika ditolak.
-- Mencapai target -> state menjadi ReadyToTurnIn (hadiah BELUM diberikan).
function QuestService.AddProgress(player: Player, questId: string, amount: number): number?
	local def = getDef(questId)
	local data = getData(player, questId)
	if not def or not data or data.state ~= "Active" then
		return nil
	end
	if type(amount) ~= "number" or amount ~= amount or amount < 1 or amount ~= math.floor(amount) then
		return nil
	end
	data.progress = math.min(def.target, data.progress + amount)
	if data.progress >= def.target then
		data.state = "ReadyToTurnIn"
	end
	notify(player, questId, data)
	return data.progress
end

-- ReadyToTurnIn -> Completed + hadiah. State diubah SEBELUM hadiah diberikan agar
-- pemanggilan ganda tidak bisa memberi hadiah dua kali.
function QuestService.TurnIn(player: Player, questId: string): boolean
	local def = getDef(questId)
	local data = getData(player, questId)
	if not def or not data or data.state ~= "ReadyToTurnIn" then
		return false
	end
	data.state = "Completed"
	if not CurrencyService.Add(player, def.rewardCoins) then
		warn(("[Quest] Gagal memberi %d Koin untuk quest '%s' (%s)"):format(def.rewardCoins, questId, player.Name))
	end
	if not TrustService.Add(player, def.rewardTrust) then
		warn(("[Quest] Gagal memberi %d kepercayaan untuk quest '%s' (%s)"):format(def.rewardTrust, questId, player.Name))
	end
	notify(player, questId, data)
	return true
end

local started = false

function QuestService.Init()
	if started then
		return
	end
	started = true
	CurrencyService.Start()
	TrustService.Start()
	Players.PlayerAdded:Connect(function(player: Player)
		if not dataByPlayer[player] then
			dataByPlayer[player] = {}
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		dataByPlayer[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		if not dataByPlayer[player] then
			dataByPlayer[player] = {}
		end
	end
end

return QuestService
