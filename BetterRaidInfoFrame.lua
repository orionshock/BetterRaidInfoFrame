local ADDON_NAME, core = ...
_G[ADDON_NAME] = _G[ADDON_NAME] or core

local LibQTip = LibStub("LibQTip-1.0")
local betterRaidInfoQTip
local eventFrame = CreateFrame("Frame")
eventFrame:SetScript(
    "OnEvent",
    function(frame, event, ...)
        if type(core[event]) == "function" then
            core[event](core, event, ...)
        end
    end
)
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("UPDATE_INSTANCE_INFO")

function core:ADDON_LOADED(event, addon)
    if addon == ADDON_NAME then
        core.oldFunc_RaidFrameRaidInfoButton_OnClick = RaidFrameRaidInfoButton:GetScript("OnClick")
        RaidFrameRaidInfoButton:SetScript("OnClick", core.toggleBetterRaidInfoFrame)
        RequestRaidInfo()
        eventFrame:UnregisterEvent("ADDON_LOADED")
    end
end

local savedInstanceInfo = {}
local savedInstance_TopLevelGroups = {}
core.savedInstanceInfo = savedInstanceInfo
core.savedInstance_TopLevelGroups = savedInstance_TopLevelGroups

local function instanceSortByNameFunc(a, b)
    return a.name < b.name
end
local function difficultyNameSortFunc(a, b)
    if (type(a) == "string") and (type(b) == "string") then
        if strfind(a:sub(1, 1), "%a") and strfind(b:sub(1, 1), "%a") then     --Both Strings (unlikely) sort "A" > "B"
            return a < b
        elseif strfind(a:sub(1, 1), "%a") and strfind(b:sub(1, 1), "%d") then --A is String and B is Number - Sort Letters over Numbers
            return true
        elseif strfind(a:sub(1, 1), "%d") and strfind(b:sub(1, 1), "%a") then --A is Number and B is Letter, Sort letters over Numbers
            return false
        elseif strfind(a:sub(1, 1), "%d") and strfind(b:sub(1, 1), "%d") then --Both are Numbers, sort Low to High
            return a < b
        end
    end

    return a < b
end

function core:UPDATE_INSTANCE_INFO(event)
    wipe(savedInstanceInfo)
    wipe(savedInstance_TopLevelGroups)
    for raidIndex = 1, GetNumSavedInstances() do
        local name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress, extendDisabled =
            GetSavedInstanceInfo(raidIndex)
        if name then
            savedInstanceInfo[difficultyName] = savedInstanceInfo[difficultyName] or {}
            table.insert(
                savedInstanceInfo[difficultyName],
                {
                    ["name"] = name,
                    ["difficultyName"] = difficultyName,
                    ["id"] = id,
                    ["reset"] = reset,
                    ["encounterProgress"] = encounterProgress,
                    ["numEncounters"] = numEncounters,
                    ["raidIndex"] = raidIndex,
                }
            )
        end
    end
    for difficultyName, infoTable in pairs(savedInstanceInfo) do
        table.insert(savedInstance_TopLevelGroups, difficultyName)
        table.sort(infoTable, instanceSortByNameFunc)
    end
    table.sort(savedInstance_TopLevelGroups, difficultyNameSortFunc)
end

local function closeWindow()
    betterRaidInfoQTip:Release()
    betterRaidInfoQTip = nil
end

local total_fmt_String = "%s Total: %d"
local raidInstance_OnHover = function(frame, raidIndex, ...)
    local raidName, raidID, _, _, _, _, _, _, _, _, numBosses = GetSavedInstanceInfo(raidIndex);

    if not raidID or not raidName or not raidIndex then
        return
    end

    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");

    GameTooltip:AddLine(string.format(INSTANCE_LOCK_SS, UnitName("player"), raidName));

    for i = 1, numBosses do
        local bossName, _, isKilled = GetSavedInstanceEncounterInfo(raidIndex, i);
        if isKilled then
            GameTooltip:AddDoubleLine(bossName, BOSS_DEAD, 1, 1, 1, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
        else
            GameTooltip:AddDoubleLine(bossName, BOSS_ALIVE, 1, 1, 1, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g,
                GREEN_FONT_COLOR.b);
        end
    end

    GameTooltip:Show();
end

local function populateTooltip(window)
    window:SetHeaderFont(GameFontNormal)
    window:AddHeader(RAID_INFORMATION)
    window:SetCell(1, 1, RAID_INFORMATION, nil, "LEFT", 4)
    window:SetCell(1, 6, "[X]", nil, "RIGHT")
    window:SetCellScript(1, 6, "OnMouseUp", closeWindow)
    window:AddLine(RAID_INFO_DESC, "2", "3", "4", "5")
    window:SetCell(2, 1, RAID_INFO_DESC, GameFontHighlightSmall, "LEFT", 5)
    window:SetColumnLayout(6, "LEFT", "CENTER", "CENTER", "CENTER", "CENTER", "RIGHT")
    window:AddHeader(INSTANCE, "Difficulty", RESETS_IN, "Encounters", "RaidID")
    for index, difficultyName in ipairs(savedInstance_TopLevelGroups) do
        local currentDifficultyInfo = savedInstanceInfo[difficultyName]
        if next(currentDifficultyInfo) then
            window:AddSeparator()
        end
        for dIndex, eventInfo in ipairs(currentDifficultyInfo) do
            local lineNum = window:AddLine(eventInfo.name, eventInfo.difficultyName, SecondsToTime(eventInfo.reset or 10),
                string.join("/", eventInfo.encounterProgress or "?", eventInfo.numEncounters or "?"), eventInfo.id)
            window:SetLineScript(lineNum, "OnEnter", raidInstance_OnHover, eventInfo.raidIndex)
        end
        local tipLine, tipCol = window:AddLine("&nbsp")
        window:SetCell(tipLine, 1, total_fmt_String:format(difficultyName, #currentDifficultyInfo), "RIGHT")
    end
end

local function MakeAndPopulateQTip()
    if betterRaidInfoQTip then
        return
    end
    betterRaidInfoQTip = LibQTip:Acquire("betterRaidInfo", 6, "LEFT")
    if not betterRaidInfoQTip then
        return
    end
    RequestRaidInfo()
    populateTooltip(betterRaidInfoQTip)
    betterRaidInfoQTip:SetPoint("TOPLEFT", FriendsFrame, "TOPRIGHT")
    betterRaidInfoQTip:UpdateScrolling(FriendsFrame:GetHeight())
    betterRaidInfoQTip:Show()
end

function core.toggleBetterRaidInfoFrame(frame, button, ...)
    if IsShiftKeyDown() then
        core.oldFunc_RaidFrameRaidInfoButton_OnClick(frame, button, ...)
        return
    end
    if not betterRaidInfoQTip then
        MakeAndPopulateQTip()
    else
        closeWindow()
    end
end

FriendsFrame:HookScript(
    "OnHide",
    function(frame, ...)
        if betterRaidInfoQTip and betterRaidInfoQTip:IsShown() then
            closeWindow()
        end
    end
)
