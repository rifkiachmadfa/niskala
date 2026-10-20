--!strict
-- ShopClient: GUI toko NPC. Hanya presentasi + mengirim permintaan beli.
-- Saldo dibaca dari Attribute "Coins" pada LocalPlayer (diisi server).
-- Server memvalidasi semuanya; client tidak pernah menentukan harga/hasil.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("ShopRemotes")
local openRemote = remotes:WaitForChild("Open") :: RemoteEvent
local closeRemote = remotes:WaitForChild("Close") :: RemoteEvent
local clientClosedRemote = remotes:WaitForChild("ClientClosed") :: RemoteEvent
local buyRemote = remotes:WaitForChild("Buy") :: RemoteFunction

local function create(className: string, props: { [string]: any }, parent: Instance?): any
	local instance = Instance.new(className)
	for key, value in props do
		(instance :: any)[key] = value
	end
	instance.Parent = parent
	return instance
end

local BG = Color3.fromRGB(28, 32, 40)
local ROW = Color3.fromRGB(40, 46, 58)
local ACCENT = Color3.fromRGB(240, 180, 50)
local GOOD = Color3.fromRGB(110, 200, 120)
local BAD = Color3.fromRGB(230, 90, 90)

local gui = create("ScreenGui", {
	Name = "ShopGui",
	ResetOnSpawn = false,
	DisplayOrder = 15, -- di atas HUD (5), di bawah dialog (20)
	Enabled = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local panel = create("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.85, 0.75),
	BackgroundColor3 = BG,
	BorderSizePixel = 0,
}, gui)
create("UICorner", { CornerRadius = UDim.new(0, 12) }, panel)
create("UISizeConstraint", { MaxSize = Vector2.new(460, 420), MinSize = Vector2.new(260, 240) }, panel)
create("UIStroke", { Color = ACCENT, Thickness = 2, Transparency = 0.4 }, panel)

local title = create("TextLabel", {
	Name = "Title",
	Position = UDim2.new(0, 14, 0, 8),
	Size = UDim2.new(1, -60, 0, 28),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	TextColor3 = Color3.new(1, 1, 1),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Toko",
}, panel)

local closeButton = create("TextButton", {
	Name = "Close",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -10, 0, 8),
	Size = UDim2.fromOffset(34, 34),
	BackgroundColor3 = BAD,
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	TextColor3 = Color3.new(1, 1, 1),
	Text = "X",
	AutoButtonColor = true,
}, panel)
create("UICorner", { CornerRadius = UDim.new(0, 8) }, closeButton)

local coinsLabel = create("TextLabel", {
	Name = "Coins",
	Position = UDim2.new(0, 14, 0, 38),
	Size = UDim2.new(1, -28, 0, 22),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamMedium,
	TextSize = 15,
	TextColor3 = ACCENT,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Koin: 0",
}, panel)

local list = create("ScrollingFrame", {
	Name = "List",
	Position = UDim2.new(0, 10, 0, 66),
	Size = UDim2.new(1, -20, 1, -106),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, panel)
create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)

local feedback = create("TextLabel", {
	Name = "Feedback",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 14, 1, -8),
	Size = UDim2.new(1, -28, 0, 24),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamMedium,
	TextSize = 14,
	TextColor3 = Color3.new(1, 1, 1),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "",
}, panel)

local currentVendorId: string? = nil
local buying = false
local feedbackToken = 0

local function refreshCoins()
	local raw = localPlayer:GetAttribute("Coins")
	coinsLabel.Text = ("Koin: %d"):format(if type(raw) == "number" then raw else 0)
end
localPlayer:GetAttributeChangedSignal("Coins"):Connect(refreshCoins)
refreshCoins()

local function showFeedback(message: string, color: Color3)
	feedbackToken += 1
	local token = feedbackToken
	feedback.Text = message
	feedback.TextColor3 = color
	task.delay(3, function()
		if feedbackToken == token then
			feedback.Text = ""
		end
	end)
end

local function clearList()
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function hideShop()
	currentVendorId = nil
	gui.Enabled = false
	clearList()
	feedback.Text = ""
end

local function buy(vendorId: string, itemId: string)
	if buying or currentVendorId ~= vendorId then
		return
	end
	buying = true
	task.spawn(function()
		local ok, result = pcall(function()
			return buyRemote:InvokeServer(vendorId, itemId)
		end)
		buying = false
		if not gui.Enabled then
			return
		end
		if ok and type(result) == "table" then
			showFeedback(tostring(result.message), if result.ok then GOOD else BAD)
		else
			showFeedback("Gagal menghubungi toko.", BAD)
		end
	end)
end

local function addRow(vendorId: string, item: any, order: number)
	local row = create("Frame", {
		Name = "Row_" .. tostring(item.id),
		LayoutOrder = order,
		Size = UDim2.new(1, -6, 0, 62),
		BackgroundColor3 = ROW,
		BorderSizePixel = 0,
	}, list)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, row)

	create("TextLabel", {
		Position = UDim2.new(0, 10, 0, 6),
		Size = UDim2.new(1, -110, 0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = ("%s  [%s]"):format(tostring(item.name), tostring(item.category)),
	}, row)
	create("TextLabel", {
		Position = UDim2.new(0, 10, 0, 28),
		Size = UDim2.new(1, -110, 0, 28),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(190, 195, 205),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Text = tostring(item.description),
	}, row)

	local button = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(84, 40),
		BackgroundColor3 = ACCENT,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(30, 30, 30),
		Text = ("Beli\n%d Koin"):format(item.price),
	}, row)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, button)

	button.Activated:Connect(function()
		buy(vendorId, tostring(item.id))
	end)
end

openRemote.OnClientEvent:Connect(function(payload: any)
	if type(payload) ~= "table" or type(payload.items) ~= "table" then
		return
	end
	clearList()
	currentVendorId = tostring(payload.vendorId)
	title.Text = tostring(payload.title)
	for index, item in payload.items do
		addRow(currentVendorId :: string, item, index)
	end
	refreshCoins()
	feedback.Text = ""
	gui.Enabled = true
end)

closeRemote.OnClientEvent:Connect(hideShop)

closeButton.Activated:Connect(function()
	if currentVendorId then
		hideShop()
		clientClosedRemote:FireServer()
	end
end)
