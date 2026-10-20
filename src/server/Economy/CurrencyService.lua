--!strict
-- CurrencyService: pemilik tunggal saldo Koin per pemain (server = sumber kebenaran).
--
-- STATUS: DUMMY untuk tes Shop. Saldo hanya di memori server (hilang saat keluar,
-- belum ada DataStore -> Phase 8). API publik sengaja sama dengan versi final
-- (Get/Add/Spend) supaya Shop/Quest tidak perlu diubah saat save ditambahkan.
--
-- Saldo dicerminkan ke Attribute Player "Coins" agar UI client bisa membaca tanpa
-- Remote. Client tidak bisa mengubah saldo server lewat Attribute.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 5)
assert(sharedFolder, "[Currency] ReplicatedStorage.Shared tidak ditemukan.")
local configModule = sharedFolder:WaitForChild("GameConfig", 5)
assert(configModule, "[Currency] ReplicatedStorage.Shared.GameConfig tidak ditemukan.")
local GameConfig = require(configModule :: ModuleScript) :: any

local CurrencyService = {}

local coinsByPlayer: { [Player]: number } = {}
local started = false

local function isValidAmount(amount: any): boolean
	return type(amount) == "number"
		and amount == amount
		and amount > 0
		and amount < 1e9
		and amount == math.floor(amount)
end

local function publish(player: Player)
	player:SetAttribute("Coins", coinsByPlayer[player])
end

local function addPlayer(player: Player)
	if coinsByPlayer[player] ~= nil then
		return
	end
	coinsByPlayer[player] = GameConfig.StartingCoins
	publish(player)
end

-- Saldo pemain, atau nil jika pemain tidak dikenal.
function CurrencyService.Get(player: Player): number?
	return coinsByPlayer[player]
end

-- Menambah koin. amount harus bilangan bulat positif.
function CurrencyService.Add(player: Player, amount: number): boolean
	local balance = coinsByPlayer[player]
	if balance == nil or not isValidAmount(amount) then
		return false
	end
	coinsByPlayer[player] = balance + amount
	publish(player)
	return true
end

-- Mengurangi koin. Gagal (tanpa efek) jika saldo kurang; saldo tidak pernah negatif.
function CurrencyService.Spend(player: Player, amount: number): boolean
	local balance = coinsByPlayer[player]
	if balance == nil or not isValidAmount(amount) or balance < amount then
		return false
	end
	coinsByPlayer[player] = balance - amount
	publish(player)
	return true
end

function CurrencyService.Start()
	if started then
		return
	end
	started = true
	Players.PlayerAdded:Connect(addPlayer)
	Players.PlayerRemoving:Connect(function(player)
		coinsByPlayer[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		addPlayer(player)
	end
end

return CurrencyService
