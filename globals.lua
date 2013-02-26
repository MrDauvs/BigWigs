--luac -l MyFile.lua | lua globals.lua MyFile.lua
-- BigWigs globals.lua
-- Modified from FindGlobals.lua by Mikk
-- All code in this script is in the public domain.

local ignoredFiles = {
	["./globals.lua"] = true,
	["./Options/scripts/authors.lua"] = true,
	["./Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua"] = true,
}
local fileName = arg[1]
if ignoredFiles[fileName] then return end

local acceptedGlobals = {
	GetPlayerFacing = true,
	GetSpellLink = true,
	GetNumSpellTabs = true,
	GetSpellTabInfo = true,
	GetSpellBookItemName = true,
	BOOKTYPE_SPELL = true,
	ChatFrame_AddMessageEventFilter = true,
	GetInstanceInfo = true,
	CombatLogClearEntries = true,
	PlaySoundFile = true,
	PlaySound = true,
	InCombatLockdown = true,
	RaidWarningFrame = true,
	SetRaidTarget = true,
	GetRaidTargetIndex = true,
	UnitRace = true,
	IsItemInRange = true,
	IsSpellInRange = true,
	SetMapToCurrentZone = true,
	GetMapInfo = true,
	GetCurrentMapDungeonLevel = true,
	GetPlayerMapPosition = true,
	GameTooltip = true,
	UnitIsDeadOrGhost = true,
	CUSTOM_CLASS_COLORS = true,
	InterfaceOptions_AddCategory = true,
	InterfaceOptionsFrame = true,
	HideUIPanel = true,
	InterfaceOptionsFrameAddOns = true,
	GameFontNormalHuge = true,
	CheckInteractDistance = true,
	GameMenuFrame = true,
	OptionsListButtonToggle_OnClick = true,
	InterfaceOptionsFrame_OpenToCategory = true,
	InterfaceOptionsFramePanelContainer = true,
	CTRL_KEY_TEXT = true,
	ALT_KEY = true,
	SHIFT_KEY_TEXT = true,
	KEY_BUTTON1 = true,
	KEY_BUTTON2 = true,
	KEY_BUTTON3 = true,
	BigWigs = true,
	next = true,
	wipe = true,
	GetTime = true,
	tonumber = true,
	LibStub = true,
	UnitName = true,
	UnitIsUnit = true,
	print = true,
	select = true,
	pairs = true,
	GetAddOnMetadata = true,
	tinsert = true,
	tremove = true,
	type = true,
	unpack = true,
	strsplit = true,
	string = true,
	BigWigsOptions = true,
	BigWigs3IconDB = true,
	GetRealNumPartyMembers = true,
	GetRealNumRaidMembers = true,
	GetZoneText = true,
	GetRealZoneText = true,
	GetSpellInfo = true,
	UnitClass = true,
	GetLocale = true,
	BigWigsLoader = true,
	setmetatable = true,
	CreateFrame = true,
	GetAddOnMetadata = true,
	GetAddOnInfo = true,
	LoadAddOn = true,
	IsAddOnLoaded = true,
	IsAddOnLoadOnDemand = true,
	SendAddonMessage = true,
	GetRaidRosterInfo = true,
	GetNumAddOns = true,
	IsAltKeyDown = true,
	IsControlKeyDown = true,
	INTERFACEOPTIONS_ADDONCATEGORIES = true,
	RAID_CLASS_COLORS = true,
	SlashCmdList = true,
	["_G"] = true,
	table = true,
	bit = true,
	error = true,
	UIParent = true,
	UnitPower = true,
	UnitHealth = true,
	UnitHealthMax = true,
	UnitDebuff = true,
	ALTERNATE_POWER_INDEX = true,
	UnitGUID = true,
	floor = true,
	math = true,
	tostring = true,
	UnitIsCorpse = true,
	UnitIsDead = true,
	UnitPlayerControlled = true,
	IsInInstance = true,
	GetSubZoneText = true,
	strjoin = true,
	UnitExists = true,
	UnitAffectingCombat = true,
	UnitIsPlayer = true,
	rawset = true,
	SendChatMessage = true,
	IsRaidLeader = true,
	IsRaidOfficer = true,
	WorldFrame = true,
	GameFontNormal = true,
	UnitInRaid = true,
	UnitIsRaidOfficer = true,
	UnitInRaid = true,
	IsInGuild = true,
	GetGuildInfo = true,
	UnitInBattleground = true,
	GetNumSubgroupMembers = true,
	GetNumGroupMembers = true,
}

local hasPrintedFileName = nil
local match = "^\t%d+\t%[(%d+)%]\t([SG]ETGLOBAL)\t%d+%s?%-%d+\t;%s(%S+)$"
local fmt = "\tLine %d: %s (%s)"

local stdin = io.input()
while true do
	local line = stdin:read()
	if not line then break end
	local lineNumber, setOrGet, globalName = select(3, line:find(match))
	if globalName and not acceptedGlobals[globalName] then
		if not hasPrintedFileName then
			print(fileName)
			hasPrintedFileName = true
		end
		print(fmt:format(lineNumber, globalName, setOrGet == "GETGLOBAL" and "get" or "set"))
	end
end

