--!strict
-- StatsHud: HUD survival (hanya presentasi).
--   * Bar LAPAR dan HAUS di kiri atas, tanpa angka. Nilai dibaca dari Attribute
--     "Hunger"/"Thirsty" pada LocalPlayer (diisi server oleh PlayerStats).
--   * Bar HP di tengah bawah layar (di antara analog dan tombol lompat pada mobile).
--     Hijau; oranye saat HP <= HpOrangeAtOrBelow; merah saat HP <= HpRedAtOrBelow.
--     Nilai dibaca dari Humanoid karakter saat ini.
-- Tidak menyimpan state sendiri.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig") :: ModuleScript) :: any
local SURVIVAL = GameConfig.Survival
local MAX_STAT: number = SURVIVAL.MaxStat

local COLOR_PANEL = Color3.fromRGB(22, 26, 32)
local COLOR_GREEN = Color3.fromRGB(80, 190, 90)
local COLOR_ORANGE = Color3.fromRGB(240, 150, 40)
local COLOR_RED = Color3.fromRGB(220, 60, 60)
local LOW_FRACTION = 0.2 -- Hunger/Thirsty menjadi merah di bawah 20%

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

-- Satu bar: panel gelap + isi yang dianimasikan. Tanpa angka.
local function createBar(name: string, label: string, color: Color3, size: UDim2, parent: Instance): any
	local row = create("Frame", {
		Name = name,
		Size = size,
		BackgroundColor3 = COLOR_PANEL,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
	}, parent)
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
		Size = UDim2.new(1, -16, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = label,
		ZIndex = 2,
	}, row)

	return { row = row, fill = fill, color = color }
end

local function setBar(bar: any, fraction: number, color: Color3)
	TweenService:Create(bar.fill, TweenInfo.new(0.25), {
		Size = UDim2.new(math.clamp(fraction, 0, 1), 0, 1, 0),
		BackgroundColor3 = color,
	}):Play()
end

------------------------------------------------------------------------
-- LAPAR dan HAUS: kiri atas
------------------------------------------------------------------------

local topLeft = create("Frame", {
	Name = "TopLeft",
	Position = UDim2.new(0, 12, 0, 12), -- geser di sini jika bertabrakan dengan UI lain
	Size = UDim2.new(0, 200, 0, 52),
	BackgroundTransparency = 1,
}, gui)
create("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, topLeft)

local bars = {
	Hunger = createBar("HungerBar", "LAPAR", Color3.fromRGB(230, 150, 40), UDim2.new(1, 0, 0, 23), topLeft),
	Thirsty = createBar("ThirstyBar", "HAUS", Color3.fromRGB(60, 150, 230), UDim2.new(1, 0, 0, 23), topLeft),
}
bars.Hunger.row.LayoutOrder = 1
bars.Thirsty.row.LayoutOrder = 2

local function refreshStat(attributeName: string)
	local bar = bars[attributeName]
	local raw = localPlayer:GetAttribute(attributeName)
	local amount = if type(raw) == "number" then raw else MAX_STAT
	local fraction = amount / MAX_STAT
	setBar(bar, fraction, if fraction <= LOW_FRACTION then COLOR_RED else bar.color)
end

for attributeName in bars do
	refreshStat(attributeName)
	localPlayer:GetAttributeChangedSignal(attributeName):Connect(function()
		refreshStat(attributeName)
	end)
end

------------------------------------------------------------------------
-- HP: tengah bawah (antara analog kiri dan tombol lompat kanan pada mobile)
------------------------------------------------------------------------

local hpHolder = create("Frame", {
	Name = "HpHolder",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -16),
	Size = UDim2.new(0.28, 0, 0, 22),
	BackgroundTransparency = 1,
}, gui)
create("UISizeConstraint", { MinSize = Vector2.new(120, 22), MaxSize = Vector2.new(260, 22) }, hpHolder)

local hpBar = createBar("HpBar", "HP", COLOR_GREEN, UDim2.new(1, 0, 1, 0), hpHolder)

local function hpColor(health: number): Color3
	if health <= SURVIVAL.HpRedAtOrBelow then
		return COLOR_RED
	elseif health <= SURVIVAL.HpOrangeAtOrBelow then
		return COLOR_ORANGE
	end
	return COLOR_GREEN
end

local humanoidConns: { RBXScriptConnection } = {}

local function bindHumanoid(character: Model)
	for _, conn in humanoidConns do
		conn:Disconnect()
	end
	table.clear(humanoidConns)

	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end
	local function update()
		setBar(hpBar, humanoid.Health / math.max(humanoid.MaxHealth, 1), hpColor(humanoid.Health))
	end
	update()
	table.insert(humanoidConns, humanoid.HealthChanged:Connect(update))
	table.insert(humanoidConns, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update))
end

localPlayer.CharacterAdded:Connect(bindHumanoid)
if localPlayer.Character then
	task.spawn(bindHumanoid, localPlayer.Character)
end
