--!strict
-- DialogueClient: menampilkan UI dialog NPC. Hanya presentasi dan input.
-- Semua keputusan (isi dialog, validasi sesi, flag) ada di server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
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
local OPEN_TIMEOUT: number = GameConfig.Dialogue.OpenTimeout

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
local freezeMode: string? = nil -- "controls" (PlayerModule) atau "override" (fallback)
local warnedNoControls = false
local FREEZE_STEP = "NPCDialogueFreeze"

local function getHumanoid(): Humanoid?
	local character = localPlayer.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

-- TIDAK PERNAH yield. PlayerModule dicari apa adanya; jika belum ada, kembalikan nil.
local function tryGetControls(): any
	if controlsCache then
		return controlsCache
	end
	local playerScripts = localPlayer:FindFirstChild("PlayerScripts")
	local playerModule = playerScripts and playerScripts:FindFirstChild("PlayerModule")
	if not playerModule or not playerModule:IsA("ModuleScript") then
		return nil
	end
	local ok, result = pcall(function()
		return (require(playerModule) :: any):GetControls()
	end)
	if ok and result then
		controlsCache = result
		return result
	end
	if not warnedNoControls then
		warnedNoControls = true
		warn("[DialogueClient] Gagal mengambil kontrol PlayerModule: " .. tostring(result))
	end
	return nil
end

local function setFrozen(shouldFreeze: boolean)
	if frozen == shouldFreeze then
		return
	end
	frozen = shouldFreeze
	if shouldFreeze then
		local controls = tryGetControls()
		if controls then
			freezeMode = "controls"
			controls:Disable()
		else
			-- Fallback: timpa input gerak tiap frame (setelah kontrol bawaan berjalan).
			-- Tidak menyentuh WalkSpeed, jadi aman untuk efek Thirsty di Phase 2.
			freezeMode = "override"
			RunService:BindToRenderStep(FREEZE_STEP, Enum.RenderPriority.Input.Value + 1, function()
				local humanoid = getHumanoid()
				if humanoid then
					humanoid:Move(Vector3.zero)
					humanoid.Jump = false
				end
			end)
		end
		local humanoid = getHumanoid()
		if humanoid then
			humanoid:Move(Vector3.zero)
		end
	else
		if freezeMode == "controls" then
			local controls = tryGetControls()
			if controls then
				controls:Enable()
			end
		elseif freezeMode == "override" then
			RunService:UnbindFromRenderStep(FREEZE_STEP)
		end
		freezeMode = nil
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

local function focusCameraOn(focus: BasePart): Tween?
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
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
	return tween
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
local uiReady = false -- true setelah kamera terkunci dan panel dialog ditampilkan
local revealToken = 0

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
	uiReady = false
	revealToken += 1
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
	if not active or not uiReady then
		return
	end
	local sessionId = currentSessionId
	closeUi()
	finishEvent:FireServer(sessionId, skipped)
end

local function advance()
	if not active or not uiReady then
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
-- Respons instan: kunci kamera + gerak begitu prompt NPC ditekan di client,
-- tanpa menunggu balasan server. Dialog tetap baru tampil saat server membuka sesi.
------------------------------------------------------------------------

local pending = false
local pendingToken = 0
local pendingTween: Tween? = nil

local function cancelPending()
	pendingToken += 1
	if not pending then
		return
	end
	pending = false
	pendingTween = nil
	if not active then
		ProximityPromptService.Enabled = true
		setFrozen(false)
		restoreCamera(false)
	end
end

local function resolveFocus(prompt: ProximityPrompt): BasePart?
	local focusName = prompt:GetAttribute("DialogueFocusPart")
	if type(focusName) ~= "string" then
		return nil
	end
	local ancestor: Instance? = prompt.Parent
	while ancestor and ancestor ~= Workspace do
		if ancestor:IsA("Model") then
			local found = ancestor:FindFirstChild(focusName, true)
			if found and found:IsA("BasePart") then
				return found
			end
		end
		ancestor = ancestor.Parent
	end
	return nil
end

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
	if player ~= localPlayer or active or pending then
		return
	end
	if prompt:GetAttribute("DialogueNPC") == nil then
		return
	end
	local focus = resolveFocus(prompt)
	if not focus then
		return -- fokus belum tersedia di client (mis. belum ter-stream); pakai alur normal
	end
	pending = true
	pendingToken += 1
	local myToken = pendingToken
	ProximityPromptService.Enabled = false
	pendingTween = focusCameraOn(focus)
	setFrozen(true)
	task.delay(OPEN_TIMEOUT, function()
		if pending and pendingToken == myToken and not active then
			cancelPending() -- server menolak / tidak membuka dialog
		end
	end)
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
	uiReady = false
	revealToken += 1
	local myReveal = revealToken
	local mySession = payload.sessionId

	ProximityPromptService.Enabled = false -- sembunyikan prompt lain selama dialog
	-- Bind sekarang (Sink) agar tombol E saat kamera bergerak tidak memicu hal lain;
	-- advance() sendiri mengabaikan input sampai uiReady = true.
	ContextActionService:BindActionAtPriority(
		ACTION_NAME,
		onAction,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.KeyCode.E,
		Enum.KeyCode.Return,
		Enum.KeyCode.ButtonA
	)

	-- 1) Kunci kamera dan gerak DULU. Panel dialog baru muncul setelah kamera sampai.
	setFrozen(true)
	local tween: Tween? = nil
	local focus = payload.focus
	if pending then
		-- Kamera sudah dikunci saat prompt ditekan; lanjutkan tween yang berjalan.
		pending = false
		pendingToken += 1
		tween = pendingTween
		pendingTween = nil
		if tween and tween.PlaybackState ~= Enum.PlaybackState.Playing then
			tween = nil -- sudah sampai: dialog langsung tampil
		end
	elseif typeof(focus) == "Instance" and focus:IsA("BasePart") then
		tween = focusCameraOn(focus)
	end

	-- 2) Tampilkan dialog (hanya sekali, dan hanya jika sesi masih yang sama).
	local function reveal()
		if not active or uiReady or revealToken ~= myReveal or currentSessionId ~= mySession then
			return
		end
		uiReady = true
		gui.Enabled = true
		showLine(1)
	end

	if tween then
		tween.Completed:Once(reveal)
		-- Pengaman: jika Completed tidak terpanggil, dialog tetap muncul.
		task.delay(CAMERA_CFG.TweenTime + CAMERA_CFG.RevealTimeoutPadding, reveal)
	else
		reveal() -- tanpa kamera (focus/camera tidak ada): tampilkan langsung
	end
end)

closeEvent.OnClientEvent:Connect(function(sessionId: any)
	if active and sessionId == currentSessionId then
		closeUi() -- ditutup server (pemain menjauh / mati); tidak melapor balik
	end
end)

-- Pemanasan di background: cache kontrol PlayerModule jika sudah tersedia.
-- Tidak pernah memblokir dialog.
task.spawn(function()
	local deadline = os.clock() + 15
	while not tryGetControls() and os.clock() < deadline do
		task.wait(0.5)
	end
	if not controlsCache then
		warn("[DialogueClient] PlayerModule tidak ditemukan; gerak dibekukan lewat fallback.")
	end
end)
