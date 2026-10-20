--!strict
-- ConsumableService: makan/minum item dari Backpack (server = sumber kebenaran).
--
-- Saat pemain memegang Tool item lalu klik/tap (Tool.Activated):
--   * Efek diambil dari GameConfig.Items[<ItemId>] (field hunger / thirsty).
--   * Hunger/Thirsty ditambah lewat PlayerStats.Add (di-clamp 0..MaxStat).
--   * Jumlah di Backpack berkurang 1 lewat InventoryService (Tool hilang jika habis).
--
-- Server memvalidasi: Tool benar-benar dipegang pemain yang hidup, item dikenal,
-- jumlah >= 1, dan cooldown antar konsumsi. Tidak ada Remote (client tidak dipercaya).
-- Item yang tidak punya field hunger/thirsty diabaikan (bukan consumable).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryService = require(script.Parent.InventoryService)
local PlayerStats = require(script.Parent.Parent.Stats.PlayerStats)

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 5)
assert(sharedFolder, "[Consumable] ReplicatedStorage.Shared tidak ditemukan.")
local configModule = sharedFolder:WaitForChild("GameConfig", 5)
assert(configModule, "[Consumable] ReplicatedStorage.Shared.GameConfig tidak ditemukan.")
local GameConfig = require(configModule :: ModuleScript) :: any
local CFG = GameConfig.Consumable
local MAX_STAT: number = GameConfig.Survival.MaxStat

local ConsumableService = {}

local hooked: { [Tool]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local lastUseAt: { [Player]: number } = {}
local started = false

local function isAlive(player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function gains(amount: any): number
	if type(amount) == "number" and amount > 0 then
		return amount
	end
	return 0
end

local function onActivated(tool: Tool, itemId: string, def: any)
	-- Tool harus sedang dipegang (berada di karakter) oleh pemain yang hidup.
	local character = tool.Parent
	local player = if character then Players:GetPlayerFromCharacter(character) else nil
	if not player or not isAlive(player) then
		return
	end

	local now = os.clock()
	local last = lastUseAt[player]
	if last and now - last < CFG.Cooldown then
		return
	end

	if tool:GetAttribute("ItemId") ~= itemId or InventoryService.GetToolQuantity(tool) < 1 then
		return
	end

	local hungerGain = gains(def.hunger)
	local thirstGain = gains(def.thirsty)

	local hunger, thirst = PlayerStats.Get(player)
	if hunger == nil or thirst == nil then
		return
	end
	if CFG.BlockWhenFull then
		local useful = (hungerGain > 0 and hunger < MAX_STAT) or (thirstGain > 0 and thirst < MAX_STAT)
		if not useful then
			return -- status sudah penuh: item tidak terbuang
		end
	end

	-- Dari sini tidak ada yield: efek dan pengurangan jumlah atomik.
	if hungerGain > 0 and not PlayerStats.Add(player, "Hunger", hungerGain) then
		return
	end
	if thirstGain > 0 and not PlayerStats.Add(player, "Thirsty", thirstGain) then
		return
	end
	lastUseAt[player] = now
	InventoryService.ConsumeOne(tool)
end

local function hookTool(instance: Instance)
	if not instance:IsA("Tool") or hooked[instance] then
		return
	end
	local itemId = instance:GetAttribute("ItemId")
	if type(itemId) ~= "string" then
		return
	end
	local def = GameConfig.Items[itemId]
	if not def or (gains(def.hunger) == 0 and gains(def.thirsty) == 0) then
		return
	end

	hooked[instance] = true
	instance.Activated:Connect(function()
		local ok, err = pcall(onActivated, instance, itemId, def)
		if not ok then
			warn("[Consumable] Error saat konsumsi: " .. tostring(err))
		end
	end)
end

local function hookBackpack(backpack: Instance)
	for _, child in backpack:GetChildren() do
		hookTool(child)
	end
	backpack.ChildAdded:Connect(hookTool)
end

local function setupPlayer(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		hookBackpack(backpack)
	end
	-- Backpack dibuat ulang setiap respawn.
	player.ChildAdded:Connect(function(child)
		if child:IsA("Backpack") then
			hookBackpack(child)
		end
	end)
end

function ConsumableService.Start()
	if started then
		return
	end
	started = true

	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(function(player)
		lastUseAt[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
end

return ConsumableService
