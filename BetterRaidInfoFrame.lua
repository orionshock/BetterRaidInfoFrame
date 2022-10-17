local ADDON_NAME, core = ...
_G[ADDON_NAME] = _G[ADDON_NAME] or core

local LibQTip = LibStub("LibQTip-1.0")
local betterRaidInfoQTip
local Debug = print

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
    if (Debug == print) and LibEdrik_GetDebugFunction then
        Debug = LibEdrik_GetDebugFunction("BRIF: ", nil, "Debug", false)
    end
    if addon == ADDON_NAME then
        core.oldFunc_RaidFrameRaidInfoButton_OnClick = RaidFrameRaidInfoButton:GetScript("OnClick")
        RaidFrameRaidInfoButton:SetScript("OnClick", core.toggleBetterRaidInfoFrame)

        RequestRaidInfo()
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
    return a > b
end

function core:UPDATE_INSTANCE_INFO(event)
    Debug(event, GetNumSavedInstances())
    wipe(savedInstanceInfo)
    wipe(savedInstance_TopLevelGroups)
    for i = 1, GetNumSavedInstances() do
        local name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress, extendDisabled = GetSavedInstanceInfo(i)
        if name then
            Debug("Adding: ", name, difficultyName, id, reset, encounterProgress, numEncounters)
            savedInstanceInfo[difficultyName] = savedInstanceInfo[difficultyName] or {}
            table.insert(
                savedInstanceInfo[difficultyName],
                {
                    ["name"] = name,
                    ["difficultyName"] = difficultyName,
                    ["id"] = id,
                    ["reset"] = reset,
                    ["encounterProgress"] = encounterProgress,
                    ["numEncounters"] = numEncounters
                }
            )
            Debug(savedInstanceInfo[difficultyName][#savedInstanceInfo[difficultyName]].name)
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

local function populateTooltip(window) --yes we call it a window here... sue me
    --we are 5 columns Wide
    window:AddHeader(RAID_INFORMATION)
    window:SetCell(1, 1, RAID_INFORMATION, nil, "LEFT", 4)
    window:SetCell(1, 5, "[X]", nil, "RIGHT")
    window:SetCell(1, 6, " ")
    window:SetCellScript(1, 5, "OnMouseUp", closeWindow)
    --    window:AddLine(RAID_INFO_DESC)
    --    window:SetCell(2, 1, RAID_INFO_DESC, nil, "LEFT", 4)
    window:AddHeader(INSTANCE, "Difficulty", "Remaining Time", "Encounters", "RaidID")
    window:AddSeparator(8)
    Debug("Adding Info to tip")
    for index, difficultyName in ipairs(savedInstance_TopLevelGroups) do
        local currentDifficultyInfo = savedInstanceInfo[difficultyName]
        Debug(index, difficultyName, currentDifficultyInfo)
        if next(currentDifficultyInfo) then
            Debug("Something is in the table")
            local cLine = window:AddHeader(difficultyName)
            window:SetCell(cLine, 1, difficultyName, nil, "LEFT", 5)
            window:AddSeparator()
        end
        for dIndex, eventInfo in ipairs(currentDifficultyInfo) do
            window:AddLine(eventInfo.name, eventInfo.difficultyName, SecondsToTime(eventInfo.reset or 10), string.join("/", eventInfo.encounterProgress or "?", eventInfo.numEncounters or "?"), eventInfo.id)
        end
        window:AddSeparator()
    end
end

local function MakeAndPopulateQTip()
    if betterRaidInfoQTip then
        Debug("WTF?? MakeAndPopulateQTip we have a tooltip and we're being called")
        return
    end
    betterRaidInfoQTip = LibQTip:Acquire("betterRaidInfo", 6, "LEFT")
    if not betterRaidInfoQTip then
        Debug("??WTF?? MakeAndPopulateQTip() LibQTip Didn't give us a tip??")
        return
    end
    RequestRaidInfo()
    populateTooltip(betterRaidInfoQTip)
    betterRaidInfoQTip:SetPoint("TOPLEFT", FriendsFrame, "TOPRIGHT")
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
