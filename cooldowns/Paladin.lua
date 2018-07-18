local _, Oken = ...
local Cooldowns = Oken:GetModule("Cooldowns")

local SPEC_HOLY = 65
local SPEC_PROTECTION = 66
local SPEC_RETRIBUTION  = 70

local function UnbreakableSpirit(unit) return unit:HasTalentSpell(114154) and 0.7 or 1 end
local function DivineIntervention(unit) return unit:HasTalentSpell(213313) and 0.8 or 1 end

local function UthersGuard(unit) return unit:HasLegendary(137105) and 1.5 or 1 end
local function TyrsHandOfFaith(unit) return unit:HasLegendary(137059) and 0.3 or 1 end

local function HandDuration(base)
	return function(unit)
		return base * UthersGuard(unit)
	end
end

Cooldowns:RegisterSpells("PALADIN", {
	[642] = { -- Divine Shield
		cooldown = function(unit) return 300 * UnbreakableSpirit(unit) * DivineIntervention(unit) end,
		duration = 8,
	},
	[633] = { -- Lay on Hands
		cooldown = function(unit)
			return 600 * UnbreakableSpirit(unit) * TyrsHandOfFaith(unit)
		end
	},
	[1044] = { -- Blessing of Freedom
		cooldown = function(unit)
			return 25
		end,
		duration = HandDuration(8)
	},
	[1022] = { -- Blessing of Protection
		cooldown = function(unit) return 300 end,
		duration = HandDuration(10),
		icon = 135964,
		available = function(unit) return not unit:HasTalent(22433) end
	},
	[6940] = { -- Blessing of Sacrifice
		cooldown = function(unit) return 150 end,
		duration = HandDuration(12),
		spec = { SPEC_HOLY, SPEC_PROTECTION }
	},

	-- Holy
	[31842] = { -- Avenging Wrath (Holy)
		cooldown = 120,
		duration = function(unit) return unit:HasTalent(22190) and 30 or 20 end,
		spec = SPEC_HOLY
	},
	[31821] = { -- Aura Mastery
		cooldown = 180,
		duration = function(unit) return 6 end,
		spec = SPEC_HOLY
	},
	[498] = {
		-- Divine Protection
		cooldown = function(unit) return 60 * UnbreakableSpirit(unit) end,
		duration = function(unit) return 8 end,
		icon = 524353,
		spec = SPEC_HOLY
	},

	-- Protection
	[86659] = { -- Guardian of Ancient King
		cooldown = 300,
		duration = 8,
		spec = SPEC_PROTECTION
	},
	[31850] = { -- Ardent Defender
		cooldown = function(unit) return 120 end,
		duration = 8,
		spec = SPEC_PROTECTION
	},

	-- Shared
	[96231] = { -- Rebuke
		cooldown = 15,
		duration = 4,
		spec = { SPEC_PROTECTION, SPEC_RETRIBUTION }
	},

	-- Talents
	[204150] = { -- Aegis of Light
		cooldown = 300,
		duration = 6,
		talent = true
	},
	[204018] = { -- Blessing of Spellwarding
		cooldown = 180,
		duration = 10,
		talent = true
	},
	[105809] = { -- Holy Avenger
		cooldown = 90,
		duration = 20,
		talent = true
	},
})
