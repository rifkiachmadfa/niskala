--!strict
-- WoodQuest: logika quest Kayu (Hutan). Memakai titik kayu yang SUDAH ADA di Workspace.
--
--   * Saat quest dimulai, dipilih tepat `target` titik BERBEDA secara acak dari semua titik.
--   * Kayu hanya dihitung jika pemain benar-benar berhasil mengambilnya (divalidasi server:
--     state quest, titik termasuk yang terpilih untuk pemain itu, belum diambil, jarak).
--   * Menyerahkan kayu ke Agoesz dilakukan lewat dialog (QuestService.TurnIn).
--
-- Tidak ada Part/model yang dibuat atau dipindah. Jika sebuah titik belum punya
-- ProximityPrompt, dibuat satu objek logika nonvisual "KayuPrompt". Visibilitas titik
-- per pemain diatur di sisi client (QuestClient) lewat remote Sync.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local QuestService = require(script.Parent.QuestService)

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 5)
assert(sharedFolder, "[WoodQuest] ReplicatedStorage.Shared tidak ditemukan.")
local configModule = sharedFolder:WaitForChild("GameConfig", 5)
assert(configModule, "[WoodQuest] ReplicatedStorage.Shared.GameConfig tidak ditemukan.")
local GameConfig = require(configModule :: ModuleScript) :: any

local QUEST_ID = "Wood"
local CFG = GameConfig.Quests.Wood
local DISTANCE_PADDING = 8 -- toleransi jarak validasi server di atas MaxActivationDistance

local WoodQuest = {}

local points: { Instance } = {}
-- Titik yang MASIH bisa diambil, per pemain.
local remainingByPlayer: { [Player]: { [Instance]: boolean } } = {}
local rng = Random.new()
local started = false

local syncRemote: RemoteEvent
local notifyRemote: RemoteEvent
local requestSyncRemote: RemoteEvent

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

local function getPointPart(point: Instance): BasePart?
	if point:IsA("BasePart") then
		return point
	end
	if point:IsA("Model") then
		return point.PrimaryPart or point:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function findContainer(name: string): Instance?
	local found: Instance? = nil
	local count = 0
	for _, instance in Workspace:GetDescendants() do
		if instance.Name == name and (instance:IsA("Folder") or instance:IsA("Model")) then
			count += 1
			if not found then
				found = instance
			end
		end
	end
	if count > 1 then
		warn(("[WoodQuest] Ada %d objek bernama '%s'. Memakai yang pertama ditemukan."):format(count, name))
	end
	return found
end

-- Kirim ke client: semua titik kayu + titik yang saat ini aktif untuk pemain ini.
local function sendSync(player: Player)
	local active: { Instance } = {}
	local remaining = remainingByPlayer[player]
	if remaining then
		for point in remaining do
			table.insert(active, point)
		end
	end
	syncRemote:FireClient(player, {
		hideInactive = CFG.hideInactive,
		points = points,
		active = active,
	})
end

local function notifyPlayer(player: Player, text: string)
	notifyRemote:FireClient(player, text)
end

local function pickPoints(player: Player)
	-- Fisher-Yates pada salinan, ambil `target` titik pertama => tidak ada duplikasi.
	local pool = table.clone(points)
	for i = #pool, 2, -1 do
		local j = rng:NextInteger(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local chosen: { [Instance]: boolean } = {}
	for i = 1, math.min(CFG.target, #pool) do
		chosen[pool[i]] = true
	end
	remainingByPlayer[player] = chosen
end

local function onPickup(player: Player, point: Instance, prompt: ProximityPrompt, part: BasePart)
	local remaining = remainingByPlayer[player]
	if not remaining or not remaining[point] then
		return -- bukan titik terpilih untuk pemain ini, atau sudah diambil
	end
	if QuestService.GetState(player, QUEST_ID) ~= "Active" then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (root and root:IsA("BasePart")) or not humanoid or humanoid.Health <= 0 then
		return
	end
	if (root.Position - part.Position).Magnitude > prompt.MaxActivationDistance + DISTANCE_PADDING then
		return
	end

	remaining[point] = nil -- tandai SEBELUM menambah progres agar tidak bisa dihitung dua kali
	local progress = QuestService.AddProgress(player, QUEST_ID, 1)
	if progress == nil then
		remaining[point] = true -- progres ditolak: kembalikan titik
		return
	end
	sendSync(player)
	if progress >= CFG.target then
		notifyPlayer(player, ("Kayu terkumpul %d/%d. Antarkan ke Agoesz di desa!"):format(progress, CFG.target))
	else
		notifyPlayer(player, ("Kayu %d/%d"):format(progress, CFG.target))
	end
end

local function bindPoint(point: Instance)
	local part = getPointPart(point)
	if not part then
		warn(("[WoodQuest] Titik '%s' tidak punya BasePart. Dilewati."):format(point:GetFullName()))
		return
	end

	local prompt = point:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not prompt then
		local newPrompt = Instance.new("ProximityPrompt")
		newPrompt.Name = "KayuPrompt"
		newPrompt.ActionText = "Ambil"
		newPrompt.ObjectText = "Kayu"
		newPrompt.HoldDuration = 0
		newPrompt.MaxActivationDistance = CFG.promptDistance
		newPrompt.RequiresLineOfSight = false
		newPrompt.KeyboardKeyCode = Enum.KeyCode.E
		newPrompt.Parent = part
		prompt = newPrompt
	end
	local bound = prompt :: ProximityPrompt
	bound.Triggered:Connect(function(player: Player)
		onPickup(player, point, bound, part)
	end)
end

function WoodQuest.Start()
	if started then
		return
	end
	started = true

	QuestService.Init()

	local folder = ReplicatedStorage:FindFirstChild("QuestRemotes")
	if not folder then
		local newFolder = Instance.new("Folder")
		newFolder.Name = "QuestRemotes"
		newFolder.Parent = ReplicatedStorage
		folder = newFolder
	end
	local remoteFolder = folder :: Folder
	syncRemote = getOrCreateRemote(remoteFolder, "Sync") -- server -> client
	notifyRemote = getOrCreateRemote(remoteFolder, "Notify") -- server -> client
	requestSyncRemote = getOrCreateRemote(remoteFolder, "RequestSync") -- client -> server

	QuestService.SetAvailable(QUEST_ID, false) -- aktif lagi hanya jika semua titik valid
	local container = findContainer(CFG.spawnContainerName)
	if not container then
		warn(("[WoodQuest] Folder/Model titik kayu '%s' tidak ditemukan di Workspace. Quest Kayu tidak aktif. Sesuaikan GameConfig.Quests.Wood.spawnContainerName dengan nama di Explorer."):format(CFG.spawnContainerName))
		return
	end
	for _, child in container:GetChildren() do
		if child:IsA("BasePart") or child:IsA("Model") then
			table.insert(points, child)
		end
	end
	print(("[WoodQuest] %d titik kayu ditemukan di %s"):format(#points, container:GetFullName()))
	if #points ~= CFG.spawnCount then
		warn(("[WoodQuest] Jumlah titik kayu %d, GDD/konfigurasi mengharapkan %d."):format(#points, CFG.spawnCount))
	end
	if #points < CFG.target then
		warn(("[WoodQuest] Titik kayu (%d) kurang dari target (%d). Quest Kayu tidak aktif."):format(#points, CFG.target))
		points = {}
		return
	end
	for _, point in points do
		bindPoint(point)
	end
	QuestService.SetAvailable(QUEST_ID, true)

	QuestService.Subscribe(function(player: Player, questId: string, state: QuestService.State, progress: number)
		if questId ~= QUEST_ID then
			return
		end
		if state == "Active" and progress == 0 then
			pickPoints(player)
		elseif state == "ReadyToTurnIn" or state == "Completed" then
			remainingByPlayer[player] = {}
		end
		sendSync(player)
		if state == "Completed" then
			notifyPlayer(player, ("Quest selesai! +%d Koin, +%d kepercayaan warga"):format(CFG.rewardCoins, CFG.rewardTrust))
		end
	end)

	requestSyncRemote.OnServerEvent:Connect(function(player: Player)
		sendSync(player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		remainingByPlayer[player] = nil
	end)
end

return WoodQuest
