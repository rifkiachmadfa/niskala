--!strict
-- QuestClient: presentasi quest di sisi client. TIDAK menentukan hasil apa pun.
--   * Menyembunyikan titik kayu yang tidak aktif untuk pemain ini (hanya lokal,
--     Workspace di server tidak berubah; server tetap memvalidasi setiap pengambilan).
--   * Menampilkan notifikasi kecil (mis. "Kayu 2/6").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("QuestRemotes")
local syncRemote = remotes:WaitForChild("Sync") :: RemoteEvent
local notifyRemote = remotes:WaitForChild("Notify") :: RemoteEvent
local requestSyncRemote = remotes:WaitForChild("RequestSync") :: RemoteEvent

------------------------------------------------------------------------
-- Visibilitas titik (lokal)
------------------------------------------------------------------------

local function setPointVisible(point: Instance, visible: boolean)
	local function apply(instance: Instance)
		if instance:IsA("BasePart") then
			instance.LocalTransparencyModifier = if visible then 0 else 1
		elseif instance:IsA("ProximityPrompt") then
			instance.Enabled = visible
		end
	end
	apply(point)
	for _, descendant in point:GetDescendants() do
		apply(descendant)
	end
end

type SyncPayload = {
	hideInactive: boolean,
	points: { Instance },
	active: { Instance },
}

syncRemote.OnClientEvent:Connect(function(payload: SyncPayload)
	if type(payload) ~= "table" or not payload.hideInactive then
		return
	end
	local activeSet: { [Instance]: boolean } = {}
	for _, point in payload.active do
		activeSet[point] = true
	end
	for _, point in payload.points do
		setPointVisible(point, activeSet[point] == true)
	end
end)

------------------------------------------------------------------------
-- Notifikasi sederhana
------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "QuestNotify"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Parent = playerGui

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0.14, 0)
label.Size = UDim2.new(0, 360, 0, 40)
label.BackgroundColor3 = Color3.fromRGB(28, 32, 40)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(240, 180, 50)
label.TextTransparency = 1
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Text = ""
label.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = label

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.PaddingTop = UDim.new(0, 6)
padding.PaddingBottom = UDim.new(0, 6)
padding.Parent = label

local toastId = 0

notifyRemote.OnClientEvent:Connect(function(text: unknown)
	if type(text) ~= "string" then
		return
	end
	toastId += 1
	local myId = toastId
	label.Text = text
	label.BackgroundTransparency = 0.15
	label.TextTransparency = 0
	task.delay(3, function()
		if toastId ~= myId then
			return -- ada notifikasi yang lebih baru
		end
		local info = TweenInfo.new(0.4)
		TweenService:Create(label, info, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
	end)
end)

-- Minta status awal setelah semua listener terpasang.
requestSyncRemote:FireServer()
