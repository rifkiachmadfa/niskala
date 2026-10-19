--!strict
-- SurvivalLogic: aturan murni Hunger/Thirsty (tanpa API Roblox) agar mudah diuji.
-- Hanya dipakai oleh PlayerStats.

export type Config = {
	MaxStat: number,
	HungerWalkSecondsPerPoint: number,
	ThirstWalkSecondsPerPoint: number,
	StarvationDamage: number,
	StarvationDamageInterval: number,
}

export type State = {
	hunger: number,
	thirst: number,
	damageTimer: number,
}

local SurvivalLogic = {}

function SurvivalLogic.NewState(hunger: number, thirst: number): State
	return { hunger = hunger, thirst = thirst, damageTimer = 0 }
end

function SurvivalLogic.Clamp(value: number, maxValue: number): number
	return math.clamp(value, 0, maxValue)
end

-- Nilai tampilan (bilangan bulat). Memakai ceil supaya angka 0 hanya muncul
-- ketika status benar-benar kosong (konsisten dengan syarat damage).
function SurvivalLogic.Display(value: number): number
	return math.ceil(value - 1e-9)
end

function SurvivalLogic.IsStarving(state: State): boolean
	return state.hunger <= 0 and state.thirst <= 0
end

-- Memajukan state sebesar dt detik. Mengembalikan total damage HP yang harus
-- diberikan pada langkah ini (0 jika tidak ada).
function SurvivalLogic.Step(state: State, dt: number, walking: boolean, cfg: Config): number
	if dt <= 0 then
		return 0
	end

	if walking then
		state.thirst = SurvivalLogic.Clamp(state.thirst - dt / cfg.ThirstWalkSecondsPerPoint, cfg.MaxStat)
		state.hunger = SurvivalLogic.Clamp(state.hunger - dt / cfg.HungerWalkSecondsPerPoint, cfg.MaxStat)
	end

	if SurvivalLogic.IsStarving(state) then
		state.damageTimer += dt
		local ticks = math.floor(state.damageTimer / cfg.StarvationDamageInterval)
		if ticks > 0 then
			state.damageTimer -= ticks * cfg.StarvationDamageInterval
			return ticks * cfg.StarvationDamage
		end
	else
		state.damageTimer = 0
	end

	return 0
end

return SurvivalLogic
