--!strict
-- DialogueClient: menampilkan UI dialog NPC. Hanya presentasi dan input.
-- Semua keputusan (isi dialog, validasi sesi, flag) ada di server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("DialogueRemotes")
local openEvent = remotes:WaitForChild("Open") :: RemoteEvent
local closeEvent = remotes:WaitForChild("Close") :: RemoteEvent
local finishEvent = remotes:WaitForChild("Finish") :: RemoteEvent

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig") :: ModuleScript) :: any
local CHARS_PER_SECOND: number = GameConfig.Dialogue.TypewriterCharsPerSecond
local CAMERA_CFG = GameConfig.Dialogue.Camera

local ACTION_NAME = "NPCDialogueAdvance"

type DialogueLine = { speaker: string, text: string }

------------------------------------------------------------------------
-- UI (dibuat lewat kode; tidak ada UI dialog lain yang tersedia di proyek)
------------------------------------------------------------------------

local function create(className: string, props: { [string]: any }, parent: Instance?): any
	local instance = Instance.new(className)
	for key, value in props do
		(instance :: any)[key] = value
	end
	instance.Parent = parent
	return instance
end

local gui = create("ScreenGui", {
	Name = "NPCDialogueGui",
	ResetOnSpawn = false,
	DisplayOrder = 20,
	IgnoreGuiInset = true,
	Enabled = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local panel = create("TextButton", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -16),
	Size = UDim2.new(0.92, 0, 0, 200),
	BackgroundColor3 = Color3.fromRGB(22, 26, 32),
	BackgroundTransparency = 0.08,
	AutoButtonColor = false,
	Text = "",
}, gui)
create("UISizeConstraint", { MaxSize = Vector2.new(780, 240), MinSize = Vector2.new(260, 160) }, panel)
create("UICorner", { CornerRadius = UDim.new(0, 12) }, panel)
create("UIStroke", { Color = Color3.fromRGB(255, 214, 120), Transparency = 0.5, Thickness = 1.5 }, panel)
create("UIPadding", {
	PaddingTop = UDim.new(0, 12),
	PaddingBottom = UDim.new(0, 12),
	PaddingLeft = UDim.new(0, 16),
	PaddingRight = UDim.new(0, 16),
}, panel)

local nameLabel = create("TextLabel", {
	Name = "NPCName",
	Size = UDim2.new(1, 0, 0, 26),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	TextColor3 = Color3.fromRGB(255, 214, 120),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "",
}, panel)

local textLabel = create("TextLabel", {
	Name = "DialogueText",
	Position = UDim2.new(0, 0, 0, 30),
	Size = UDim2.new(1, 0, 1, -80),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextScaled = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	Text = "",
}, panel)
create("UITextSizeConstraint", { MaxTextSize = 20, MinTextSize = 11 }, textLabel)

local skipButton = create("TextButton", {
	Name = "Skip",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, 0),
	Size = UDim2.new(0, 100, 0, 40),
	BackgroundColor3 = Color3.fromRGB(70, 75, 85),
	Font = Enum.Font.GothamMedium,
	TextSize = 16,
	TextColor3 = Color3.fromRGB(235, 235, 235),
	Text = "Lewati",
}, panel)
create("UICorner", { CornerRadius = UDim.new(0, 8) }, skipButton)

local nextButton = create("TextButton", {
	Name = "Next",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, 0, 1, 0),
	Size = UDim2.new(0, 120, 0, 40),
	BackgroundColor3 = Color3.fromRGB(214, 160, 60),
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = Color3.fromRGB(25, 20, 10),
	Text = "Lanjut",
}, panel)
create("UICorner", { CornerRadius = UDim.new(0, 8) }, nextButton)

local progressLabel = create("TextLabel", {
	Name = "Progress",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(0, 80, 0, 40),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextSize = 14,
	TextColor3 = Color3.fromRGB(160, 160, 160),
	Text = "",
}, panel)

------------------------------------------------------------------------
-- Freeze gerak pemain (lewat kontrol bawaan Roblox; WalkSpeed tidak disentuh
-- agar tidak bentrok dengan efek Thirsty di Phase 2)
------------------------------------------------------------------------

local controlsCache: any = nil
local frozen = false

local function getHumanoid(): Humanoid?
	local character = localPlayer.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getControls(): any
	if controlsCache then
		return controlsCache
	end
	local ok, result = pcall(function()
		local playerScripts = localPlayer:WaitForChild("PlayerScripts")
		local playerModule = playerScripts:WaitForChild("PlayerModule", 5)
		return (require(playerModule :: ModuleScript) :: any):GetControls()
	end)
	if ok and result then
		controlsCache = result
		return result
	end
	warn("[DialogueClient] Gagal mengambil kontrol PlayerModule: " .. tostring(result))
	return nil
end

local function setFrozen(shouldFreeze: boolean)
	if frozen == shouldFreeze then
		return
	end
	local controls = getControls()
	if not controls then
		return
	end
	frozen = shouldFreeze
	if shouldFreeze then
		controls:Disable()
		local humanoid = getHumanoid()
		if humanoid then
			humanoid:Move(Vector3.zero)
		end
	else
		controls:Enable()
	end
end

------------------------------------------------------------------------
-- Kamera ke wajah NPC
------------------------------------------------------------------------

local cameraOverridden = false
local savedCameraType: Enum.CameraType? = nil
local savedCFrame: CFrame? = nil
local pendingRestoreType: Enum.CameraType? = nil
local cameraTween: Tween? = nil
local cameraToken = 0

local function cancelCameraTween()
	if cameraTween then
		cameraTween:Cancel()
		cameraTween = nil
	end
end

local function focusCameraOn(focus: BasePart)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	cameraToken += 1
	cancelCameraTween()

	if not cameraOverridden then
		cameraOverridden = true
		savedCameraType = pendingRestoreType or camera.CameraType
		savedCFrame = camera.CFrame
		pendingRestoreType = nil
	end

	local character = localPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local focusPos = focus.Position

	-- Arah dari NPC ke pemain (horizontal), digeser sedikit ke samping.
	local flat = Vector3.zero
	if root and root:IsA("BasePart") then
		local delta = root.Position - focusPos
		flat = Vector3.new(delta.X, 0, delta.Z)
	end
	if flat.Magnitude < 0.1 then
		local look = focus.CFrame.LookVector
		flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude < 0.1 then
			flat = Vector3.new(0, 0, 1)
		end
	end
	local dir = CFrame.Angles(0, math.rad(CAMERA_CFG.SideAngle), 0):VectorToWorldSpace(flat.Unit)
	local offset: Vector3 = dir * CAMERA_CFG.Distance + Vector3.new(0, CAMERA_CFG.Height, 0)
	local desired = focusPos + offset

	-- Jangan tembus dinding: jika ada penghalang, kamera dimajukan.
	local ignore: { Instance } = {}
	if character then
		table.insert(ignore, character)
	end
	local npcModel = focus:FindFirstAncestorOfClass("Model")
	if npcModel then
		table.insert(ignore, npcModel)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local hit = Workspace:Raycast(focusPos, offset, params)
	if hit then
		local hitDistance = (hit.Position - focusPos).Magnitude
		desired = focusPos + offset.Unit * math.max(hitDistance - 0.5, 1.5)
	end

	camera.CameraType = Enum.CameraType.Scriptable
	local tween = TweenService:Create(
		camera,
		TweenInfo.new(CAMERA_CFG.TweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = CFrame.lookAt(desired, focusPos) }
	)
	cameraTween = tween
	tween:Play()
end

local function restoreCamera(instant: boolean)
	if not cameraOverridden then
		return
	end
	cameraOverridden = false
	cameraToken += 1
	local token = cameraToken
	cancelCameraTween()

	local camera = Workspace.CurrentCamera
	local previousType = savedCameraType or Enum.CameraType.Custom
	local previousCFrame = savedCFrame
	savedCameraType = nil
	savedCFrame = nil
	if not camera then
		return
	end

	if instant or not previousCFrame then
		camera.CameraType = previousType
		return
	end

	pendingRestoreType = previousType
	local tween = TweenService:Create(
		camera,
		TweenInfo.new(CAMERA_CFG.ReturnTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = previousCFrame }
	)
	cameraTween = tween
	tween.Completed:Connect(function()
		if cameraToken == token then
			cameraTween = nil
			pendingRestoreType = nil
			camera.CameraType = previousType
		end
	end)
	tween:Play()
end

------------------------------------------------------------------------
-- State dialog
------------------------------------------------------------------------

local active = false
local currentSessionId = 0
local currentLines: { DialogueLine } = {}
local currentIndex = 0
local typing = false
local typeToken = 0

local function completeTyping()
	typeToken += 1
	typing = false
	textLabel.MaxVisibleGraphemes = -1
end

local function showLine(index: number)
	currentIndex = index
	local line = currentLines[index]
	nameLabel.Text = line.speaker
	textLabel.Text = line.text
	progressLabel.Text = ("%d / %d"):format(index, #currentLines)
	nextButton.Text = if index == #currentLines then "Selesai" else "Lanjut"

	typeToken += 1
	local token = typeToken
	typing = true
	textLabel.MaxVisibleGraphemes = 0

	task.spawn(function()
		local total = utf8.len(line.text) or #line.text
		local shown = 0
		while shown < total and typeToken == token do
			shown += 1
			textLabel.MaxVisibleGraphemes = shown
			task.wait(1 / CHARS_PER_SECOND)
		end
		if typeToken == token then
			typing = false
			textLabel.MaxVisibleGraphemes = -1
		end
	end)
end

local function closeUi()
	active = false
	typeToken += 1
	typing = false
	gui.Enabled = false
	ContextActionService:UnbindAction(ACTION_NAME)
	ProximityPromptService.Enabled = true
	setFrozen(false)
	local humanoid = getHumanoid()
	restoreCamera(humanoid == nil or humanoid.Health <= 0)
end

local function finish(skipped: boolean)
	if not active then
		return
	end
	local sessionId = currentSessionId
	closeUi()
	finishEvent:FireServer(sessionId, skipped)
end

local function advance()
	if not active then
		return
	end
	if typing then
		completeTyping()
		return
	end
	if currentIndex < #currentLines then
		showLine(currentIndex + 1)
	else
		finish(false)
	end
end

local function onAction(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject)
	if inputState == Enum.UserInputState.Begin then
		advance()
	end
	return Enum.ContextActionResult.Sink
end

panel.Activated:Connect(advance)
nextButton.Activated:Connect(advance)
skipButton.Activated:Connect(function()
	finish(true)
end)

------------------------------------------------------------------------
-- Event dari server
------------------------------------------------------------------------

openEvent.OnClientEvent:Connect(function(payload: any)
	if type(payload) ~= "table" or type(payload.sessionId) ~= "number" or type(payload.lines) ~= "table" then
		return
	end
	if #payload.lines == 0 then
		return
	end

	currentSessionId = payload.sessionId
	currentLines = payload.lines
	active = true
	gui.Enabled = true
	ProximityPromptService.Enabled = false -- sembunyikan prompt lain selama dialog
	ContextActionService:BindActionAtPriority(
		ACTION_NAME,
		onAction,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.KeyCode.E,
		Enum.KeyCode.Return,
		Enum.KeyCode.ButtonA
	)
	showLine(1)

	setFrozen(true)
	local focus = payload.focus
	if typeof(focus) == "Instance" and focus:IsA("BasePart") then
		focusCameraOn(focus)
	end
end)

closeEvent.OnClientEvent:Connect(function(sessionId: any)
	if active and sessionId == currentSessionId then
		closeUi() -- ditutup server (pemain menjauh / mati); tidak melapor balik
	end
end)
