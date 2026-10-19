--!strict
-- DialogueService: sistem dialog NPC generik (server = sumber kebenaran).
--
-- Tanggung jawab:
--   * Mencari Model NPC yang SUDAH ADA di Workspace (tidak membuat/mengubah model).
--   * Memakai ProximityPrompt yang sudah ada di model; jika tidak ada, membuat satu
--     objek logika nonvisual bernama "DialoguePrompt" di bagian model NPC.
--   * Memilih percakapan per pemain (via selectConversation milik data NPC).
--   * Mengirim baris dialog ke client, memvalidasi sesi, dan menutup dialog jika
--     pemain menjauh / mati / keluar.
--   * Menyimpan flag dialog per pemain (SEMENTARA di memori, belum disimpan ke DataStore).
--
-- BUKAN tanggung jawab modul ini: koin, quest, kepercayaan, gerbang.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Types = require(script.Parent.DialogueTypes)

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 5)
assert(sharedFolder, "[Dialogue] ReplicatedStorage.Shared tidak ditemukan. Buat folder Shared dan taruh GameConfig di dalamnya.")
local configModule = sharedFolder:WaitForChild("GameConfig", 5)
assert(configModule, "[Dialogue] ReplicatedStorage.Shared.GameConfig tidak ditemukan.")
local GameConfig = require(configModule :: ModuleScript) :: any

type Session = {
	id: number,
	npcId: string,
	conversationId: string,
	anchor: BasePart,
	closeDistance: number,
}

type Remotes = {
	Open: RemoteEvent,
	Finish: RemoteEvent,
	Close: RemoteEvent,
}

local DialogueService = {}

local npcs: { [string]: Types.NPCDefinition } = {}
local sessions: { [Player]: Session } = {}
local flagsByUserId: { [number]: { [string]: any } } = {}
local nextSessionId = 0
local started = false
local remotes: Remotes

------------------------------------------------------------------------
-- Flag dialog per pemain (sementara; Phase 8 akan memindahkannya ke SaveService)
------------------------------------------------------------------------

function DialogueService.SetFlag(player: Player, key: string, value: any)
	local flags = flagsByUserId[player.UserId]
	if not flags then
		flags = {}
		flagsByUserId[player.UserId] = flags
	end
	flags[key] = value
end

function DialogueService.GetFlag(player: Player, key: string): any
	local flags = flagsByUserId[player.UserId]
	if flags then
		return flags[key]
	end
	return nil
end

function DialogueService.HasFlag(player: Player, key: string): boolean
	local value = DialogueService.GetFlag(player, key)
	return value ~= nil and value ~= false
end

function DialogueService.IsInDialogue(player: Player): boolean
	return sessions[player] ~= nil
end

------------------------------------------------------------------------
-- Helper
------------------------------------------------------------------------

local function formatText(text: string): string
	local result = string.gsub(text, "{(%w+)}", function(key: string)
		local value = GameConfig[key]
		if value ~= nil then
			return tostring(value)
		end
		warn(("[Dialogue] Placeholder {%s} tidak ada di GameConfig"):format(key))
		return nil
	end)
	return result
end

local function getRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function isAlive(player: Player): boolean
	local character = player.Character
	if not character then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function endSession(player: Player, session: Session, notifyClient: boolean)
	if sessions[player] ~= session then
		return
	end
	sessions[player] = nil
	if notifyClient and player.Parent == Players then
		remotes.Close:FireClient(player, session.id)
	end
end

local function monitorSession(player: Player, session: Session)
	local interval: number = GameConfig.Dialogue.DistanceCheckInterval
	task.spawn(function()
		while sessions[player] == session do
			task.wait(interval)
			if sessions[player] ~= session then
				return
			end
			local root = getRoot(player)
			if
				not root
				or not isAlive(player)
				or not session.anchor:IsDescendantOf(Workspace)
				or (root.Position - session.anchor.Position).Magnitude > session.closeDistance
			then
				endSession(player, session, true)
				return
			end
		end
	end)
end

------------------------------------------------------------------------
-- Memulai percakapan
------------------------------------------------------------------------

local function startConversation(def: Types.NPCDefinition, anchor: BasePart, prompt: ProximityPrompt, player: Player)
	if sessions[player] then
		return -- sudah dalam dialog
	end
	local root = getRoot(player)
	if not root or not isAlive(player) then
		return
	end

	local closeDistance = prompt.MaxActivationDistance + (GameConfig.Dialogue.CloseDistancePadding :: number)
	if (root.Position - anchor.Position).Magnitude > closeDistance then
		return -- validasi jarak di server
	end

	local ctx: Types.SelectContext = {
		player = player,
		hasFlag = function(key: string)
			return DialogueService.HasFlag(player, key)
		end,
		getFlag = function(key: string)
			return DialogueService.GetFlag(player, key)
		end,
	}

	local ok, conversationId = pcall(def.selectConversation, ctx)
	if not ok then
		warn(("[Dialogue] selectConversation error untuk NPC '%s': %s"):format(def.id, tostring(conversationId)))
		return
	end
	local conversation = def.conversations[conversationId]
	if not conversation or #conversation.lines == 0 then
		warn(("[Dialogue] Percakapan '%s' tidak valid untuk NPC '%s'"):format(tostring(conversationId), def.id))
		return
	end

	local lines = {}
	for _, line in conversation.lines do
		table.insert(lines, {
			speaker = line.speaker or def.displayName,
			text = formatText(line.text),
		})
	end

	nextSessionId += 1
	local session: Session = {
		id = nextSessionId,
		npcId = def.id,
		conversationId = conversationId,
		anchor = anchor,
		closeDistance = closeDistance,
	}
	sessions[player] = session

	remotes.Open:FireClient(player, {
		sessionId = session.id,
		npcName = def.displayName,
		lines = lines,
	})
	monitorSession(player, session)
end

------------------------------------------------------------------------
-- Mengikat NPC ke model yang sudah ada
------------------------------------------------------------------------

local function findNPCModel(modelName: string): Model?
	local found: Model? = nil
	local count = 0
	for _, instance in Workspace:GetDescendants() do
		if instance.Name == modelName and instance:IsA("Model") then
			count += 1
			if not found then
				found = instance
			end
		end
	end
	if count > 1 then
		warn(("[Dialogue] Ada %d Model bernama '%s' di Workspace. Memakai yang pertama ditemukan."):format(count, modelName))
	end
	return found
end

local function findAnchor(model: Model): BasePart?
	if model.PrimaryPart then
		return model.PrimaryPart
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

function DialogueService.RegisterNPC(def: Types.NPCDefinition): boolean
	if npcs[def.id] then
		warn(("[Dialogue] NPC '%s' sudah terdaftar."):format(def.id))
		return false
	end

	local model = findNPCModel(def.modelName)
	if not model then
		warn(("[Dialogue] Model '%s' tidak ditemukan di Workspace. NPC '%s' dilewati."):format(def.modelName, def.id))
		return false
	end
	local anchor = findAnchor(model)
	if not anchor then
		warn(("[Dialogue] Model '%s' tidak punya BasePart untuk dijadikan titik interaksi."):format(def.modelName))
		return false
	end

	-- Pakai prompt yang sudah ada jika ada; jangan menggandakan.
	local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		print(("[Dialogue] '%s': memakai ProximityPrompt yang sudah ada (%s)"):format(def.id, prompt:GetFullName()))
	else
		local settings = def.prompt
		local newPrompt = Instance.new("ProximityPrompt")
		newPrompt.Name = "DialoguePrompt"
		newPrompt.ActionText = (settings and settings.actionText) or "Bicara"
		newPrompt.ObjectText = def.displayName
		newPrompt.HoldDuration = 0
		newPrompt.MaxActivationDistance = (settings and settings.maxActivationDistance) or 10
		newPrompt.RequiresLineOfSight = false
		newPrompt.KeyboardKeyCode = Enum.KeyCode.E
		newPrompt.Parent = anchor
		prompt = newPrompt
		print(("[Dialogue] '%s': membuat DialoguePrompt di %s"):format(def.id, anchor:GetFullName()))
	end
	local boundPrompt = prompt :: ProximityPrompt

	npcs[def.id] = def
	boundPrompt.Triggered:Connect(function(player: Player)
		startConversation(def, anchor, boundPrompt, player)
	end)
	return true
end

------------------------------------------------------------------------
-- Start
------------------------------------------------------------------------

local function getOrCreateRemote(folder: Folder, name: string): RemoteEvent
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

function DialogueService.Start(definitions: { Types.NPCDefinition })
	if started then
		warn("[Dialogue] Start dipanggil lebih dari sekali.")
		return
	end
	started = true

	local folder = ReplicatedStorage:FindFirstChild("DialogueRemotes")
	if not folder then
		local newFolder = Instance.new("Folder")
		newFolder.Name = "DialogueRemotes"
		newFolder.Parent = ReplicatedStorage
		folder = newFolder
	end
	local remoteFolder = folder :: Folder
	remotes = {
		Open = getOrCreateRemote(remoteFolder, "Open"), -- server -> client
		Close = getOrCreateRemote(remoteFolder, "Close"), -- server -> client
		Finish = getOrCreateRemote(remoteFolder, "Finish"), -- client -> server
	}

	-- Client melapor dialog selesai / dilewati. Server memvalidasi sesi.
	remotes.Finish.OnServerEvent:Connect(function(player: Player, sessionId: unknown, _skipped: unknown)
		local session = sessions[player]
		if type(sessionId) ~= "number" or not session or session.id ~= sessionId then
			return
		end
		sessions[player] = nil

		local def = npcs[session.npcId]
		local conversation = def and def.conversations[session.conversationId]
		if conversation and conversation.setFlags then
			for key, value in conversation.setFlags do
				DialogueService.SetFlag(player, key, value)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		sessions[player] = nil
		flagsByUserId[player.UserId] = nil
	end)

	for _, def in definitions do
		DialogueService.RegisterNPC(def)
	end
end

return DialogueService
