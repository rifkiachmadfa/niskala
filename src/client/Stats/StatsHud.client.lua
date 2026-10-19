--!strict
-- StatsHud: menampilkan bar Hunger (LAPAR) dan Thirsty (HAUS).
-- Hanya presentasi: membaca Attribute "Hunger"/"Thirsty" pada LocalPlayer yang
-- diisi server (PlayerStats). Tidak menyimpan state sendiri.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig") :: ModuleScript) :: any
local MAX_STAT: number = GameConfig.Survival.MaxStat

local LOW_THRESHOLD = 20
local LOW_COLOR = Color3.fromRGB(220, 60, 60)

local function create(className: string, props: { [string]: any }, parent: Instance?): any
	local instance = Instance.new(className)
	for key, value in props do
		(instance :: any)[key] = value
	end
	instance.Parent = parent
	return instance
end

local gui = create("ScreenGui", {
	Name = "StatsHudGui",
	ResetOnSpawn = false,
	DisplayOrder = 5, -- di bawah dialog (20)
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local container = create("Frame", {
	Name = "Container",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.new(0, 230, 0, 52),
	BackgroundTransparency = 1,
}, gui)
create("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, container)

local function createBar(name: string, label: string, color: Color3, order: number)
	local row = create("Frame", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 23),
		BackgroundColor3 = Color3.fromRGB(22, 26, 32),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
	}, container)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, row)

	local fill = create("Frame", {
		Name = "Fill",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, row)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, fill)

	create("TextLabel", {
		Name = "Label",
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = label,
		ZIndex = 2,
	}, row)

	local value = create("TextLabel", {
		Name = "Value",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 0),
		Size = UDim2.new(0.4, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.5,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "",
		ZIndex = 2,
	}, row)

	return { fill = fill, value = value, color = color }
end

local bars = {
	Hunger = createBar("HungerBar", "LAPAR", Color3.fromRGB(230, 150, 40), 1),
	Thirsty = createBar("ThirstyBar", "HAUS", Color3.fromRGB(60, 150, 230), 2),
}

local function refresh(attributeName: string)
	local bar = bars[attributeName]
	local raw = localPlayer:GetAttribute(attributeName)
	local amount = if type(raw) == "number" then math.clamp(raw, 0, MAX_STAT) else MAX_STAT

	bar.value.Text = tostring(amount)
	TweenService:Create(bar.fill, TweenInfo.new(0.25), {
		Size = UDim2.new(amount / MAX_STAT, 0, 1, 0),
		BackgroundColor3 = if amount <= LOW_THRESHOLD then LOW_COLOR else bar.color,
	}):Play()
end

for attributeName in bars do
	refresh(attributeName)
	localPlayer:GetAttributeChangedSignal(attributeName):Connect(function()
		refresh(attributeName)
	end)
end
