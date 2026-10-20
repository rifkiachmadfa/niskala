--!strict
-- InventoryService: pemilik tunggal inventori item berbasis Tool di Backpack.
--
-- Satu Tool per jenis item. Sumber kebenaran:
--   * Attribute "ItemId"   : identitas item (kunci di GameConfig.Items).
--   * Attribute "Quantity" : jumlah yang dimiliki.
-- Tool.Name/ToolTip hanya label tampilan ("Ikan Goreng x2"); JANGAN dibaca sebagai data.
--
-- Dipakai oleh ShopService (menambah item) dan ConsumableService (mengurangi item).
-- STATUS: belum ada penyimpanan (Backpack hilang saat respawn/keluar -> Phase 8).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 5)
assert(sharedFolder, "[Inventory] ReplicatedStorage.Shared tidak ditemukan.")
local configModule = sharedFolder:WaitForChild("GameConfig", 5)
assert(configModule, "[Inventory] ReplicatedStorage.Shared.GameConfig tidak ditemukan.")
local GameConfig = require(configModule :: ModuleScript) :: any

local InventoryService = {}

local function setQuantity(tool: Tool, itemId: string, quantity: number)
	local def = GameConfig.Items[itemId]
	local displayName: string = if def then def.name else itemId
	tool:SetAttribute("Quantity", quantity)
	local label = ("%s x%d"):format(displayName, quantity)
	tool.Name = label
	tool.ToolTip = label
end

-- Tool item milik pemain (di Backpack atau sedang dipegang), atau nil.
function InventoryService.FindTool(player: Player, itemId: string): Tool?
	local containers: { Instance? } = { player:FindFirstChildOfClass("Backpack"), player.Character }
	for _, container in containers do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute("ItemId") == itemId then
					return child
				end
			end
		end
	end
	return nil
end

-- Jumlah dari satu Tool item (0 jika bukan Tool item yang valid).
function InventoryService.GetToolQuantity(tool: Tool): number
	local quantity = tool:GetAttribute("Quantity")
	if type(quantity) == "number" and quantity >= 1 then
		return math.floor(quantity)
	end
	return 0
end

function InventoryService.GetQuantity(player: Player, itemId: string): number
	local tool = InventoryService.FindTool(player, itemId)
	return if tool then InventoryService.GetToolQuantity(tool) else 0
end

local function getHandle(tool: Tool): BasePart?
	local handle = tool:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then
		return handle
	end
	return nil
end

-- Memeriksa template Tool dan mengembalikan daftar masalah (kosong = aman).
-- Hanya MEMBACA; template di ServerStorage tidak pernah diubah.
function InventoryService.Inspect(tool: Tool): { string }
	local problems = {}

	local raw = tool:FindFirstChild("Handle")
	if not raw then
		local parts = {}
		for _, child in tool:GetChildren() do
			if child:IsA("BasePart") then
				table.insert(parts, child.Name)
			end
		end
		table.insert(
			problems,
			("tidak punya child bernama 'Handle'. Part langsung di dalam Tool: %s"):format(
				if #parts > 0 then table.concat(parts, ", ") else "(tidak ada)"
			)
		)
	elseif not raw:IsA("BasePart") then
		table.insert(problems, ("'Handle' berjenis %s, harus Part/MeshPart (BasePart)"):format(raw.ClassName))
	else
		if raw.Transparency >= 1 then
			table.insert(problems, "Handle Transparency = 1 (tidak terlihat)")
		end
		if raw.Size.Magnitude < 0.2 then
			table.insert(problems, "ukuran Handle sangat kecil")
		end
	end

	if not tool.Enabled then
		table.insert(problems, "properti Enabled = false (tool tidak bisa dipakai/diklik)")
	end
	return problems
end

-- Hanya pada KLON runtime (bukan aset): pastikan Tool bisa dipegang dan diaktifkan.
--   * Tanpa Handle valid, RequiresHandle = true membuat Tool tidak bisa di-equip sama
--     sekali, sehingga Activated tidak pernah terpicu. Dipaksa false agar tetap bisa dipakai
--     (tampilan di tangan tetap butuh Handle yang benar di aset; lihat peringatan di Output).
--   * Enabled = false membuat Activated tidak terpicu; consumable harus Enabled.
local function ensureUsable(tool: Tool)
	if tool.RequiresHandle and not getHandle(tool) then
		tool.RequiresHandle = false
	end
	tool.Enabled = true
end

-- Menambah satu item. template = Tool di ServerStorage (hanya di-Clone, tidak diubah).
-- Mengembalikan jumlah baru, atau nil jika item/Backpack tidak valid.
function InventoryService.Give(player: Player, itemId: string, template: Tool): number?
	if not GameConfig.Items[itemId] then
		return nil
	end

	local existing = InventoryService.FindTool(player, itemId)
	if existing then
		local quantity = math.max(InventoryService.GetToolQuantity(existing), 1) + 1
		setQuantity(existing, itemId, quantity)
		return quantity
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return nil
	end
	local tool = template:Clone()
	tool.CanBeDropped = false -- jumlah ada di Attribute; tool yang dibuang akan merusak stack
	ensureUsable(tool)
	tool:SetAttribute("ItemId", itemId)
	setQuantity(tool, itemId, 1)
	tool.Parent = backpack
	return 1
end

-- Mengurangi satu item dari Tool ini. Tool dihapus bila habis.
-- Mengembalikan sisa jumlah, atau nil jika Tool tidak valid.
function InventoryService.ConsumeOne(tool: Tool): number?
	local itemId = tool:GetAttribute("ItemId")
	if type(itemId) ~= "string" then
		return nil
	end
	local quantity = InventoryService.GetToolQuantity(tool)
	if quantity < 1 then
		return nil
	end

	local remaining = quantity - 1
	if remaining <= 0 then
		tool:SetAttribute("Quantity", 0)
		tool:Destroy()
	else
		setQuantity(tool, itemId, remaining)
	end
	return remaining
end

return InventoryService
