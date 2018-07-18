local _, Oken = ...
local Cooldowns = Oken:GetModule("Cooldowns")

local SPEC_BLOOD = 250
local SPEC_FROST = 251
local SPEC_UNHOLY = 252

local function TighteningGrasp(unit) return unit:HasTalentSpell(206970) and 30 or 0 end
local function SpellEater(unit) return unit:HasTalentSpell(207321) and 5 or 0 end

Cooldowns:RegisterSpells("DEATHKNIGHT", {
	[49576] = { -- Death Grip
		cooldown = function(unit) return (unit.info.global_spec_id == SPEC_BLOOD) and 15 or 25 end,
		duration = 3
	},
	[47528] = { -- Mind freeze
		cooldown = 15,
		duration = 3
	},
	[48707] = { -- Anti-Magic Shell
		cooldown = 60,
		duration = function(unit) return 5 + SpellEater(unit) end
		-- TODO: Duration affected by item
	},

	-- Blood
	[108199] = { -- Gorefiend's Grasp
		cooldown = function(unit) return 120 - TighteningGrasp(unit) end,
		spec = SPEC_BLOOD
	},
	[55233] = { -- Vampiric Blood
		cooldown = 90,
		duration = 10,
		spec = SPEC_BLOOD
		-- TODO: Affected by item
	},
	[49028] = { -- Dancing Rune Weapon
		cooldown = 120,
		duration = function(unit) return 8 end,
		spec = SPEC_BLOOD
	},

	-- Talents
	[194679] = { -- Rune Tap
		cooldown = 25,
		duration = 3,
		charges = 2,
		talent = true
	},
	[206977] = { -- Blood Mirror
		cooldown = 120,
		duration = 10,
		talent = true
	},
	[207319] = { -- Corpse Shield
		cooldown = 60,
		duration = 10,
		talent = true
	},
})
