--!strict
-- PlayerStats: pemilik state Hunger/Thirsty per pemain (server = sumber kebenaran).
--
-- Perilaku:
--   * Hunger dan Thirsty berkurang (default: hanya saat pemain benar-benar bergerak,
--     diukur server dari perpindahan HumanoidRootPart; atur DrainOnlyWhileWalking).
--   * Thirsty turun lebih cepat daripada Hunger (lihat GameConfig.Survival).
--   * Jika Hunger DAN Thirsty kosong, HP berkurang berkala.
--   * Setelah mati, nilai di-set ke RespawnHunger/RespawnThirsty saat karakter muncul lagi.
--
-- State dicerminkan ke Attribute Player ("Hunger", "Thirsty") agar HUD client bisa
-- membaca tanpa Remote. Client tidak bisa mengubah state server lewat Attribute.
--
-- BUKAN tanggung jawab modul ini: koin, shop, regen HP, efek lambat Thirsty 0.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SurvivalLogic = require(script.Parent.SurvivalLogic)

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 5)
assert(sharedFolder, "[PlayerStats] ReplicatedStorage.Shared tidak ditemukan.")
local configModule = sharedFolder:WaitForChild("GameConfig", 5)
assert(configModule, "[PlayerStats] ReplicatedStorage.Shared.GameConfig tidak ditemukan.")
local GameConfig = require(configModule :: ModuleScript) :: any
local CFG = GameConfig.Survival

type PlayerData = {
	state: SurvivalLogic.State,
	lastPos: Vector3?,
	respawnReset: boolean,
	characterConn: RBXScriptConnection?,
	diedConn: RBXScriptConnection?,
	shownHunger: number,
	shownThirst: number,
}

local PlayerStats = {}

local dataByPlayer: { [Player]: PlayerData } = {}
local connections: { RBXScriptConnection } = {}
local started = false

local function publish(player: Player, data: PlayerData)
	local hunger = SurvivalLogic.Display(data.state.hunger)
	local thirst = SurvivalLogic.Display(data.state.thirst)
	-- SetAttribute hanya dipanggil bila nilai tampilan berubah (hemat replikasi).
	if hunger ~= data.shownHunger then
		data.shownHunger = hunger
		player:SetAttribute("Hunger", hunger)
	end
	if thirst ~= data.shownThirst then
		data.shownThirst = thirst
		player:SetAttribute("Thirsty", thirst)
	end
end

local function getHumanoid(player: Player): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

local function onCharacterAdded(player: Player, character: Model)
	local data = dataByPlayer[player]
	if not data then
		return
	end

	data.lastPos = nil
	if data.diedConn then
		data.diedConn:Disconnect()
		data.diedConn = nil
	end

	if data.respawnReset then
		data.respawnReset = false
		data.state = SurvivalLogic.NewState(CFG.RespawnHunger, CFG.RespawnThirsty)
		publish(player, data)
	end

	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if humanoid and dataByPlayer[player] == data then
		data.diedConn = humanoid.Died:Connect(function()
			data.respawnReset = true
		end)
	end
end

local function addPlayer(player: Player)
	if dataByPlayer[player] then
		return
	end

	local data: PlayerData = {
		state = SurvivalLogic.NewState(CFG.StartHunger, CFG.StartThirsty),
		lastPos = nil,
		respawnReset = false,
		characterConn = nil,
		diedConn = nil,
		shownHunger = -1,
		shownThirst = -1,
	}
	dataByPlayer[player] = data
	publish(player, data)

	data.characterConn = player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end

local function removePlayer(player: Player)
	local data = dataByPlayer[player]
	if not data then
		return
	end
	if data.characterConn then
		data.characterConn:Disconnect()
	end
	if data.diedConn then
		data.diedConn:Disconnect()
	end
	dataByPlayer[player] = nil
end

-- Apakah pemain sedang berjalan? Diukur dari kecepatan horizontal nyata.
local function isWalking(data: PlayerData, humanoid: Humanoid, dt: number): boolean
	local root = humanoid.RootPart
	if not root then
		data.lastPos = nil
		return false
	end

	local pos = root.Position
	local last = data.lastPos
	data.lastPos = pos
	if not last or dt <= 0 then
		return false
	end

	local delta = pos - last
	local horizontalSpeed = Vector3.new(delta.X, 0, delta.Z).Magnitude / dt
	return horizontalSpeed >= CFG.MinWalkSpeed and horizontalSpeed <= CFG.TeleportSpeedLimit
end

local function tick(dt: number)
	for player, data in dataByPlayer do
		local humanoid = getHumanoid(player)
		if not humanoid or humanoid.Health <= 0 then
			data.lastPos = nil
			continue
		end

		local walking = isWalking(data, humanoid, dt)
		local draining = walking or not CFG.DrainOnlyWhileWalking
		local damage = SurvivalLogic.Step(data.state, dt, draining, CFG)
		publish(player, data)

		if damage > 0 and humanoid.Health > 0 then
			-- Set langsung (bukan TakeDamage) agar tidak diblok ForceField spawn.
			humanoid.Health = math.max(0, humanoid.Health - damage)
		end
	end
end

------------------------------------------------------------------------
-- API publik (server saja; dipakai Shop/Quest di phase berikutnya)
------------------------------------------------------------------------

-- Mengembalikan (hunger, thirsty) sebagai bilangan bulat, atau nil jika pemain tidak dikenal.
function PlayerStats.Get(player: Player): (number?, number?)
	local data = dataByPlayer[player]
	if not data then
		return nil, nil
	end
	return SurvivalLogic.Display(data.state.hunger), SurvivalLogic.Display(data.state.thirst)
end

-- Menambah/mengurangi status. stat = "Hunger" | "Thirsty". Hasil di-clamp 0..MaxStat.
function PlayerStats.Add(player: Player, stat: string, amount: number): boolean
	local data = dataByPlayer[player]
	if not data or type(amount) ~= "number" or amount ~= amount then
		return false
	end
	if stat == "Hunger" then
		data.state.hunger = SurvivalLogic.Clamp(data.state.hunger + amount, CFG.MaxStat)
	elseif stat == "Thirsty" then
		data.state.thirst = SurvivalLogic.Clamp(data.state.thirst + amount, CFG.MaxStat)
	else
		warn("[PlayerStats] Stat tidak dikenal: " .. tostring(stat))
		return false
	end
	publish(player, data)
	return true
end

function PlayerStats.Start()
	if started then
		return
	end
	started = true

	table.insert(connections, Players.PlayerAdded:Connect(addPlayer))
	table.insert(connections, Players.PlayerRemoving:Connect(removePlayer))
	for _, player in Players:GetPlayers() do
		addPlayer(player)
	end

	task.spawn(function()
		local last = os.clock()
		while started do
			task.wait(CFG.TickInterval)
			local now = os.clock()
			local dt = now - last
			last = now
			local ok, err = pcall(tick, dt)
			if not ok then
				warn("[PlayerStats] Error pada tick: " .. tostring(err))
			end
		end
	end)
end

return PlayerStats
