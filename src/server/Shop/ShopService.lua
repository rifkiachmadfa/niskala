--!strict
-- ShopService: toko NPC (server = sumber kebenaran).
--
-- Tanggung jawab:
--   * Mencari Model NPC penjual yang SUDAH ADA di Workspace (tidak membuat/mengubah model).
--   * Memakai ProximityPrompt yang sudah ada di model; jika tidak ada, membuat satu
--     objek logika nonvisual "ShopPrompt" di part jangkar (pola sama dengan DEC-006).
--   * Membuka sesi toko per pemain, memvalidasi pembelian, memotong koin lewat
--     CurrencyService, dan memberi item ke Backpack lewat InventoryService. Tool di-Clone
--     dari template di ServerStorage/Tools (nama per item: GameConfig.Items.<id>.toolName).
--
-- BUKAN tanggung jawab modul ini: saldo koin (CurrencyService), efek konsumsi
-- item, penyimpanan data.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local CurrencyService = require(script.Parent.Parent.Economy.CurrencyService)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 5)
assert(sharedFolder, "[Shop] ReplicatedStorage.Shared tidak ditemukan.")
local configModule = sharedFolder:WaitForChild("GameConfig", 5)
assert(configModule, "[Shop] ReplicatedStorage.Shared.GameConfig tidak ditemukan.")
local GameConfig = require(configModule :: ModuleScript) :: any
local CFG = GameConfig.Shop

type Vendor = {
	id: string,
	config: any,
	anchor: BasePart,
	closeDistance: number,
}

type Session = {
	vendor: Vendor,
}

type BuyResult = { ok: boolean, message: string }

local ShopService = {}

local vendors: { [string]: Vendor } = {}
local sessions: { [Player]: Session } = {}
local lastBuyAt: { [Player]: number } = {}
local started = false

local openRemote: RemoteEvent
local closeRemote: RemoteEvent
local clientClosedRemote: RemoteEvent
local buyRemote: RemoteFunction

------------------------------------------------------------------------
-- Helper
------------------------------------------------------------------------

local function getRoot(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function isAlive(player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function isNear(player: Player, vendor: Vendor): boolean
	local root = getRoot(player)
	if not root or not vendor.anchor:IsDescendantOf(Workspace) then
		return false
	end
	return (root.Position - vendor.anchor.Position).Magnitude <= vendor.closeDistance
end

local function findAnchor(model: Model): BasePart?
	if model.PrimaryPart then
		return model.PrimaryPart
	end
	for _, name in { "HumanoidRootPart", "Head", "Torso", "UpperTorso" } do
		local part = model:FindFirstChild(name, true)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			return descendant
		end
	end
	return nil
end

local function endSession(player: Player, session: Session, notifyClient: boolean)
	if sessions[player] ~= session then
		return
	end
	sessions[player] = nil
	if notifyClient and player.Parent == Players then
		closeRemote:FireClient(player)
	end
end

local function monitorSession(player: Player, session: Session)
	task.spawn(function()
		while sessions[player] == session do
			task.wait(CFG.DistanceCheckInterval)
			if sessions[player] ~= session then
				return
			end
			if not isAlive(player) or not isNear(player, session.vendor) then
				endSession(player, session, true)
				return
			end
		end
	end)
end

local function buildCatalog(vendor: Vendor): { any }
	local list = {}
	for _, itemId in vendor.config.itemIds do
		local def = GameConfig.Items[itemId]
		if def then
			table.insert(list, {
				id = itemId,
				name = def.name,
				category = def.category,
				price = def.price,
				description = def.description,
			})
		else
			warn(("[Shop] Item '%s' di vendor '%s' tidak ada di GameConfig.Items"):format(itemId, vendor.id))
		end
	end
	return list
end

local function openShop(player: Player, vendor: Vendor)
	if not isAlive(player) or not isNear(player, vendor) then
		return
	end
	local existing = sessions[player]
	if existing then
		if existing.vendor == vendor then
			return -- sudah terbuka
		end
		endSession(player, existing, false)
	end

	local session: Session = { vendor = vendor }
	sessions[player] = session
	openRemote:FireClient(player, {
		vendorId = vendor.id,
		title = vendor.config.title,
		items = buildCatalog(vendor),
	})
	monitorSession(player, session)
end

------------------------------------------------------------------------
-- Item (Tool di Backpack)
------------------------------------------------------------------------

-- Template Tool item di ServerStorage (tidak pernah diubah, hanya di-Clone).
local function getToolTemplate(def: any): Tool?
	local folder = ServerStorage:FindFirstChild(CFG.ToolsFolderName)
	if not folder then
		return nil
	end
	local template = folder:FindFirstChild(def.toolName)
	if template and template:IsA("Tool") then
		return template
	end
	return nil
end

------------------------------------------------------------------------
-- Pembelian
------------------------------------------------------------------------

local function fail(message: string): BuyResult
	return { ok = false, message = message }
end

local function handleBuy(player: Player, vendorId: any, itemId: any): BuyResult
	if type(vendorId) ~= "string" or type(itemId) ~= "string" then
		return fail("Permintaan tidak valid.")
	end

	local session = sessions[player]
	if not session or session.vendor.id ~= vendorId then
		return fail("Toko tidak terbuka.")
	end
	local vendor = session.vendor
	if not isAlive(player) or not isNear(player, vendor) then
		endSession(player, session, true)
		return fail("Kamu terlalu jauh dari penjual.")
	end

	local now = os.clock()
	local last = lastBuyAt[player]
	if last and now - last < CFG.BuyCooldown then
		return fail("Pelan-pelan ya.")
	end

	if not table.find(vendor.config.itemIds, itemId) then
		return fail("Barang tidak dijual di sini.")
	end
	local def = GameConfig.Items[itemId]
	if not def then
		return fail("Barang tidak tersedia.")
	end

	local template = getToolTemplate(def)
	if not template then
		warn(("[Shop] Tool '%s' tidak ada di ServerStorage/%s. Pembelian '%s' dibatalkan."):format(
			tostring(def.toolName),
			CFG.ToolsFolderName,
			itemId
		))
		return fail("Barang sedang tidak tersedia.")
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return fail("Tas belum siap, coba lagi.")
	end
	if InventoryService.GetQuantity(player, itemId) >= CFG.MaxStack then
		return fail(("Kamu sudah membawa %s secukupnya."):format(def.name))
	end

	-- Semua pengecekan lolos; dari sini tidak ada yield sehingga pembelian atomik.
	if not CurrencyService.Spend(player, def.price) then
		return fail("Koin tidak cukup.")
	end
	lastBuyAt[player] = now

	local quantity = InventoryService.Give(player, itemId, template)
	if not quantity then
		CurrencyService.Add(player, def.price) -- kembalikan koin
		return fail("Tas belum siap, coba lagi.")
	end
	return { ok = true, message = ("Membeli %s. Kamu punya %d."):format(def.name, quantity) }
end

------------------------------------------------------------------------
-- Registrasi vendor
------------------------------------------------------------------------

local function registerVendor(vendorId: string, config: any, model: Model)
	local anchor = findAnchor(model)
	if not anchor then
		warn(("[Shop] Model '%s' tidak punya BasePart untuk jangkar."):format(config.modelName))
		return
	end

	local prompt: ProximityPrompt? = nil
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("ProximityPrompt") then
			prompt = descendant
			break
		end
	end
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ShopPrompt"
		prompt.Parent = anchor
	end
	local activePrompt = prompt :: ProximityPrompt
	activePrompt.ActionText = config.prompt.actionText
	activePrompt.ObjectText = config.displayName
	activePrompt.MaxActivationDistance = config.prompt.maxActivationDistance
	activePrompt.HoldDuration = 0
	activePrompt.RequiresLineOfSight = false

	local vendor: Vendor = {
		id = vendorId,
		config = config,
		anchor = anchor,
		closeDistance = config.prompt.maxActivationDistance + CFG.ClosePadding,
	}
	vendors[vendorId] = vendor

	activePrompt.Triggered:Connect(function(player)
		openShop(player, vendor)
	end)
	print(("[Shop] Vendor '%s' terpasang pada model '%s'."):format(vendorId, model:GetFullName()))
end

local function findVendorModel(modelName: string): Model?
	local found = Workspace:FindFirstChild(modelName, true)
	if found and found:IsA("Model") then
		return found
	end
	return nil
end

local function setupVendor(vendorId: string, config: any)
	task.spawn(function()
		local model = findVendorModel(config.modelName)
		local attempts = 0
		while not model and attempts < 10 do
			attempts += 1
			task.wait(1)
			model = findVendorModel(config.modelName)
		end
		if not model then
			warn(
				("[Shop] Model '%s' tidak ditemukan di Workspace. Periksa nama model di Explorer lalu sesuaikan GameConfig.Shop.Vendors.%s.modelName.")
					:format(config.modelName, vendorId)
			)
			return
		end
		registerVendor(vendorId, config, model)
	end)
end

------------------------------------------------------------------------
-- Start
------------------------------------------------------------------------

-- Memberi peringatan di Output jika Tool item belum ada di ServerStorage.
local function validateTools()
	local folder = ServerStorage:WaitForChild(CFG.ToolsFolderName, 10)
	if not folder then
		warn(("[Shop] Folder ServerStorage/%s tidak ditemukan. Pembelian akan ditolak."):format(CFG.ToolsFolderName))
		return
	end
	local available = {}
	for _, child in folder:GetChildren() do
		table.insert(available, child.Name .. "(" .. child.ClassName .. ")")
	end
	for _, vendor in CFG.Vendors do
		for _, itemId in vendor.itemIds do
			local def = GameConfig.Items[itemId]
			if def and not getToolTemplate(def) then
				warn(("[Shop] Tool '%s' (item %s) tidak ada/bukan Tool di ServerStorage/%s. Isi folder: %s"):format(
					tostring(def.toolName),
					itemId,
					CFG.ToolsFolderName,
					table.concat(available, ", ")
				))
			end
		end
	end
end

local function getOrCreate(parent: Instance, className: string, name: string): any
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

function ShopService.Start()
	if started then
		return
	end
	started = true

	local folder = getOrCreate(ReplicatedStorage, "Folder", "ShopRemotes")
	openRemote = getOrCreate(folder, "RemoteEvent", "Open")
	closeRemote = getOrCreate(folder, "RemoteEvent", "Close")
	clientClosedRemote = getOrCreate(folder, "RemoteEvent", "ClientClosed")
	buyRemote = getOrCreate(folder, "RemoteFunction", "Buy")

	buyRemote.OnServerInvoke = function(player: Player, vendorId: any, itemId: any)
		local ok, result = pcall(handleBuy, player, vendorId, itemId)
		if not ok then
			warn("[Shop] Error saat pembelian: " .. tostring(result))
			return fail("Terjadi kesalahan, coba lagi.")
		end
		return result
	end

	clientClosedRemote.OnServerEvent:Connect(function(player: Player)
		local session = sessions[player]
		if session then
			endSession(player, session, false)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
		lastBuyAt[player] = nil
	end)

	for vendorId, config in CFG.Vendors do
		setupVendor(vendorId, config)
	end
	task.spawn(validateTools)
end

return ShopService
