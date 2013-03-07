--[[
TODO:
	figure out where to start ForceOfWill in the DisintegrationBeam phase
		as of 25 N ptr there is no force of will during DisintegrationBeam phase
]]--
--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Durumu the Forgotten", 930, 818)
if not mod then return end
mod:RegisterEnableMob(68036)

--------------------------------------------------------------------------------
-- Locals
--
local redAddLeft = 3
local lifedranJumps = 0
local lingeringGaze = {}
local openedForMe = false
local blueRayTracking, redRayTracking = mod:SpellName(139202), mod:SpellName(139204)
local blueController, redController, yellowSpawner

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.rays_spawn = "Rays spawn"
	L.red_spawn_trigger = "The Infrared Light reveals a Crimson Fog!"
	L.blue_spawn_trigger = "The Blue Rays reveal an Azure Eye!"
	L.red_add = "|c00FF0000Red|r add"
	L.blue_add = "|c000000FFBlue|r add"
	L.clockwise = "Clockwise"
	L.counter_clockwise = "Counter clockwise"
	L.death_beam = "Death beam"

	L.custom_off_ray_controllers = "Ray controllers"
	L.custom_off_ray_controllers_desc = "Use the |TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1.blp:15|t, |TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_7.blp:15|t, |TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_6.blp:15|t raid markers to mark people who will control the ray spawn positions and movement"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"custom_off_ray_controllers",
		{133767, "TANK"}, {133765, "TANK_HEALER"}, {134626, "PROXIMITY", "FLASH"}, {136932, "FLASH", "SAY"}, {-6891, "FLASH"}, -6898, -6892,
		{133798, "ICON"}, -6882, 140502, -6889,
		"berserk", "bosskill",
	}, {
		custom_off_ray_controllers = L.custom_off_ray_controllers,
		[133767] = "general",
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Log("SPELL_CAST_START", "IceWall", 134587)
	self:Log("SPELL_PERIODIC_DAMAGE", "EyeSore", 140502)
	self:Log("SPELL_AURA_REMOVED", "LifeDrainRemoved", 133798)
	self:Log("SPELL_AURA_APPLIED", "LifeDrainApplied", 133798)
	self:RegisterEvent("UNIT_AURA")
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
	self:Log("SPELL_DAMAGE", "LingeringGazeDamage", 134044)
	self:Log("SPELL_AURA_REMOVED", "LingeringGazeRemoved", 134626)
	self:Log("SPELL_AURA_APPLIED", "LingeringGazeApplied", 134626)
	self:Log("SPELL_CAST_START", "HardStare", 133765) -- the reason we have this too is to help healers pre shield, and if shield fully absorbs, Serious Wound does not happen
	self:Log("SPELL_AURA_APPLIED_DOSE", "SeriousWound", 133767) -- this is for the tanks
	self:Log("SPELL_AURA_APPLIED", "SeriousWound", 133767)
	self:Death("Deaths", 68036, 69052, 69050) -- Boss, Blue add, Red add
end

function mod:OnEngage()
	self:Berserk(600) -- Confirmed 25N
	self:CDBar(134626, 15) -- Lingering Gaze
	self:Bar(136932, 33) -- Force of Will
	self:Bar(-6882, 135, L["death_beam"])
	redAddLeft = 3
	lifedranJumps = 0
	if self:Heroic() then self:Bar(-6889, 127) end
	self:Bar(-6891, 41) -- Light Spectrum
	wipe(lingeringGaze)
	openedForMe = false
	blueController, redController, yellowSpawner = nil, nil, nil
end

--------------------------------------------------------------------------------
-- Event Handlers
--

local function mark(unit, mark)
	if not unit or not mark or not mod.db.profile.custom_off_ray_controllers then return end
	SetRaidTarget(unit, mark)
end

function mod:IceWall(args)
	self:Message(-6889, "Urgent")
	self:Bar(-6889, 95)
end

do
	local prev = 0
	function mod:EyeSore(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(args.spellId, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(args.spellId)
		end
	end
end

function mod:LifeDrainRemoved(args)
	self:PrimaryIcon(args.spellId)
end

function mod:LifeDrainApplied(args)
	self:PrimaryIcon(args.spellId, args.destName)
	lifedranJumps = lifedranJumps + 1
	self:TargetMessage(args.spellId, args.destName, "Important", "Alert", ("%s - %d%%"):format(args.spellName, lifedranJumps*60)) -- maybe this should just be the amount of jumps
end

function mod:UNIT_AURA(unit)
	local unitGUID = UnitGUID(unit)
	if UnitDebuff(unit, blueRayTracking) and blueController ~= unitGUID then
		blueController = unitGUID
		if self:Me(unitGUID) then
			self:Message(-6891, "Positive", "Alert", CL["you"]:format("|c000000FF"..blueController.."|r"), 134122)
		end
		mark(unit, 6)
	elseif UnitDebuff(unit, redRayTracking) and redController ~= unitGUID then
		redController = unitGUID
		if self:Me(unitGUID) then
			self:Message(-6891, "Positive", "Alert", CL["you"]:format("|c00FF0000"..redController.."|r"), 134123)
		end
		mark(unit, 7)
	end
end

function mod:CHAT_MSG_MONSTER_EMOTE(_, msg, sender, _, _, target)
	if msg:find("134124") then -- Yellow
		redAddLeft = 3
		yellowSpawner = target
		if self:Heroic() then self:Bar(-6891, 80, 137747) end -- Obliterate
		self:StopBar(136932)
		self:Bar(-6891, 10, L["rays_spawn"], "inv_misc_gem_variety_02") -- only spawn this bar in one of the if statements -- this should overwrites the general CD bar
		self:ScheduleTimer("Bar", 10, -6891, 180) -- Light Spectrum
		mark(target, 1)
		self:ScheduleTimer(mark, 10, yellowSpawner, 0)
		if UnitIsUnit("player", target) then
			self:Message(-6891, "Positive", "Alert", CL["you"]:format("|c00FFFF00"..sender.."|r"), 134124)
		end
	elseif msg:find("134123") then -- Red
		redController = target
		mark(target, 7)
		if UnitIsUnit("player", target) then
			self:Message(-6891, "Positive", "Alert", CL["you"]:format("|c00FF0000"..sender.."|r"), 134123)
		end
	elseif msg:find("134122") then -- Blue
		blueController = target
		mark(target, 6)
		if UnitIsUnit("player", target) then
			self:Message(-6891, "Positive", "Alert", CL["you"]:format("|c000000FF"..sender.."|r"), 134122)
		end
	elseif msg:find("133795") then -- HungryEyeStart this is faster than CLEU
		self:TargetMessage(133798, target, "Important", "Alert")
		self:Bar(133798, 20, CL["cast"]:format(self:SpellName(133798)))
		self:PrimaryIcon(133798, target)
		lifedranJumps = 0
	elseif msg:find(L["red_spawn_trigger"]) then
		self:Message(-6892, "Urgent", nil, L["red_add"], 136154)
	elseif msg:find(L["blue_spawn_trigger"]) then
		self:Message(-6898, "Urgent", nil, L["blue_add"], 136177)
	elseif msg:find("136932") then -- Force of Will
		local onPlayer = UnitIsUnit("player", target)
		self:Message(136932, "Attention", onPlayer and "Long", onPlayer and CL["you"]:format(self:SpellName(136932)))
		self:CDBar(136932, 20)
		if onPlayer then
			self:Flash(136932)
			self:Say(136932)
		end
	elseif msg:find("134169") then -- Disintegration Beam
		self:CDBar(134626, 76) -- Lingering Gaze
		self:CDBar(136932, 78) -- Force of Will
		self:Bar(-6882, 60, CL["cast"]:format(L["death_beam"])) -- Exactly 60 sec, a good place to start other timers
		self:Bar(-6882, 191, L["death_beam"])
		self:Message(-6882, "Attention", nil, L["death_beam"])
	end
end

do
	local prev = 0
	function mod:LingeringGazeDamage(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(134626, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(134626)
		end
	end
end

function mod:LingeringGazeRemoved(args)
	if self:Me(args.destGUID) then openedForMe = false end
	-- gotta do all this so in case you can bubble or cloak/etc the debuff then we don't close the display for everyone
	for k, v in next, lingeringGaze do if v == args.destName then table.remove(lingeringGaze, k) end end
	if #lingeringGaze == 0 then
		self:CloseProximity(args.spellId)
	else
		if not openedForMe then
			self:OpenProximity(args.spellId, 15, lingeringGaze)
		end
	end
end

function mod:LingeringGazeApplied(args)
	self:CDBar(args.spellId, 25)
	if self:Me(args.destGUID) then
		self:Flash(args.spellId)
		self:Message(args.spellId, "Urgent", "Alarm", CL["you"]:format(args.spellName))
		self:OpenProximity(args.spellId, 15)
		openedForMe = true
	else
		lingeringGaze[#lingeringGaze+1] = args.destName
		if not openedForMe then
			self:OpenProximity(args.spellId, 15, lingeringGaze)
		end
	end
end

function mod:HardStare(args)
	self:Bar(args.spellId, 12)
end

function mod:SeriousWound(args)
	self:StackMessage(args.spellId, args.destName, args.amount, "Attention", "Info")
end

function mod:Deaths(args)
	if args.mobId == 68036 then -- Boss
		self:Win()
	elseif args.mobId == 69050 then -- Red add
		redAddLeft = redAddLeft - 1
		if redAddLeft == 0 then
			self:StopBar(137747)
			self:CDBar(136932, 20) -- Force of Will
			mark(blueController, 0)
			mark(redController, 0)
		else
			self:Message(-6892, "Urgent", nil, CL["count"]:format(L["red_add"], redAddLeft))
		end
	end
end
