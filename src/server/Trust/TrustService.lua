--!strict
-- TrustService: pemilik tunggal Kepercayaan Warga per pemain (0-100). Server = sumber kebenaran.
--
-- Kepercayaan HANYA bertambah lewat penyelesaian quest (QuestService.TurnIn memanggil Add).
-- STATUS: nilai hanya di memori server (belum disimpan -> Phase 8). Belum terhubung ke
-- Gerbang Candi (itu tugas terpisah di Phase 3).
-- Nilai dicerminkan ke Attribute Player "Trust" agar UI bisa membaca tanpa Remote.

local Players = game:GetService("Players")

local MAX_TRUST = 100 -- GDD: rentang 0-100

local TrustService = {}

local trustByPlayer: { [Player]: number } = {}
local started = false

local function publish(player: Player)
	player:SetAttribute("Trust", trustByPlayer[player])
end

local function addPlayer(player: Player)
	if trustByPlayer[player] ~= nil then
		return
	end
	trustByPlayer[player] = 0
	publish(player)
end

function TrustService.Get(player: Player): number?
	return trustByPlayer[player]
end

-- Menambah kepercayaan (bilangan bulat positif). Hasil dijepit ke 0..100.
function TrustService.Add(player: Player, amount: number): boolean
	local current = trustByPlayer[player]
	if current == nil or type(amount) ~= "number" or amount ~= amount or amount <= 0 or amount ~= math.floor(amount) then
		return false
	end
	trustByPlayer[player] = math.min(MAX_TRUST, current + amount)
	publish(player)
	return true
end

function TrustService.Start()
	if started then
		return
	end
	started = true
	Players.PlayerAdded:Connect(addPlayer)
	Players.PlayerRemoving:Connect(function(player: Player)
		trustByPlayer[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		addPlayer(player)
	end
end

return TrustService
