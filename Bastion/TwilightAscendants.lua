if not GetSpellInfo(90000) then return end
--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewBoss("Twilight Ascendants", "The Bastion of Twilight")
if not mod then return end
mod:RegisterEnableMob(43686, 43687, 43688, 43689) --Ignacious, Feludius, Arion, Terrastra
mod.toggleOptions = {{92067, "FLASHSHAKE", "SAY", "ICON"}, {92075, "FLASHSHAKE", "SAY", "ICON"}, {92307, "FLASHSHAKE", "WHISPER"}, 82631, 82660, 82746, 82665, 82762, 83067, {83099, "SAY", "ICON", "FLASHSHAKE"}, 83500, 83565, 83581, "proximity", "switch", "bosskill"}

--------------------------------------------------------------------------------
-- Locals
--

local searingWinds = GetSpellInfo(83500)
local grounded = GetSpellInfo(83581)
local grounded_check_allowed, searing_winds_check_allowed = false, false

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.static_overload_say = "Static Overload on ME!"
	L.gravity_core_say = "Gravity Core on ME!"
	L.health_report = "%s is at %d%% health, switch soon!"
	L.switch = "Switch"
	L.switch_desc = "Warning for boss switches"
	
	L.lightning_rod_say = "Lightning Rod on ME!"

	L.switch_trigger = "We will handle them!"

	L.quake_trigger = "The ground beneath you rumbles ominously...."
	L.thundershock_trigger = "The surrounding air crackles with energy...."

	L.searing_winds_message = "Get Searing Winds!"
	L.grounded_message = "Get Grounded!"

	L.last_phase_trigger = "BEHOLD YOUR DOOM!"
end
L = mod:GetLocale()

mod.optionHeaders = {
	[82631] = "Ignacious",
	[82746] = "Feludius",
	[83067] = "Arion",
	[83565] = "Terrastra",
	[92067] = "heroic",
	proximity = "general",
}

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnBossEnable()
	--heroic
	self:Log("SPELL_AURA_APPLIED", "StaticOverload", 92067)
	self:Log("SPELL_AURA_APPLIED", "GravityCore", 92075)
	self:Log("SPELL_AURA_APPLIED", "FrostBeacon", 92307)

	--normal
	self:Log("SPELL_AURA_APPLIED", "LightningRod",83099)
	
	self:Log("SPELL_CAST_START", "AegisofFlame", 82631, 92513)
	self:Log("SPELL_CAST_START", "Glaciate", 82746, 92507)
	self:Log("SPELL_AURA_APPLIED", "Waterlogged", 82762)
	self:Log("SPELL_CAST_SUCCESS", "HeartofIce", 82665)
	self:Log("SPELL_CAST_SUCCESS", "BurningBlood", 82660)

	self:Yell("Switch", L["switch_trigger"])

	self:Log("SPELL_CAST_START", "Quake", 83565)
	self:Log("SPELL_CAST_START", "Thundershock", 83067)

	self:Emote("QuakeTrigger", L["quake_trigger"])
	self:Emote("ThundershockTrigger", L["thundershock_trigger"])

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")

	self:RegisterEvent("UNIT_HEALTH")

	self:Yell("LastPhase", L["last_phase_trigger"])

	self:Death("Win", 73735) -- Elementium Mostrosity
end


function mod:OnEngage(diff)
	if diff > 2 then
		self:OpenProximity(8)
	end
	self:Bar(82631, (GetSpellInfo(82631)), 28, 82631)
	self:Bar(82746, (GetSpellInfo(82746)), 15, 82746)
	grounded_check_allowed, searing_winds_check_allowed = false, false
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:LightningRod(player, spellId, _, _, spellName)
	if UnitIsUnit(player, "player") then
		self:Say(83099, L["lightning_rod_say"])
		self:FlashShake(83099)
	end
	self:TargetMessage(83099, spellName, player, "Personal", spellId, "Alarm")
	self:SecondaryIcon(83099, player)
end

function mod:GravityCore(player, spellId, _, _, spellName)
	if UnitIsUnit(player, "player") then
		self:Say(92075, L["gravity_core_say"])
		self:FlashShake(92075)
	end
	self:TargetMessage(92075, spellName, player, "Personal", spellId, "Alarm")
	self:SecondaryIcon(92075, player)
end

function mod:StaticOverload(player, spellId, _, _, spellName)
	if UnitIsUnit(player, "player") then
		self:Say(92067, L["static_overload_say"])
		self:FlashShake(92067)
	end
	self:TargetMessage(92067, spellName, player, "Personal", spellId, "Alarm")
	self:PrimaryIcon(92067, player)
end

function mod:FrostBeacon(player, spellId, _, _, spellName)
	if UnitIsUnit(player, "player") then
		self:FlashShake(92307)
	end
	self:TargetMessage(92307, spellName, player, "Personal", spellId, "Alarm")
	self:Whisper(92307, player, spellName)
end

local function searing_winds_check()
	if searing_winds_check_allowed then
		if not UnitDebuff("player", searingWinds) and not UnitIsDeadOrGhost("player") then
			mod:LocalMessage(83500, L["searing_winds_message"], "Personal", 83500, "Info")
			mod:ScheduleTimer(searing_winds_check, 1) -- this might be a bit annoying but hey else you die
		end
	end
end

local function grounded_check()
	if grounded_check_allowed then
		if not UnitDebuff("player", grounded) and not UnitIsDeadOrGhost("player") then
			mod:LocalMessage(83581, L["grounded_message"], "Personal", 83581, "Info")
			mod:ScheduleTimer(grounded_check, 1) -- this might be a bit annoying but hey else you die
		end
	end
end

function mod:UNIT_HEALTH(event, unit)
	--if unit:find("^boss%d$") then
	-- this is probably faster, but uglier :P
	if unit == "boss1" or unit == "boss2" or unit == "boss3" or unit == "boss4" then
		local hp = UnitHealth(unit) / UnitHealthMax(unit) * 100
		if hp < 30 then
			self:Message("switch", L["health_report"]:format((UnitName(unit)), hp), "Attention", 26662, "Info")
			self:UnregisterEvent("UNIT_HEALTH")
		end
	end
end

function mod:AegisofFlame(_, spellId, _, _, spellName)
	self:Bar(82631, spellName, 62, spellId)
	self:Message(82631, spellName, "Urgent", spellId, "Info")
end

function mod:Glaciate(_, spellId, _, _, spellName)
	self:Bar(82746, spellName, 33, spellId)
	self:Message(82746, spellName, "Urgent", spellId, "Info")
end

function mod:Waterlogged(player, spellId, _, _, spellName)
	if UnitIsUnit(player, "player") then
		self:LocalMessage(82762, spellName, player, "Personal", spellId)
	end
end

function mod:HeartofIce(player, spellId, _, _, spellName)
	self:TargetMessage(82665, spellName, player, "Attention", spellId)
end

function mod:BurningBlood(player, spellId, _, _, spellName)
	self:TargetMessage(82660, spellName, player, "Attention", spellId)
end

function mod:Switch()
	self:SendMessage("BigWigs_StopBar", self, (GetSpellInfo(82631)))
	self:SendMessage("BigWigs_StopBar", self, (GetSpellInfo(82746)))
	self:Bar(83565, (GetSpellInfo(83565)), 33, 83565)
	self:Bar(83067, (GetSpellInfo(83067)), 70, 83067)
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:Quake(_, spellId, _, _, spellName)
	self:Bar(83565, spellName, 65, spellId)
	self:Message(83565, spellName, "Important", spellId, "Alert")
	searing_winds_check_allowed = false
end

function mod:Thundershock(_, spellId, _, _, spellName)
	self:Bar(83067, spellName, 65, spellId)
	self:Message(83067, spellName, "Important", spellId, "Alert")
	grounded_check_allowed = false
end

function mod:QuakeTrigger()
	searing_winds_check_allowed = true
	searing_winds_check()
	self:Bar(83565, (GetSpellInfo(83565)), 10, 83565) -- update the bar since we are sure about this timer
end

function mod:ThundershockTrigger()
	grounded_check_allowed = true
	grounded_check()
	self:Bar(83067, (GetSpellInfo(83067)), 10, 83067) -- update the bar since we are sure about this timer
end


function mod:LastPhase()
	self:SendMessage("BigWigs_StopBar", self, (GetSpellInfo(83565)))
	self:SendMessage("BigWigs_StopBar", self, (GetSpellInfo(83067)))
	self:OpenProximity(10) -- assumed, not even sure if we need it
end

