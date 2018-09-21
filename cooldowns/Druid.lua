local _, Oken = ...
local Cooldowns = Oken:GetModule("Cooldowns")

local SPEC_BALANCE = 102
local SPEC_FERAL = 103
local SPEC_GUARDIAN = 104
local SPEC_RESTORATION = 105

local function GutturalRoars(unit) return unit:HasTalentSpell(204012) and 0.5 or 1.0 end
local function InnerPeace(unit) return unit:HasTalent(21716) and 60 or 0 end
local function Stonebark(unit) return unit:HasTalent(18585) and 15 or 0 end
local function SurvivalOfTheFittest(unit) return unit:HasTalentSpell(203965) and 2/3 or 1 end

Cooldowns:RegisterSpells("DRUID", {
	[77764] = { -- Stampeding Roar
		cooldown = function(unit) return 120 * GutturalRoars(unit) end,
		duration = 8,
		alias = {77761, 106898}, -- Bear
		spec = { SPEC_FERAL, SPEC_GUARDIAN }
	},
	[132469] = { -- Typhoon
		cooldown = 30,
		duration = 6,
		talent = true
	},

	-- Balance
	[78675] = { -- Solar Beam
		cooldown = 60, --function(unit) return 60 - LightOfTheSun(unit) end,
		duration = 8,
		spec = SPEC_BALANCE
	},

	-- Guardian
	[99] = { -- Incapacitating Roar
		cooldown = 30,
		duration = 3,
		spec = SPEC_GUARDIAN
	},
	[22812] = { -- Barkskin
		cooldown = function(unit) return 90 * SurvivalOfTheFittest(unit) end,
		duration = 12,
		duration = 12,
		spec = SPEC_GUARDIAN
	},
	[61336] = { -- Survival Instinct
		cooldown = function(unit) return 240 * SurvivalOfTheFittest(unit) end,
		duration = 6,
		charges = 2,
		spec = SPEC_GUARDIAN
	},

	-- Resto
	[740] = { -- Tranquility
		cooldown = function(unit) return 180 - InnerPeace(unit) end,
		duration = 7,
		spec = SPEC_RESTORATION
	},
	[102342] = { -- Ironbark
		cooldown = function(unit) return 60 - Stonebark(unit) end,
		duration = 12,
		spec = SPEC_RESTORATION
	},
	[102793] = { -- Ursol's Vortex
		cooldown = 60,
		duration = 10,
		spec = SPEC_RESTORATION
	},

	-- Shared
	[29166] = { -- Innervate
		cooldown = 180,
		duration = 12,
		spec = { SPEC_BALANCE, SPEC_RESTORATION },
	},
	[106839] = { -- Skull Bash
		cooldown = 15,
		duration = 4,
		spec = { SPEC_GUARDIAN, SPEC_FERAL }
	},

	-- Talents
	[33891] = { -- Incarnation: Tree of Life
		cooldown = 180,
		duration = 30,
		talent = true
	},
	[102359] = { -- Mass Entanglement
		cooldown = 30,
		duration = 20,
		talent = true
	},
})
