local _, Core = ...

Oken = LibStub("AceAddon-3.0"):NewAddon(Core, "Oken")
Oken.Util = {}
Oken.PTR = GetBuildInfo() == "7.1.0"

LibStub("AceEvent-3.0"):Embed(Oken)
LibStub("AceConsole-3.0"):Embed(Oken)

Oken:SetDefaultModuleLibraries("AceEvent-3.0", "AceConsole-3.0")

local LSM = LibStub("LibSharedMedia-3.0")
LSM:Register("font", "Fira Mono Medium", "Interface\\Addons\\Oken_Core\\media\\FiraMono-Medium.ttf")

-- Version
do
	local version_str = "@project-version@"
	local dev_version = "@project" .. "-version@"
	Oken.version = version_str == dev_version and "dev" or version_str
end

function Core:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("OkenDB", nil, true)
	if not self.db.global.PLAYER_KEY then
		self.db.global.PLAYER_KEY = "PK:" .. Oken:UUID() .. ":" .. time()
	end
end

function Core:OnEnable()
	self:RegisterEvent("ENCOUNTER_START")
	self:RegisterEvent("ENCOUNTER_END")
	self:RegisterEvent("GUILD_ROSTER_UPDATE")
	self:RegisterEvent("GUILD_MOTD", "CheckMOTD")
	self:Printf("Core Loaded [%s]", Oken.version)
end

function Core:RegisterModule(name, ...)
	local mod = self:NewModule(name, ...)
	self[name] = mod
	return mod
end

-- MOTD
do
	local motd
	local guildName

	StaticPopupDialogs["GUILD_MOTD"] = {
		text = "",
		button1 = "Ok",
		--button2 = "No",
		OnAccept = function()
			--GreetTheWorld()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3, -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	}

	function Core:CheckMOTD()
		if self:EncounterInProgress() then return end

		local motd = GetGuildRosterMOTD()
		if not motd or motd == "" then return end

		local gname = GetGuildInfo("player")
		if not gname then return end

		self.db.global.motds = self.db.global.motds or {}
		if self.db.global.motds[gname] ~= motd then
			self.db.global.motds[gname] = motd
			StaticPopupDialogs["GUILD_MOTD"].text = "|cffe6494a*** " .. gname .. " ***|r\n\n" .. motd
			StaticPopup_Show("GUILD_MOTD")
		end
	end
end

-- Encounter tracking
do
	function Core:ENCOUNTER_START(id, name, difficulty, size)
		self.encounter = { id = id, name = name, difficulty = difficulty, size = size }
	end

	function Core:ENCOUNTER_END()
		self.encounter = nil
	end

	function Core:EncounterInProgress()
		return self.encounter
	end
end

-- Players tracking
do
	function Core:NormalizeName(name)
		if not name then return name end
		return name:match("([^\\-]+)") or name
	end

	local guild_members = {}
	function Core:GUILD_ROSTER_UPDATE()
		if self:EncounterInProgress() then return end
		wipe(guild_members)
		for i = 1, GetNumGuildMembers() do
			local name = self:NormalizeName(GetGuildRosterInfo(i))
			if name then guild_members[name] = true end
		end
		self:CheckMOTD()
	end

	function Core:UnitIsInGuild(unit)
		return guild_members[UnitName(unit) or unit] or false
	end

	function Core:UnitIsTrusted(unit)
		return UnitIsUnit("player", unit)
			or UnitIsGroupLeader(unit)
			or UnitIsGroupAssistant(unit)
	end
end

-- UUID
do
	local chars = {}
	for i = 48, 57 do chars[#chars + 1] = string.char(i) end
	for i = 65, 90 do chars[#chars + 1] = string.char(i) end
	for i = 97, 122 do chars[#chars + 1] = string.char(i) end

	local floor, random = math.floor, math.random

	function Core:UUID(length)
		if not length then length = 64 end
		local uuid = ""
		for i = 1, length do
			uuid = uuid .. chars[floor(random() * #chars + 1)]
		end
		return uuid
	end
end

-- PlayerKey
function Core:PlayerKey()
	if not self.db then return end
	return self.db.global.PLAYER_KEY
end

-- Deep cloning helper
function Core:Clone(source)
	local clone = {}
	for k, v in pairs(source) do
		if type(v) == "table" then
			clone[k] = Core:Clone(v)
		else
			clone[k] = v
		end
	end
	return clone
end

