local _, Oken = ...
local Cooldowns = Oken:GetModule("Cooldowns")

local SPEC_ASSASSINATION = 259
local SPEC_OUTLAW = 260
local SPEC_SUBTLETY = 261

Cooldowns:RegisterSpells("ROGUE", {
	[1766] = { -- Kick
		cooldown = 15,
		duration = 5
	},
	[31224] = { -- Clock of Shadows
		cooldown = function(unit) return 90 end,
		duration = 5
	},
	[5277] = { -- Evasion
		cooldown = 120,
		duration = 5,
		alias = 199754
	},
})
