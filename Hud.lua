local _, FS = ...
local Hud = FS:RegisterModule("Hud")

local sin, cos = math.sin, math.cos
local pi_2 = math.pi / 2

--------------------------------------------------------------------------------
-- HUD Frame

local hud
do
	hud = CreateFrame("Frame", "FSHud", UIParent)
	hud:Hide()
end

--------------------------------------------------------------------------------
-- Module initialization

function Hud:OnInitialize()
	self.objects = {}
	self.num_objs = 0
	self.visible = false
end

function Hud:OnEnable()
end

function Hud:OnDisable()
	-- Clear all active objects on disable
	self:Clear()
end

--------------------------------------------------------------------------------
-- Visibility and updates

function Hud:Show()
	if self.visible then return end
	self:Print("activating HUD display")
	self.visible = true
	hud:SetAllPoints()
	hud:Show()
	self.ticker = C_Timer.NewTicker(0.035, function() self:OnUpdate() end)
	self:OnUpdate()
end

function Hud:Hide()
	if not self.visible then return end
	self:Print("disabling HUD display")
	self.visible = false
	self.ticker:Cancel()
	hud:Hide()
	self:Clear()
end

do
	local px = 0
	local py = 0
	local sin_t = 0
	local cos_t = 0
	local zoom = 10
	
	function Hud:SetZoom(z)
		zoom = z
	end
	
	function Hud:Project(x, y)
		local dx = px - x
		local dy = py - y
		local rx = dx * cos_t + dy * sin_t
		local ry = -dx * sin_t + dy * cos_t
		return rx * zoom, ry * zoom
	end

	function Hud:OnUpdate()
		-- Nothing to draw, auto-hide
		if self.num_objs == 0 then
			self:Hide()
			return
		end
		
		px, py = UnitPosition("player")
		local t = GetPlayerFacing() + pi_2
		cos_t = cos(t)
		sin_t = sin(t)
		
		for obj in next, self.objects do
			obj:Update()
		end
	end
end

--------------------------------------------------------------------------------
-- Object frame pool

do
	local pool = {}
	
	local function normalize(frame)
		frame:SetFrameStrata("BACKGROUND")
		frame:ClearAllPoints()
		
		frame.tex:SetAllPoints()
		frame.tex:Hide()
		
		frame:Show()
		return frame
	end
	
	function Hud:AllocObjFrame()
		if #pool > 0 then
			return normalize(table.remove(pool))
		else
			local frame = CreateFrame("Frame", nil, hud)
			frame.tex = frame:CreateTexture(nil, "OVERLAY")
			return normalize(frame)
		end
	end
	
	function Hud:ReleaseObjFrame(frame)
		frame:Hide()
		table.insert(pool, tex)
	end
end

--------------------------------------------------------------------------------
-- Objects interface

local HudObject = {}

function HudObject:Init() end
function HudObject:Position() end

function HudObject:Remove()
	Hud:RemoveObject(self)
end

function HudObject:SetSize(w, h)
	self.frame:SetSize(w, h)
end

function HudObject:SetTex(path)
	self.tex:SetTexture(path)
	self.tex:Show()
end

function HudObject:SetTexColor(...)
	self.tex:SetVertexColor(...)
end

function HudObject:Update()
	if self.OnUpdate then
		self:OnUpdate()
	end
	self:Draw()
end

function HudObject:Draw()
	local x, y = self:Position()
	if not x then
		self:Remove()
		return
	end
	self.frame:SetPoint("CENTER", hud, "CENTER", Hud:Project(x, y))
end

function Hud:CreateObject(proto)
	return setmetatable(proto or {}, { __index = HudObject })
end

--------------------------------------------------------------------------------
-- Scene management

-- Add a new object to the scene
function Hud:AddObject(obj)
	if self.objects[obj] then return obj end
	if obj._destroyed then error("Cannot add a destroyed object") end
	
	self.objects[obj] = true
	self.num_objs = self.num_objs + 1
	
	obj.frame = Hud:AllocObjFrame()
	obj.tex = obj.frame.tex
	
	obj:Init()
	Hud:Show()
	return obj
end

-- Remove an object from the scene
function Hud:RemoveObject(obj)
	if not self.objects[obj] then return end
	obj._destroyed = true
	
	self.objects[obj] = nil
	self.num_objs = self.num_objs - 1
	
	if obj.OnRemove then obj:OnRemove() end
	Hud:ReleaseObjFrame(obj.frame)
end

-- Clear the whole scene
function Hud:Clear()
	for obj in next, self.objects do
		obj:Remove()
	end
end

--------------------------------------------------------------------------------
-- API

-- Point
do
	local gray = { 0.5, 0.5, 0.5 }
	
	function Hud:DrawPoint(x, y, color)
		local p = self:CreateObject({
			x = x or 0,
			y = y or 0,
			color = color or gray
		})
		
		function p:Init()
			self:SetSize(16, 16)
			self:SetTex("Interface\\AddOns\\BigWigs\\Textures\\blip")
			self:SetTexColor(unpack(self.color))
		end
		
		function p:Position()
			return self.x, self.y
		end
		
		return self:AddObject(p)
	end
end

-- Line
do
	local gray = { 0.5, 0.5, 0.5 }
	
	local TAXIROUTE_LINEFACTOR = 32 / 30
	local TAXIROUTE_LINEFACTOR_2 = TAXIROUTE_LINEFACTOR / 2

	function Hud:DrawLine(sx, sy, ex, ey, width, color)
		local l = self:CreateObject({
			sx = sx or 0,
			sy = sy or 0,
			ex = ex or 0,
			ey = ey or 0,
			width = width or 32,
			color = color or gray
		})
		
		function l:Init()
			--self:SetTex("Interface\\TaxiFrame\\UI-Taxi-Line")
			self:SetTex("Interface\\AddOns\\FS_Core\\media\\line")
			self:SetTexColor(unpack(self.color))
		end
		
		function l:Draw()
			local sx, sy = Hud:Project(self.sx, self.sy)
			local ex, ey = Hud:Project(self.ex, self.ey)
			
			-- Determine dimensions and center point of line
			local dx, dy = ex - sx, ey - sy
			local cx, cy = (sx + ex) / 2, (sy + ey) / 2
			local w = self.width
			
			-- Normalize direction if necessary
			if dx < 0 then
				dx, dy = -dx, -dy;
			end
			
			-- Calculate actual length of line
			local l = (dx * dx + dy * dy) ^ 0.5
			
			-- Quick escape if it's zero length
			if l == 0 then
				self.frame:ClearAllPoints()
				self.frame:SetPoint("BOTTOMLEFT", hud, "CENTER", cx, cy)
				self.frame:SetPoint("TOPRIGHT",   hud, "CENTER", cx, cy)
				self.tex:SetTexCoord(0,0,0,0,0,0,0,0)
				return
			end
			
			-- Sin and Cosine of rotation, and combination (for later)
			local s, c = -dy / l, dx / l
			local sc = s * c
			
			-- Calculate bounding box size and texture coordinates
			local Bwid, Bhgt, BLx, BLy, TLx, TLy, TRx, TRy, BRx, BRy
			if dy >= 0 then
				Bwid = ((l * c) - (w * s)) * TAXIROUTE_LINEFACTOR_2
				Bhgt = ((w * c) - (l * s)) * TAXIROUTE_LINEFACTOR_2
				BLx, BLy, BRy = (w / l) * sc, s * s, (l / w) * sc
				BRx, TLx, TLy, TRx = 1 - BLy, BLy, 1 - BRy, 1 - BLx
				TRy = BRx;
			else
				Bwid = ((l * c) + (w * s)) * TAXIROUTE_LINEFACTOR_2
				Bhgt = ((w * c) + (l * s)) * TAXIROUTE_LINEFACTOR_2
				BLx, BLy, BRx = s * s, -(l / w) * sc, 1 + (w / l) * sc
				BRy, TLx, TLy, TRy = BLx, 1 - BRx, 1 - BLx, 1 - BLy
				TRx = TLy
			end
			
			self.frame:ClearAllPoints()
			self.frame:SetPoint("BOTTOMLEFT", hud, "CENTER", cx - Bwid, cy - Bhgt)
			self.frame:SetPoint("TOPRIGHT",   hud, "CENTER", cx + Bwid, cy + Bhgt)
			self.tex:SetTexCoord(TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy)
		end
		
		return self:AddObject(l)
	end
end

-- Units
do
	-- Currently drawn units
	local active_units = {}
	
	-- Draw a specific unit
	function Hud:DrawUnit(unit)
		local guid = UnitGUID(unit)
		if active_units[guid] then return end
		
		local point = self:DrawPoint(0, 0, { FS:GetClassColor(unit, true) })
		active_units[guid] = point
		
		-- Overload the Point.Position function
		function point:Position()
			return UnitPosition(unit)
		end
		
		-- Track user raid target icon and class color
		local display_rt = -1
		local display_class = nil
		
		function point:OnUpdate()
			local rt = GetRaidTargetIndex(unit)
			if display_rt ~= rt then
				if rt then
					point:SetSize(24, 24)
					point:SetTex("Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_" .. rt .. ".blp")
					point:SetTexColor(1, 1, 1)
					display_class = nil
				elseif not rt then
					point:SetSize(16, 16)
					point:SetTex("Interface\\AddOns\\BigWigs\\Textures\\blip")
				end
				display_rt = rt
			end
			
			local class = UnitClass(unit)
			if not rt and display_class ~= class then
				point:SetTexColor(FS:GetClassColor(unit, true))
				display_class = class
			end
		end
		
		function point:OnRemove()
			active_units[guid] = nil
		end
		
		return point
	end
	
	-- Draw the player dot
	function Hud:DrawPlayer()
		self:DrawUnit("player")
	end
	
	-- Draw all units of the raid
	function Hud:DrawAllUnits()
		if IsInRaid() then
			for i = 1, GetNumGroupMembers() do
				self:DrawUnit("raid" .. i)
			end
		end
	end
end